import httpcore
import request

proc t*(msg: string) =
    echo(msg)


template getMock*(path: string, requestHeaders: HttpHeaders = newHttpHeaders()): MikeResponse =
    waitFor handleRequest(
        newRequest(
                HttpGet,
                path,
                headers = requestHeaders
            )
    )
template postMock*(path, body: string, requestHeaders: HttpHeaders = newHttpHeaders()): MikeResponse =
    waitFor handleRequest(
        newRequest(
            HttpPost,
            path,
            body,
            headers = requestHeaders
        )
    )

