import request
import httpcore
import httpx
import helpers
proc redirect*(request: MikeRequest,location: string, responseCode: HttpCode = Http301) =
    addHeader("Location",location)
    send(responseCode)