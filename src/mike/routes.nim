import httpcore
import tables
import macros
import httpcore
import strutils
import strformat

var compileTimeRoutes {.compileTime.} = initTable[string, NimNode]()

macro makeMethods*(): untyped =
    ## Creates all the macros for creating routes
    ## Used internally
    result = newStmtList()
    for meth in Httpmethod:
        # 
        # For each HttpMethod a new macro is created
        # This macro creates a adds the body of the route which gets compiled into a proc later
        #
        result.add parseStmt(&"macro {toLowerAscii($meth)}* (route: string, body: untyped) = compileTimeRoutes[\"{meth}\" & route.strVal()] = body")
    
makeMethods()
