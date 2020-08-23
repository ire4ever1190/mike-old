import json
import uri
import options
import testing
import macros
import strformat
import httpcore
import httpx
import tables

macro simple(body: untyped): untyped =
    let name = body[0][1].strVal()
    return newStmtList(
        body,
        parseStmt(fmt"template {name}*(): untyped = req.{name}()")
    )

when not defined(testing):
    template send*(reqBody: string, code: HttpCode = Http200) = req.send(code, reqBody)
    template send*(code: HttpCode) = req.send(code)
    template body*(): untyped = getOrDefault(body(req))
    template json*(): untyped = parseJson(body().get())
else: # Test methods need to use MockRequest
    template send*(reqBody: string, code: HttpCode = Http200) = return Response(body: $code)
    template send*(code: HttpCode): untyped = return Response(body: $code)
    template body*(): untyped = req.body
    template json*(): untyped = parseJson("{\"msg\": 1}")
    

proc getOrDefault*[T](value: Option[T]): T =
    ## Gets the value of Option[T] or else gets the default value of T
    if value.isSome:
        return value.get()

proc form*(req: Request|MockRequest): Table[string, string] {.simple.} =
    for entry in decodeUrl(body()).split("&"):
        echo(entry)
        let values = entry.split("=", maxsplit=1)
        result[values[0]] = decodeUrl(values[1])
