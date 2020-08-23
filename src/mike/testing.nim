import httpcore
import tables

type Response* = object
    body*: string
    code*: HttpCode
    headers*: Table[string, string]

type MockRequest* = object
    httpMethod*: HttpMethod
    path*: string
    body*: string
    headers*: Table[string, string]

proc makeGetMock*(path: string, headers: Table[string, string] = initTable[string, string]()): MockRequest =
    return MockRequest(
        httpMethod: HttpGet,
        path: path,
        headers: headers
    )

template getMock*(path: string, headers: Table[string, string] = initTable[string, string]()): untyped =
    handleRequest(makeGetMock(path, headers))

proc makePostMock*(path, body: string, headers: Table[string, string] = initTable[string, string]()): MockRequest =
    return MockRequest(
        httpMethod: HttpPost,
        path: path,
        body: body,
        headers: headers
    )

template postMock*(path, body: string, headers: Table[string, string] = initTable[string, string]()): untyped =
    handleRequest(makePostMock(path, body, headers))
