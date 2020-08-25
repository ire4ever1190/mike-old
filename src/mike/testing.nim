import httpcore
import asyncfutures
import tables

type Response* = object
    body*: string
    code*: HttpCode
    headers*: HttpHeaders

type MockRequest* = object
    httpMethod*: HttpMethod
    path*: string
    body*: string
    headers*: HttpHeaders
    response*: Future[Response]
    
proc makeGetMock*(path: string, headers: HttpHeaders = newHttpHeaders()): MockRequest =
    return MockRequest(
        httpMethod: HttpGet,
        path: path,
        headers: headers
    )

template getMock*(path: string, headers: HttpHeaders = newHttpHeaders()): untyped =
    waitFor handleRequest(makeGetMock(path, headers))

proc makePostMock*(path, body: string, headers: HttpHeaders = newHttpHeaders()): MockRequest =
    return MockRequest(
        httpMethod: HttpPost,
        path: path,
        body: body,
        headers: headers
    )

template postMock*(path, body: string, headers: HttpHeaders = newHttpHeaders()): untyped =
    waitFor handleRequest(makePostMock(path, body, headers))
