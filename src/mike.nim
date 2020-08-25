import uri
import httpx
import macros
import tables
import options
import strutils
import strformat
import asyncdispatch

include mike/routes
include mike/helpers
when defined(testing):
    include mike/testing
    
export json
export httpx
export tables
export options
export strutils
export asyncdispatch


macro createRoutes*(): untyped =
    ## Gets all the routes from the global routes variable and puts them in a case tree
    result = newStmtList()
    var routeCase = nnkCaseStmt.newTree(parseStmt("$httpMethod & request.path"))
    
    for (route, body) in routes.pairs:
        if defined(debug):
            echo(route)
        routeCase.add(
            nnkOfBranch.newTree(newLit(route), body)
        )

    result.add(
        routeCase,
        parseStmt("send(Http404)")
    )
    
template startServer*(serverPort: int = 8080, numOfThreads: int = 0): untyped {.dirty.} =
    when not defined(testing):
        proc handleRequest*(req: Request) {.async, gcsafe.} =
            var request = req.toRequest()            
            
            let httpMethod = request.httpMethod
            
            if defined(debug):
                echo($httpMethod & " " & request.path & " " & $request.queries)
            try:
                createRoutes()
            except:
                let
                    e = getCurrentException()
                    msg = getCurrentExceptionMsg()
                echo "Got exception ", e.name, " with message ", msg    
                send(Http500)
    else:
        proc handleRequest*(request: MikeRequest): owned(Future[MikeResponse]) =
            request.futResponse = newFuture[MikeResponse]("Request handling")
            result = request.futResponse
            request.response = newRespose()
            let httpMethod = request.httpMethod
            if defined(debug):
                echo($httpMethod & " " & request.path & " " & $request.queries)
            createRoutes()

    let settings = initSettings(Port(serverPort), numThreads = numOfThreads)
    when not defined(testing):
       run(handleRequest)
