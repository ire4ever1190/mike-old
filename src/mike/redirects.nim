import request
import httpcore
import httpx
import helpers
proc redirect*(request: MikeRequest,location: string, responseCode: HttpCode = Http301) {.removeRequestParam.} =
    ## This redirects the request to another url
    addHeader("Location",location)
    send(responseCode)
