import httpcore
import tables
import macros
import httpcore
import strutils
import strformat

# The first element in the sequence is the actual route code
# The rest is middlewarre
var routes {.compileTime.} = initTable[string, NimNode]()

macro makeMethods*(): untyped =
    ## Creates all the macros for creating routes
    ## Used internally
    result = newStmtList()
    for meth in Httpmethod:
        # 
        # For each HttpMethod a new macro is created
        # This macro creates a adds the body of the route which gets compiled into a proc later
        #
        result.add parseStmt(&"macro {toLowerAscii($meth)}* (route: string, body: untyped) = routes[\"{meth}\" & route.strVal()] = body")
    
makeMethods()
