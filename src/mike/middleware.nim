import request
import macros

var beforeProcs* {.compileTime.}: seq[string] = @[]
var afterProcs* {.compileTime.}: seq[string] = @[]

macro beforeRequest*(someProc: untyped): untyped =
    ## Use this as a pragma for a middleware function for it to be called before the request
    beforeProcs.add(someProc.name.strVal)
    return someProc

macro afterRequest*(someProc: untyped): untyped =
    ## Use this as a pragma for a middle function for i to be called after the request
    afterProcs.add(someProc.name.strVal)
    return someProc

type 
    Handler* = proc (request: MikeRequest) {.nimcall.}

## An example middleware
proc callLogging*(request: MikeRequest) {.beforeRequest.} =
    echo(request.path)
