import httpcore

var routes* {.compileTime.} = initTable[string, NimNode]()

macro makeMethods*(): untyped =
    result = newStmtList()
    for meth in Httpmethod:
        echo($meth)
        result.add parseStmt(&"macro {toLowerAscii($meth)}* (route: string, body: untyped) = routes[\"{meth}\" & route.strVal()] = body")

makeMethods()
