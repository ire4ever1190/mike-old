import json
import uri
import options
import macros
import httpcore
import request
import strutils
import tables
import mimetypes
import asyncdispatch
import httpx
export request
import strformat
import cookies
import times
import sugar


let mimeDB = newMimeTypes() 

macro removeRequestParam*(prc: untyped): untyped =
    ## Makes a template that removes the need to have the request parameter.
    ## the MikeRequest parameter must be the first parameter if using this
    result = newStmtList(prc)
    var
        params = prc[3][1..^1] # Remove the return type
        callingVariables = collect(newSeq):
            for i in params[1..^1]: ## Remove the request parameter
                for ii in i[0..^3]: ## Remove the type
                    ii.strVal
    params[0] = newEmptyNode()
    let k = callingVariables.join(", ")
    result.add nnkTemplateDef.newTree(
        nnkPostfix.newTree(ident("*"), prc.name),
        newEmptyNode(),
        newEmptyNode(),
        nnkFormalParams.newTree(params),
        newEmptyNode(),
        newEmptyNode(),
        parseStmt(
            fmt"request.{prc.name}({k})"
        )
    )
    
proc headerToString(headers: HttpHeaders): string =
    ## Converts HttpHeaders into their correct string representation
    var index = 0
    let finalIndex = len(headers) - 1
    for header in headers.pairs:
        result &= header.key & ": " & header.value
        # If not on the last header then add a new line
        if index != finalIndex:
            result &= "\c\L"
        index += 1

# int64 is used over int since getting the intVal in the error macro returns BiggestInt type
var errorHandleTable* = newTable[int64, proc (request: MikeRequest): string]() 

template status*(code: int|HttpCode, body: untyped): untyped {.dirty.} =
    errorHandleTable[code] = proc (request: MikeRequest): string =
        body

# TODO remove the gcsafe error
proc send*(request: MikeRequest, responseBody: string = "", code: HttpCode = Http200, headers: HttpHeaders = newHttpHeaders()) =
    ## Sends a response back to the request.
    # Merge the headers
    for (key, value) in headers.pairs:
            request.response.headers[key] = value
    var body = responseBody
    # TODO find way to only have this be called if there is stuff to call
    # If someone knows a way to have a macro be called last, please tell me
    if errorHandleTable.hasKey(code.int64):
        body = errorHandleTable[code.int64](request)
    when defined(testing):
        if not request.finished:
            request.response.body = body
            request.response.code = code

    else:
        request.req.send(code, body, headerToString request.response.headers)
    request.finished = true # Allows to see if a 404 needs to be sent

template send*(body: string, code: HttpCode = Http200, headers: HttpHeaders = newHttpHeaders()): untyped =
    ## Respond back to the request implicitly.
    request.send(body, code, headers)
    
template send*(code: HttpCode, headers: HttpHeaders = newHttpHeaders()): untyped = 
    ## Responds with just a HttpCode.
    request.send("", code, headers)

template body*(): untyped = 
    ## Gets the body of the request, returns an empty string if there is none
    request.body

template headers*(): untyped = 
    ## Gets the headers from the request
    request.headers
    
template addHeader*(key, value: string) =
    request.response.headers[key] = value 

template json*(): untyped = 
    ## Gets the json from the body
    parseJson(body())

template json*(obj: typedesc): untyped =
    ## Gets json from the body and converts to a type
    json().to(obj)

proc getOrDefault[T](value: Option[T]): T =
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
    ## Sends json implicitly
    request.send(reqBody, hCode)

template send*(reqBody: typed, hCode: HttpCode = Http200): untyped =
    ## Sends back an object in json form
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

proc addCookie*(request: MikeRequest, key, value: string, domain = "", path = "", expires = "", secure = false, httpOnly = false) {.removeRequestParam.}=
    ## Adds a cookie to the request which the client will set at their end
    let cookie = setCookie(key, value, domain, path, expires, true, secure, httpOnly)
    request.response.headers.add("Set-Cookie", cookie)

proc addCookie*(request: MikeRequest, key, value: string, expires: DateTime|Time, domain = "", path = "", secure = false, httpOnly = false) {.removeRequestParam.}=
    ## Adds a cookie to the request which the client will set at their end
    request.addCookie(
        key,
        value,
        domain,
        path,
        format(expires.utc, "ddd',' dd MMM yyyy HH:mm:ss 'GMT'"),
        secure,
        httpOnly
    )

proc delCookie*(request: MikeRequest, key: string) {.removeRequestParam.}=
    ## Deletes a cookie from the client
    request.addCookie(key, "", fromUnix(0))

converter toHeader*(headers: openarray[(string, string)]): HttpHeaders = newHttpHeaders(headers)
