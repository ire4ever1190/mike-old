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
import mimetypes

let mimeDB = newMimeTypes()

macro simple(body: untyped): untyped =
    let name = body[0][1].strVal()
    return newStmtList(
        body,
        parseStmt(fmt"template {name}*(): untyped = req.{name}()")
    )

when not defined(testing):
    template body*(): untyped = getOrDefault(req.body)
    template send*(reqBody: string, code: HttpCode = Http200, rHeaders: string = "") = req.send(code, reqBody, rHeaders)
    template send*(code: HttpCode) = req.send(code)
else: # Test methods need to use MockRequest
    template body*(): untyped = req.body
    template send*(reqBody: string, hCode: HttpCode = Http200, rHeaders: string = "") = req.response.complete(Response(body: reqBody, code: hCode, headers: rHeaders))
    template send*(hCode: HttpCode): untyped = 
        if not req.response.finished(): # Used to handle error with send(Http404) completing the future again
            req.response.complete(Response(code: hCode))
                    
template json*(): untyped = parseJson(body())

proc getOrDefault*[T](value: Option[T]): T =
    ## Gets the value of Option[T] or else gets the default value of T
    if value.isSome:
        return value.get()

proc form*(req: Request|MockRequest): Table[string, string] {.simple.} =
    for entry in decodeUrl(body()).split("&"):
        let values = entry.split("=", maxsplit=1)
        result[values[0]] = decodeUrl(values[1])

proc headers(headers: openarray[(string, string)]): string =
    for header in headers:
        result &= header[0] & ":" & header[1] & "\n"

proc headers(resp: Response): Table[string, string] =
    for header in resp.headers.split("\n"):
        let values = header.split(":")
        result[values[0]] = values[1]

proc send*(req: Request|MockRequest, reqBody: JsonNode, hCode: HttpCode = Http200) = 
    let headers = headers {
        "Content-Type": mimeDB.getExt("json")
    }
    send $reqBody, hCode, headers      

template send*(reqBody: JsonNode, hCode: HttpCode = Http200) =
    req.send(reqBody, hCode)

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
