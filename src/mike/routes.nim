import httpcore

var routes* {.compileTime.} = initTable[string, NimNode]()

macro makeMethods*(): untyped =
    ## Creates all the macros for creating routes
    ## Used internally
    result = newStmtList()
    for meth in Httpmethod:
        result.add parseStmt(&"macro {toLowerAscii($meth)}* (route: string, body: untyped) = routes[\"{meth}\" & route.strVal()] = body")

makeMethods()
