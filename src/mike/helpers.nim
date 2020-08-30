import json
import uri
import options
import macros
import strformat
import httpcore
import request
import strutils
import tables
import mimetypes
import asyncdispatch
import httpx
export request

let mimeDB = newMimeTypes() 

macro simple(body: untyped): untyped =
    let name = body[0][1].strVal()
    return newStmtList(
        body,
        parseStmt(fmt"template {name}*(): untyped = request.{name}()")
    )

proc headerToString*(headers: HttpHeaders): string =
    var index = 0
    let finalIndex = len(headers) - 1
    for header in headers.pairs:
        result &= header.key & ": " & header.value
        # If not on the last header then add a new line
        if index != finalIndex:
            result &= "\c\L"
        index += 1
proc send*(request: MikeRequest, body: string = "", code: HttpCode = Http200, headers: HttpHeaders = newHttpHeaders()) =
    # Merge the headers
    for (key, value) in headers.pairs:
            request.response.headers[key] = value

    when defined(testing):
        if not request.futResponse.finished():
            request.response.body = body
            request.response.code = code
            request.futResponse.complete(request.response)
    else:
        echo(headers.headerToString)
        echo(body)
        request.req.send(code, body, headerToString request.response.headers)


template send*(body: string, code: HttpCode = Http200, headers: HttpHeaders = newHttpHeaders()): untyped =
    ## Respond back to the request
    request.send(body, code, headers)
    
template send*(code: HttpCode, headers: HttpHeaders = newHttpHeaders()): untyped = 
    ## Responds with just a HttpCode
    request.send("", code, headers)

template body*(): untyped = 
    ## Gets the body of the request, returns an empty string if there is none
    request.body

template headers*(): untyped = 
    ## Gets the headers from the request
    request.headers
    
template json*(): untyped = 
    ## Gets the json from the body
    parseJson(body())

template json*(obj: typedesc): untyped =
    ## Gets json from the body and converts to a type
    json().to(obj)



proc getOrDefault*[T](value: Option[T]): T =
    ## Gets the value of Option[T] or else gets the default value of T
    if value.isSome:
        return value.get()

proc form*(request: MikeRequest): Table[string, string] =
    ## Gets the form data out of a request
    for entry in decodeUrl(request.body).split("&"):
        let values = entry.split("=", maxsplit=1)
        result[values[0]] = decodeUrl(values[1])

proc headers*(headers: openarray[(string, string)]): HttpHeaders {.inline.} = newHttpHeaders(headers)

proc send*(request: MikeRequest, reqBody: JsonNode, hCode: HttpCode = Http200) =
    ## Sends a json body 
    {.gcsafe.}: # mimeDB is not GC safe but I never modify it
        request.response.headers["Content-Type"] = mimeDB.getMimeType("json")
        request.send($reqBody, hCode) 

template send*(reqBody: JsonNode, hCode: HttpCode = Http200): untyped =
    request.send(reqBody, hCode)

template send*(reqBody: typed, hCode: HttpCode = Http200): untyped =
    send(%*reqBody, hCode)

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

converter toHeader*(headers: openarray[(string, string)]): HttpHeaders = newHttpHeaders(headers)
