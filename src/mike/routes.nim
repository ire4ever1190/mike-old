import httpcore
import sets
import tables
import macros
import httpcore
import strutils
import strformat
import options
import regex

# From looking at the docs it seems that compileTime for variables does not do what I thought it did
# I need to make sure that these variables are not created at runtime since that would be a waste of space and memory
var 
    routes         {.compileTime.} = initTable[string, NimNode]()
    regexRoutes    {.compileTime.}: seq[(Regex, NimNode)]
    variableRoutes {.compileTime.} = initTable[string, NimNode]() # Optional value routes

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
                if route.kind == nnkCallStrLit:
                    if route[0].strVal == "re":
                        let key = re(`methodString` & route[1].strVal())
                        regexRoutes &= (key,  body)
                    else:
                        # echo is used instead of {.fatal.} since the fatal would be happen regardless
                        echo "ERROR: Invalid call in route. If you are doing a regex route then it must use 're' call"
                else:
                    echo(route.kind)
                    let key = `methodString` & route.strVal()
                    if route.strVal().contains("{"):
                        variableRoutes[key] = body
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
    for route, code in variableRoutes:
        result.putEnd(route.split('/'), code)

#
# End of parameter route code
#

macro createBasicRoutes*(): untyped =
    ## **USED INTERNALLY**.
    ## Gets all the routes from the global routes variable and puts them in a case tree.
    # Build cases for normal routes
    result = newStmtList()
    var routeCase = nnkCaseStmt.newTree(parseExpr("fullPath"))
    for (route, body) in routes.pairs:
        body.add parseExpr("break routes")
        routeCase.add(
            nnkOfBranch.newTree(
                newLit(route),
                body
            )
        )
    result.add(routeCase)
    #
    # Build cases for variable routes
    # TODO cleanup
    return routeCase

macro createParameterRoutes*(): untyped =
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
                    handler &= parseExpr("break routes")
                        
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

    return nnkTryStmt.newTree(
        newStmtList(
            parseExpr("let routeComponents = fullPath.split('/')"),
            addCases(variableRouteTree, 0, "")   
        ),
        #[
            An IndexDefect will be thrown if the user is trying to access a route where
            it was correct at the start but then they went over too much
        ]#
        # This needs to be changed to allow yet another else case for regex routes
        nnkExceptBranch.newTree( 
            newIdentNode((if declared(IndexDefect): "IndexDefect" else: "IndexError")), # IndexDefect is only in > 1.3 
            parseExpr("send(Http404)")
        )
    )
    
makeMethods()
