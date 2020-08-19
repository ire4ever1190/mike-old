import tables
import macros
import options
export options

import asyncdispatch
export asyncdispatch

import httpx
export httpx

# var routes* {.compileTime.} = initTable[string, untyped]()
var routes* {.compileTime.} = initTable[string, NimNode]()

macro get* (route: string, body: untyped) =
    echo("adding " & route.strVal())
    routes[route.strVal()] = body

macro createRoutes*(): untyped =
    result = newStmtList()
    var routeCase = nnkCaseStmt.newTree(newIdentNode("path"))
    for (route, body) in routes.pairs:
        routeCase.add(
            nnkOfBranch.newTree(newLit(route), body)
        )
    routeCase.add(
        nnkElse.newTree(
            parseStmt("req.send(Http404)")
        )
    )
    result.add routeCase
    echo(astGenRepr(result))

template send*(response: string) =
    req.send(response)

template startServer*(): untyped {.dirty.} =
    proc handleRequest*(req: Request) {.async.} =
        let path = req.path.get()
        # echo(path is string)
        createRoutes()
    run(handleRequest)
