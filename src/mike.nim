import macros

import uri

import tables
export tables

import options
export options

import strformat
import strutils
export strutils

include mike/routes
include mike/testing
include mike/helpers

import asyncdispatch
export asyncdispatch

export json

import httpx
export httpx

macro createRoutes*(): untyped =
    result = newStmtList()
    var routeCase = nnkCaseStmt.newTree(parseStmt("$httpMethod & path"))
    
    for (route, body) in routes.pairs:
        routeCase.add(
            nnkOfBranch.newTree(newLit(route), body)
        )

    result.add(
        routeCase,
        parseStmt("send(Http404)")
    )
    
proc parsePath*(path: string): tuple[path: string, query: Table[string, string]] =
    if path.contains("?"):
        let pathComponents = path.split("?", maxsplit=1)
        result.path = pathComponents[0]
        for param in pathComponents[1].split("&"):
            let values = param.split("=", maxsplit=1)
            result.query[values[0]] = decodeUrl(values[1])
        return
    result.path = path

    
template startServer*(serverPort: int = 8080, numOfThreads: int = 0): untyped {.dirty.} =
    when not defined(testing):
        proc handleRequest*(req: Request) {.async.} =
            let (path, params) = parsePath(req.path.get())
            let httpMethod = req.httpMethod.get()
            var body = "no body"
            if httpMethod != HttpGet:
                body = req.body().getOrDefault()
            
            if defined(debug):
                echo($httpMethod & " " & path & " " & $params)
            try:
                createRoutes()
            except:
                let
                    e = getCurrentException()
                    msg = getCurrentExceptionMsg()
                echo "Got exception ", e.name, " with message ", msg    
                send(Http500)
    else:
        proc handleRequest*(req: MockRequest): Response =
            let (path, params) = parsePath(req.path)
            let httpMethod = req.httpMethod
            var body = "no body"
            if httpMethod != HttpGet:
                body = req.body        
            if defined(debug):
                echo($httpMethod & " " & path & " " & $params)
            createRoutes()
        
    let settings = initSettings(Port(serverPort), numThreads = numOfThreads)
    when not defined(testing):
       run(handleRequest)
