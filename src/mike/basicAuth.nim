import request
import strutils
import base64
import httpcore
import helpers
import strformat


proc basicAuth*(request: MikeRequest, username, password: string, forbiddenMessage: string = "You are forbidden") =
    ## Handles HTTP Basic Auth
    block:
        if request.headers.hasKey("Authorization"):
            try:
                let authInfo = request.headers["Authorization"] 
                                    .replace("Basic ", "") # Could probably use a slice here instead
                                    .decode()
                                    .split(":")
                if authInfo[0] == username and authInfo[1] == password:
                    return
            except:
                break 
    addHeader("WWW-Authenticate", &"Basic realm=\"{forbiddenMessage}\"")
    send(Http401)
