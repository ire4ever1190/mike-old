import request
import macros

var # Hold the code for all the middleware calls
    beforeRequestCalls* {.compileTime.} = newStmtList()
    afterRequestCalls*  {.compileTime.} = newStmtList()

template handleCalls(body: untyped): untyped =
    # Insert request parameter before call
    # TODO check if request is already passed
    # TODO check if I could get compile time info 
    for node in body:
        if node.kind == nnkCall:
            node.insert(1, newIdentNode("request"))
            

macro beforeRequest*(body: untyped): untyped =
    ## Put all the code that you want to be called before a request like so.
    ##```nim
    ##  beforeRequest:
    ##      callLogging()
    ##```
    ## Any calls put in here must have MikeRequest as their first parameter (this is likely to change in the future).
    ## Also checkout afterRequest if you want to run code after the request.
    handleCalls(body)    
    beforeRequestCalls = body

macro afterRequest*(body: untyped): untyped =
    handleCalls(body)
    afterRequestCalls = body

macro callBeforewares*(): untyped =
    ## Returns the code which calls all the before middlewares
    return beforeRequestCalls

macro callAfterwares*(): untyped =
    ## Retursn the code which calls all the after middlewares
    return afterRequestCalls

proc callLogging*(request: MikeRequest, prefix: string = "") =
    ## An example middleware
    ## Echos the request path with optional prefix
    echo(prefix & " " & request.path)
