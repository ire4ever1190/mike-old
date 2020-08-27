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
    var routeCase = nnkCaseStmt.newTree(parseExpr("$httpMethod & request.path"))
    
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
                node.del(0)
            result &= node
    else:
        result = prc

template startServer*(serverPort: int = 8080, numOfThreads: int = 1): untyped {.dirty.} =
    
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
            createRoutes()
        except:
            let
                e = getCurrentException()
                msg = getCurrentExceptionMsg()
            echo "Got exception ", e.name, " with message ", msg    
            send(Http500)

    when not defined(testing):
        let settings = initSettings(Port(serverPort), numThreads = numOfThreads)
        echo("Mike is here to help")
        run(handleRequest, settings = settings)
