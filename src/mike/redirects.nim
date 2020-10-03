## This redirects the request to another url
import request
import httpcore
import httpx
import helpers
proc redirect*(request: MikeRequest,location: string, responseCode: HttpCode = Http301) {.removeRequestParam.} =
    addHeader("Location",location)
    send(responseCode)