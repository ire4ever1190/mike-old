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

type
    MikeSettings* = object
        port*: int
        address*: string
        serveStatic*: seq[string]
        threads: int

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
            elif node.kind == nnkPragma:
                node.del(0) # Remove the async pragma since it is not needed when testing
            result &= node
    else:
        result = prc

proc makeSettings*(port: int = 8080, address: string = "", serveStatic: openArray[string] = [], threads: int = 1): MikeSettings =
    result = MikeSettings(
        port: port,
        address: address,
        serveStatic: @serveStatic,
        threads: threads,
    )

template startServer*(mikeSettings: MikeSettings): untyped {.dirty.} =                                    
    ## Starts the server.
    ## Use this at the end of your main file to start the server.
    proc handleRequest*(req: Request): Future[void] {.mockable, async, gcsafe.} =
        when defined(testing):            
            request.futResponse = newFuture[MikeResponse]("Request handling")
            result = request.futResponse
            request.response = newResponse()
        else:
            var request = req.toRequest()
        let httpMethod = request.httpMethod
        if defined(debug):
            echo($httpMethod & " " & request.path & " " & $request.queries)
        try:
            callBeforewares()
            if mikeSettings.serveStatic.len != 0 and checkServedStaticByPath(request.path, mikeSettings.serveStatic):
                await request.sendFile(request.path)
            else:
                createRoutes() # Create a case statement which contains the code for the routes
            callAfterwares()
        except:
            let
                e = getCurrentException()
                msg = getCurrentExceptionMsg()
            echo "Got exception ", e.name, " with message ", msg    
            send(Http500)

    when not defined(testing):
        let nativeSettings = initSettings(Port(mikeSettings.port), numThreads = mikeSettings.threads)
        echo("Mike is here to help on port " & $mikeSettings.port)
        run(handleRequest, nativeSettings)

template startServer*(serverPort: int = 8080, numOfThreads: int = 1): untyped {.deprecated: "Use MikeSettings (via makeSettings proc) instead of plain arguments".} =
    let serverSettings = makeSettings(port = serverPort, threads = numOfThreads)
    startServer(serverSettings)

