import httpcore
import tables
import macros
import httpcore
import strutils
import strformat

var 
    routes     {.compileTime.} = initTable[string, NimNode]()
    slowRoutes {.compileTime.} = initTable[string, NimNode]() # Optional value routes, regex routes etc

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
            macro `macroIdent`* (route: string, body: untyped) =
                routes[`methodString` & route.strVal()] = body

macro createRoutes*(): untyped =
    ## **USED INTERNALLY**.
    ## Gets all the routes from the global routes variable and puts them in a case tree.
    var routeCase = nnkCaseStmt.newTree(parseExpr("$httpMethod & request.path"))
    
    for (route, body) in routes.pairs:
        routeCase.add(
            nnkOfBranch.newTree(newLit(route), body)
        )
    # routeCase.add(
        # nnkElse.newTree(parseExpr("send(Http404)"))
    # )
    result = newStmtList(
        routeCase,
        parseExpr("send(Http404)")
    )
makeMethods()
