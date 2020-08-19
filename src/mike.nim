import macros

import tables
export tables

import options
export options

import strutils
export strutils

import asyncdispatch
export asyncdispatch

import httpx
export httpx



# var routes* {.compileTime.} = initTable[string, untyped]()
var routes* {.compileTime.} = initTable[string, NimNode]()

macro get* (route: string, body: untyped) =
    routes["GET:" & route.strVal()] = body

macro post* (route: string, body: untyped) =
    routes["POST:" & route.strVal()] = body

macro createRoutes*(): untyped =
    result = newStmtList()
    var getCase = nnkCaseStmt.newTree(newIdentNode("path"))
    var postCase = nnkCaseStmt.newTree(newIdentNode("path"))
    
    for (route, body) in routes.pairs:
        let 
            info = route.split(":")
            httpMethod = info[0]
            path = info[1]
            
        case httpMethod:
        of "GET":
            getCase.add(
                nnkOfBranch.newTree(newLit(path), body)
            )
    result.add getCase
    result.add parseStmt("send(Http404)")
    echo(astGenRepr(result))

template send*(response: string) =
    req.send(response)

template startServer*(): untyped {.dirty.} =
    proc handleRequest*(req: Request) {.async.} =
        let path = req.path.get()
        let httpMethod = req.path.get() 
    
        createRoutes()
    run(handleRequest)
