import json
import uri
import options
import testing
import macros
import strformat
import httpcore
import httpx
import strutils
import tables

macro simple(body: untyped): untyped =
    let name = body[0][1].strVal()
    return newStmtList(
        body,
        parseStmt(fmt"template {name}*(): untyped = req.{name}()")
    )

when not defined(testing):
    template body*(): untyped = getOrDefault(req.body)
    template send*(reqBody: string, code: HttpCode = Http200) = req.send(code, reqBody)
    template send*(code: HttpCode) = req.send(code)
    template json*(): untyped = parseJson(body())
else: # Test methods need to use MockRequest
    template body*(): untyped = req.body
    template send*(reqBody: string, hCode: HttpCode = Http200) = return Response(body: reqBody, code: hCode)
    template send*(hCode: HttpCode): untyped = return Response(code: hCode)
    template json*(): untyped = parseJson(body())

proc getOrDefault*[T](value: Option[T]): T =
    ## Gets the value of Option[T] or else gets the default value of T
    if value.isSome:
        return value.get()

proc form*(req: Request|MockRequest): Table[string, string] {.simple.} =
    for entry in decodeUrl(body()).split("&"):
        let values = entry.split("=", maxsplit=1)
        result[values[0]] = decodeUrl(values[1])

proc form*(values: openarray[(string, string)]): string =
    ## Generates a x-www-form-urlencoded payload
    runnableExamples:
        let payload = form {
            "msg": "hello"
        }
        doAssert payload = "msg=hello"
    for (key, value) in values:
        result &= key & "=" & encodeUrl(value) & "&"
    result.removeSuffix("&")
