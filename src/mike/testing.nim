import httpcore
import request
    
proc makeGetMock*(path: string, headers: HttpHeaders = newHttpHeaders()): MikeRequest =
    return newRequest(
        HttpGet,
        path,
        headers = headers
    )

template getMock*(path: string, headers: HttpHeaders = newHttpHeaders()): untyped =
    waitFor handleRequest(makeGetMock(path, headers))

proc makePostMock*(path, body: string, headers: HttpHeaders = newHttpHeaders()): MikeRequest =
    return newRequest(
        HttpPost,
        path,
        body,
        headers
    )

template postMock*(path, body: string, headers: HttpHeaders = newHttpHeaders()): untyped =
    waitFor handleRequest(makePostMock(path, body, headers))
