import httpcore
import asyncfutures

type Response* = object
    body*: string
    code*: HttpCode
    headers*: string

type MockRequest* = object
    httpMethod*: HttpMethod
    path*: string
    body*: string
    headers*: string
    response*: Future[Response]
    
proc makeGetMock*(path: string, headers: string = ""): MockRequest =
    return MockRequest(
        httpMethod: HttpGet,
        path: path,
        headers: headers
    )

template getMock*(path: string, headers: string = ""): untyped =
    waitFor handleRequest(makeGetMock(path, headers))

proc makePostMock*(path, body: string, headers: string = ""): MockRequest =
    return MockRequest(
        httpMethod: HttpPost,
        path: path,
        body: body,
        headers: headers
    )

template postMock*(path, body: string, headers: string = ""): untyped =
    waitFor handleRequest(makePostMock(path, body, headers))
