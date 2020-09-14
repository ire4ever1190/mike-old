import os
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
import cookies
import times
import asyncfile

let mimeDB = newMimeTypes() 

proc headerToString(headers: HttpHeaders): string =
    var index = 0
    let finalIndex = len(headers) - 1
    for header in headers.pairs:
        result &= header.key & ": " & header.value
        # If not on the last header then add a new line
        if index != finalIndex:
            result &= "\c\L"
        index += 1

proc send*(request: MikeRequest, body: string = "", code: HttpCode = Http200, headers: HttpHeaders = newHttpHeaders()) =
    ## Sends a response back to the request.
    # Merge the headers
    for (key, value) in headers.pairs:
            request.response.headers[key] = value

    when defined(testing):
        if not request.finished:
            request.response.body = body
            request.response.code = code
            request.finished = true
    else:
        request.req.send(code, body, headerToString request.response.headers)

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

proc sendRaw*(request: MikeRequest, code: HttpCode, body: string, headers = "", overwriteHeaders: bool = false) =
    var text = ("HTTP/1.1 $#") % [$code]

    if overwriteHeaders:
        text = text & headers
    else:
        text = text & ("\c\LContent-Length: $#\c\L$#") % [$body.len, headers]
    
    request.req.unsafeSend(text & "\c\L\c\L" & body)

proc sendFile*(request: MikeRequest, filePath: string, mime: string = "", charset: string = "utf-8", code: HttpCode = Http200, headers: HttpHeaders = newHttpHeaders()) {.async.} =
    let filePath = filePath.strip(trailing = false, chars = {'/'})
    var fileInfo: FileInfo
    try:
        fileInfo = getFileInfo(filePath)
    except:
        send("Not found", Http404, headers)

    # if server does not have permissions to read requested file - respond with 403 code
    if fpOthersRead notin fileInfo.permissions:
        send("Forbidden", Http403, headers)
        return

    let filePathParts = splitFile(filePath)

    # get mime type for requested file if not set by developer
    var mimetype = mime
    if mimetype.len == 0:
        var ext = if filePathParts.ext.len > 0:
            filePathParts.ext.substr(1)
          else:
            ""

        mimetype = mimeDB.getMimetype(ext)

    # Merge the headers
    for (key, value) in headers.pairs:
        request.response.headers[key] = value

    # set headers for file response
    if mimetype.len != 0:
        request.response.headers.add("Content-Type", mimetype & "; " & charset)
    request.response.headers.add("Last-Modified", $fileInfo.lastWriteTime)
    echo fileInfo.size
    # if file size less then 20M bytes - send with default method, else send by blocks
    if fileInfo.size < 20000000:
        request.req.send(code, readFile(filePath), headerToString request.response.headers)
    else:
        request.response.headers.add("Content-Length", $fileInfo.size)
        request.sendRaw(code, "", "\c\L" & headerToString(request.response.headers), true)
        let fileContent = openAsync(filePath)

        while true:
            let value = await fileContent.read(4096)
            if value.len > 0:
                request.req.unsafeSend(value)
            else:
                break

        fileContent.close()


proc checkServedStaticByPath*(path: string, staticDirs: openArray[string]): bool =
    result = false
    let clearPath = path.strip(trailing = false, chars = {'/'})
    if not fileExists(clearPath):
        return

    let fileInfo = splitFile(clearPath)

    for dir in staticDirs:
        if fileInfo.dir.startsWith(dir.strip(trailing = false, chars = {'/'})):
            return true

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

proc addCookie*(request: MikeRequest, key, value: string, domain = "", path = "", expires = "", secure = false, httpOnly = false) =
    ## Adds a cookie to the request which the client will set at their end
    let cookie = setCookie(key, value, domain, path, expires, true, secure, httpOnly)
    request.response.headers.add("Set-Cookie", cookie)

proc addCookie*(request: MikeRequest, key, value: string, expires: DateTime|Time, domain = "", path = "", secure = false, httpOnly = false) =
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

proc delCookie*(request: MikeRequest, key: string) =
    ## Deletes a cookie from the client
    request.addCookie(key, "", fromUnix(0))

converter toHeader*(headers: openarray[(string, string)]): HttpHeaders = newHttpHeaders(headers)
