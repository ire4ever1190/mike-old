import httpcore
import tables

type Response* = object
    body*: string

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
