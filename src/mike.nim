import uri
import httpx
import macros
import tables
import options
import strutils
import strformat
import asyncdispatch
import sugar

include mike/routes
include mike/helpers
include mike/middleware
when defined(testing):
    include mike/testing
    
export json
export sugar
export httpx
export tables
export options
export strutils
export asyncdispatch

macro createRoutes*(): untyped =
    ## Gets all the routes from the global routes variable and puts them in a case tree
    var routeCase = nnkCaseStmt.newTree(parseExpr("$httpMethod & request.path"))
    
    for (route, body) in routes.pairs:
        routeCase.add(
            nnkOfBranch.newTree(newLit(route), body)
        )
    routeCase.add(
        nnkElse.newTree(parseExpr("send(Http404)"))
    )
    result = routeCase


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

macro callBeforewares*(middlewares: openarray[Handler]): untyped =
    result = newStmtList()
    for middleware in middlewares:
        if middleware.strVal in beforeProcs:
            result.add parseExpr(middleware.strVal & "(request)")

macro callAfterwares*(middlewares: openarray[Handler]): untyped =
    result = newStmtList()
    for middleware in middlewares:
        if middleware.strVal in afterProcs:
            result.add parseExpr(middleware.strVal & "(request)")    

template startServer*(serverPort: int = 8080, numOfThreads: int = 1, middlewares: openarray[Handler]): untyped {.dirty.} =                                    
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
            callBeforewares(middlewares)
            createRoutes()
            callAfterwares(middlewares)
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
