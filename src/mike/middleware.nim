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

# macro hasParameters*(someProc: untyped): untyped =
    # ## To allow for middleware to have parameters, this macro creates an empty proc with the request parameter removed
    # ## This is because the compiler hates it when you pass a proc in untyped and its not correct
    # First we need to get all the other parameters
    # var parameters = "" # They will be stored in the same format that they are declared
    # for node in someProc:
        # if node.kind == nnkFormalParams:
            # for param in node:
                # if param.kind == nnkIdentDefs: # Check it is not nnkEmpty or something other than an ident
                    # if param[1].strVal != "MikeRequest":
                        # parameters &= param[0].strVal & ": " & param[1].strVal & ","
    # parameters.removeSuffix(",")
    # let
        # name = someProc[0][^1]
        # parametersNode = newIdentNode(parameters)
        # newProc = quote do:
                # proc `name`* (`parametersNode`): untyped =
                    # callLogging("hello")
    # return newStmtList(
        # someProc, newproc
    # x    parseExpr(fmt"proc {name}* ({parameters}): untyped = {someProc}")
    # )

type 
    Handler* = proc (request: MikeRequest) {.nimcall.}

## An example middleware
proc callLogging*(request: MikeRequest) {.beforeRequest.} =
    echo("->" & " " & request.path)
