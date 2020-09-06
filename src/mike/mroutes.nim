import httpcore
import tables
import macros
import httpcore
import strutils
import strformat

var 
    routes     {.compileTime.} = initTable[string, NimNode]()
    slowRoutes {.compileTime.} = initTable[string, NimNode]() # Optional value routes, regex routes etc

macro makeMethods*(): untyped =
    ## Creates all the macros for creating routes
    ## Used internally
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
                # if route.strVal.contains("{"):
                    # if route.strVal.count("{") != route.strVal.count("}"):
                        # {.fatal: "Mismatched brackets with route " & route.strVal.}
                routes[`methodString` & route.strVal()] = body

makeMethods()
