import request
import macros

# TODO See if there is a way to easily allow both implicit and explicit

var # Hold the code for all the middleware calls
    beforeRequestCalls* {.compileTime.} = newStmtList()
    afterRequestCalls*  {.compileTime.} = newStmtList()

template handleCalls(body: untyped): untyped =
    # Insert request parameter before call
    # TODO check if request is already passed
    # TODO check if I could get compile time info 
    for node in body:
        if node.kind == nnkCall:
            let name = node[0].strVal
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
    ## Returns the code which calls all the after middlewares
    return afterRequestCalls

macro insertBefore*(body: untyped): untyped =
    ## Like beforeRequest and afterRequest but used for adding middleware to certain routes.
    ## Helpful for adding things like authentication middleware to only certain routes
    var calls = newStmtList()
    for node in body:
        # echo(node.kind)
        case node.kind:
        of nnkCall:
            calls.add(node)
            # echo(toStrLit(calls))
        of nnkCommand:
            for thing in node:
                if thing.kind == nnkStmtList:
                    thing.insert(0, calls)
                    # echo toStrLit(thing)
        else: 
            continue
    body.del(n = calls.len())
    return body


proc callLogging*(request: MikeRequest, prefix: string = "") =
    ## An example middleware
    ## Echos the request path with optional prefix
    echo(prefix & " " & request.path)
