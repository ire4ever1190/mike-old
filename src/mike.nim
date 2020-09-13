import httpx
import macros
import tables
import options
import strutils
import asyncdispatch
import sugar
import mike / [
    routes,
    helpers,
    middleware
]
when defined(testing):
    include mike/testing
    
export helpers
export routes
export middleware
export json
export sugar
export httpx
export tables
export options
export strutils
export asyncdispatch

macro mockable*(prc: untyped): untyped =
    ## Changes the handleRequest proc to use MockRequest
    ## Just changes the input and return type along with moving the async pragma 
    when defined(testing):
        result = nnkProcDef.newTree()
        for node in prc:
            if node.kind == nnkFormalParams:
                node[0] = parseExpr("owned(Future[MikeResponse])")
                node[1] = nnkIdentDefs.newTree(
                    newIdentNode("request"),
                    newIdentNode("MikeRequest"),
                    newEmptyNode()
                )
            result &= node
    else:
        result = prc

template startServer*(serverPort: int = 8080, numOfThreads: int = 1): untyped {.dirty.} =                                    
    ## Starts the server.
    ## Use this at the end of your main file to start the server.
    proc handleRequest*(req: Request): Future[void] {.mockable, async, gcsafe.} =
        when defined(testing):            
            request.response = newResponse()
        else:
            var request = req.toRequest()
        let httpMethod = request.httpMethod
        if defined(debug):
            # Log all the requests during debug
            # TODO add `$` proc for request that does this
            echo($httpMethod & " " & request.path & " " & $request.queries)
        try:
            let fullPath = $httpMethod & request.path
            callBeforewares()
            createRoutes() # Create a case statement which contains the code for the routes
            callAfterwares()
            send(Http404)
            when defined(testing):
                return request.response
        except:
            let
                e = getCurrentException()
                msg = getCurrentExceptionMsg()
            echo "Got exception ", e.name, " with message ", msg    
            send(Http500)

    when not defined(testing):
        let settings = initSettings(Port(serverPort), numThreads = numOfThreads)
        echo("Mike is here to help on port " & $serverPort)
        run(handleRequest, settings = settings)
