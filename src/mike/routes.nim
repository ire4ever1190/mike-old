import httpcore
import sets
import tables
import sugar
import macros
import httpcore
import strutils
import strformat
import options
import regex

# From looking at the docs it seems that compileTime for variables does not do what I thought it did
# I need to make sure that these variables are not created at runtime since that would be a waste of space and memory
# Might just have to clear them so atleast they are empty
var 
    routes          {.compileTime.} = initTable[string, NimNode]()
    regexRoutes     {.compileTime.} = initTable[string, NimNode]()
    parameterRoutes {.compileTime.} = initTable[string, NimNode]()

macro makeMethods(): untyped =
    ## **USED INTERNALLY**.
    ## Creates all the macros for creating routes
    result = newStmtList()
    for meth in Httpmethod:
        # 
        # For each HttpMethod a new macro is created
        # This macro creates a adds the body of the route which gets compiled into a proc later
        #
        let
            methodString = $meth
            macroIdent = newIdentNode(methodString.toLowerAscii())
            
        result.add quote do:
            macro `macroIdent`* (route: untyped, body: untyped) =
                body &= parseExpr("break routes") # early return
                if route.kind == nnkCallStrLit:
                    if route[0].strVal == "re":
                        let key = `methodString` & route[1].strVal()
                        regexRoutes[key] = body
                    else:
                        # echo is used instead of {.fatal.} since the fatal would be happen regardless
                        echo "ERROR: Invalid call in route. If you are doing a regex route then it must use 're' call"
                else:
                    let key = `methodString` & route.strVal()
                    if route.strVal().contains("{"):
                        parameterRoutes[key] = body
                    else:
                        routes[key] = body
#
# All this node code below is used for parameter routes
#

type Node = ref object
    data: ref Table[string, Node]
    value: Option[NimNode]

proc `$`(node: Node): string {.compileTime.}=
    if node.data.len() > 0:
        result &= $node.data

proc newNode(): Node {.compileTime.}=
    result = Node()
    result.data = newTable[string, Node]()

template get(node: Node, key: string): untyped =   
    node.data[key]

proc getEnd(node: Node, keys: openarray[string]): Node {.compileTime.} =
    ## Goes through the tree with the specified keys and returns the end node
    result = node
    for key in keys:
        result = result.get(key)

proc putEnd(node: var Node, keys: openarray[string], value: NimNode) {.compileTime.} = 
    ## Goes through the tree, and creates if needed, with the specified keys.
    ## Puts the value in the end node
    var nod: Node = node
    for key in keys:
        if not nod.data.hasKey(key):
            nod.data[key] = newNode()
        nod = nod.data[key]
    nod.value = some value

proc buildTree(): Node {.compileTime.} =
    ## Gets all the variable routes and puts them into a tree
    result = newNode()
    for route, code in parameterRoutes:
        result.putEnd(route.split('/'), code)

#
# End of parameter route code
#

macro createBasicRoutes*(): untyped =
    ## **USED INTERNALLY**.
    ## Gets all the routes from the global `routes` variable and puts them in a case tree.
    if routes.len() == 0:
        return
    result = newStmtList()
    var routeCase = nnkCaseStmt.newTree(parseExpr("fullPath"))
    for (route, body) in routes.pairs:
        routeCase.add(
            nnkOfBranch.newTree(
                newLit(route),
                body
            )
        )
    result.add(routeCase)
    return routeCase

macro createParameterRoutes*(): untyped =
    ## **USED INTERNALLY**
    ## Gets all the parameter routes that are specified in the global variable `parameterRoutes` and makes a complex case statement
    if parameterRoutes.len() == 0:
        return
    let variableRouteTree = buildTree()
    proc addCases(node: Node, i: int, completePath: string): NimNode = 
        ## Used has a recursive function. Creates the cases for the parameter routes
        ## i is used to keep track of where it is in the routeComponents
        ## The route components are the path split on the / e.g. /account/settings == [account, settings]
        result = newStmtList() 
        if node.data.len() > 0: # Check that the node still has more stuff to add
            result = nnkCaseStmt.newTree(parseExpr(fmt"routeComponents[{i}]"))
            for path, newNode in node.data:
                if newNode.value.isSome(): # If there is code contained in the node
                    var handler = newStmtList()
                    let pathComponents = (completePath & path).split('/')
                    # Create all the local variables from the parameter
                    for index, x in pathComponents:
                        if x[0] == '{' and x[^1] == '}':
                            let name = x[1..^2] # Remove the {} that is at the start and end
                            handler &= parseExpr(fmt"let {name} = routeComponents[{index}]")
    
                    handler &= newNode.value.get() # Add the code for the route
                                            
                    result &= nnkElse.newTree(
                        # This if statement checks that the path is the the correct one that the user has specified
                        nnkIfStmt.newTree(
                            nnkElifBranch.newTree(
                                parseExpr(fmt"len(routeComponents) == {len(pathComponents)}"),
                                handler
                            ),
                            nnkElse.newTree(
                                addCases(newNode, i + 1, completePath & path & "/")
                            )
                        )
                    )
                else:
                    if path[0] == '{' and path[^1] == '}': # If the path is a parameter 
                        result.add nnkElse.newTree(
                            addCases(newNode, i + 1, completePath & path & "/")
                        )
                    else:
                        result.add nnkOfBranch.newTree(newLit(path), addCases(newNode, i + 1, completePath & path & "/"))

    result = nnkTryStmt.newTree(
        newStmtList(
            parseExpr("let routeComponents = fullPath.split('/')"),
            addCases(variableRouteTree, 0, "")   
        ),
        #[
            An IndexDefect will be thrown if the user is trying to access a route where
            it was correct at the start but then they went over too much
        ]#
        nnkExceptBranch.newTree( 
            newIdentNode((if declared(IndexDefect): "IndexDefect" else: "IndexError")), # IndexDefect is only in > 1.3
            parseExpr("discard")
        )
    )
    return result
    
proc processPatterns(pattern: openarray[string]): (string, Table[int, int]) {.compileTime.} =
    ## This processes multiple patterns into one long regex pattern
    ## This means that an if statement is not required for every pattern
    ## The table that is produced is has the offset has the key and the index that it relates to has the value
    let captureRe = re"(\([^?][^\)]+\))" # A regex to match against capture groups
    var 
        currentIndex = 0
        offset = 0
    for part in pattern:
        let count = part.findAll(captureRe).len()
        result[0] &= part & "|"
        result[1][offset] = currentIndex

        currentIndex += 1
        offset += count
    result[0].removeSuffix("|")

## TODO cleanup

proc findNonEmptyIndexAndMatches*(inputList: seq[RegexMatch], path: string): (int, seq[string]) =
    ## **USED INTERNALLY**
    ## This finds the index of the first non empty regex match
    ## It also returns all the matches
    result[0] = -1
    if inputList.len() == 0: return
    let input = inputList[0] 
    var index = 0
    for match in input.captures:
        if match.len() != 0:
            if result[0] == -1:
                result[0] = index
            result[1] &= path[match[0]]
        index += 1
        
macro createRegexRoutes*(): untyped =
    # Possible optimisation, add a case statement and break the regex search into each method
    # might help if someone has a lot of regex routes
    if regexRoutes.len() == 0:
        return
    let # toSeq was broken so I needed to do this to get the keys and values
        keys = collect(newSeq):
            for key in regexRoutes.keys:
                key
        values = collect(newSeq):
            for value in regexRoutes.values:
                value
        (pattern, offsetTable) = processPatterns(keys)
    result = newStmtList()
    # I had to use this instead of quote since using quote made the index variable not available with the case statement
    # I will use the with macro once it is available
    result.add parseExpr("let regexRoutePattern {.global.} = re(" & '"' & pattern & "\")")
    result.add parseExpr("let pathMatch = findAll(fullPath, regexRoutePattern)")
    result.add parseExpr("let (nonEmptyIndex, matches) = findNonEmptyIndexAndMatches(pathMatch, fullPath)")
    var index = 0
    result.add nnkCaseStmt.newTree(ident("nonEmptyIndex"))
    for (offset, index) in offsetTable.pairs:
        result[^1].add nnkOfbranch.newTree(
            newLit(offset),
            values[index]
        )
    result[^1].add(nnkElse.newTree(parseExpr("discard")))
    echo(result.toStrLit())        
makeMethods()
