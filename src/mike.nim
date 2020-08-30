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
when defined(testing):
    include mike/testing
    
export json
export sugar
export httpx
export tables
export options
export strutils
export asyncdispatch

macro createProcs*(): untyped =
    ## Used interally.
    ## All the routes have a  unique procedure created for them which gets added to a table and called later
    result = newStmtList()
    var procTable = nnkTableConstr.newTree()
    for (key, value) in compileTimeRoutes.pairs:
        result &= newProc(name = ident(key.replace("/", "")), params = @[newEmptyNode(), newIdentDefs(ident("request"), ident("MikeRequest"))], body = value) # Create the proc
        procTable.add( # Create the table entry
            nnkExprColonExpr.newTree(
                newLit(key.replace("/", "")), newIdentNode(key.replace("/", ""))
            )
        )
    # Create the table of procs
    result.add(
        nnkLetSection.newTree(
            nnkIdentDefs.newTree(
                nnkPostFix.newTree(
                    newIdentNode("*"),
                    newIdentNode("routes")
                ),
                newEmptyNode(),
                newCall("toTable", procTable)
            )
        )
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
                node.del(0) # Remove the async pragma since it is not needed when testing
            result &= node
    else:
        result = prc

template startServer*(serverPort: int = 8080, numOfThreads: int = 1): untyped {.dirty.} =
    createProcs()
                                    
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
            let key = replace($httpMethod & request.path, "/", "")
            if routes.hasKey(key):
                routes[replace($httpMethod & request.path, "/", "")](request)
            else:
                send(Http404)
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
