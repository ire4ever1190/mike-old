import request
import macros
import tables

type Middleware* = object
    name*: string
    parameters*: seq[(string, string)] # First value is the name of the parameter, second is the type

proc contains(items: openarray[Middleware], procName: string): bool =
    ## Checks if there is a Middleware with that name in a list
    for middleware in items:
        if middleware.name == procName:
            return true
    
proc newMiddleware(someProc: NimNode): Middleware = 
    result.name = someProc.name.strVal()
 
var beforeProcs* {.compileTime.} = initTable[string, Middleware]()
var afterProcs*  {.compileTime.} = initTable[string, Middleware]()
    
macro beforeRequest*(someProc: untyped): untyped =
    ## Use this as a pragma for a middleware function for it to be called before the request
    beforeProcs[someProc.name.strVal] = newMiddleware(someProc)
    return someProc

macro afterRequest*(someProc: untyped): untyped =
    ## Use this as a pragma for a middle function for i to be called after the request
    afterProcs[someProc.name.strVal] = newMiddleware(someProc)
    return someProc

type 
    Handler* = proc (request: MikeRequest) {.nimcall.}

## An example middleware
proc callLogging*(request: MikeRequest) {.beforeRequest.} =
    echo(request.path)
