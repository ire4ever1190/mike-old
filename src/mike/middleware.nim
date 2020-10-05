import request
import macros

# TODO See if there is a way to easily allow both implicit and explicit

var # Hold the code for all the middleware calls
    beforeRequestCalls* {.compileTime.} = newStmtList()
    afterRequestCalls*  {.compileTime.} = newStmtList()

proc generateHash(routes: NimNode): uint =
    ## Generates a hash for a list of routes using sdbm.
    ## This is used instead of MD5 because the builtin MD5 does not work at compile time
    for route in routes:
        for chr in route[1].strVal:
            result = uint(ord(chr)) + (result shl 6) + (result shl 16) - result
    
template handleCalls(body: NimNode, calls: var NimNode, isBefore: bool): untyped =
    var 
        tempCalls = newStmtList() # Hold all the found calls
        procs = newStmtList() # Hold all the routes
        
    for node in body:
        case node.kind:
        of nnkCommand:
            procs.add(node)
        else:
            tempCalls &= node

    if procs.len() == 0: # If there are no routes then add to global middleware
        calls = tempCalls
    else:
        #[
          If this is middleware for certain routes then create a proc that calls all the code for the middleware
          The proc will be given a unique name by computing a hash consistening of the route paths  
        ]#
        let 
            procName = ident $generateHash(procs) # Generate a unique name
            # procName = genSym(ident = "afterwares")
            call = newCall(
                procName,
                ident("request")
            )
        for procedure in procs:
            if isBefore:
                procedure[2].insert(0, call)
            else:
                procedure[2].add(call)

        procs &= newProc( # Create the new proc and add it to the procs list
            procName,
            params = [
                newEmptyNode(),
                newIdentDefs(
                    ident("request"),
                    ident("MikeRequest")
                )],
            body = tempCalls
        )
        return procs
        

macro beforeRequest*(body: untyped): untyped =
    ## Put all the code that you want to be called before a request like so.
    ##
    ##.. code-block:: nim
    ##  beforeRequest:
    ##      echo("hello") # this will be called before ever request
    ##
    ##  # Can also be done for certain routes
    ##  beforeRequest:
    ##      echo("certain route")
    ##      get "/":
    ##          send("hello")
    ##
    ## Any calls put in here must have MikeRequest as their first parameter (this is likely to change in the future).
    ## Also checkout afterRequest if you want to run code after the request.
    # handleCalls(body)
    handleCalls(body, beforeRequestCalls, true)

macro afterRequest*(body: untyped): untyped =
    # handleCalls(body)
    handleCalls(body, afterRequestCalls, false)

macro callBeforewares*(): untyped =
    ## Returns the code which calls all the before middlewares
    return beforeRequestCalls

macro callAfterwares*(): untyped =
    ## Returns the code which calls all the after middlewares
    return afterRequestCalls

macro insertBefore*(body: untyped): untyped {.deprecated: "Use beforeRequest instead".}=
    ## Like beforeRequest and afterRequest but used for adding middleware to certain routes.
    ## Helpful for adding things like authentication middleware to only certain routes
    var calls = newStmtList()
    for node in body:
        # echo(node.kind)
        case node.kind:
        of nnkCall:
            calls.add(node)
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
