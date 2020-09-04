import macros
import request
import strutils
import base64
import httpcore
import helpers
import strformat

#[
    Authentication will work like how it does in ktor
    you will be able to assign different authentication methods to certain routes
    The code in this file will change heavily once I clean it up    
]#


proc basicAuth*(request: MikeRequest, username, password: string, forbiddenMessage: string = "You are forbidden") =
    ## Handles HTTP Basic Auth
    block:
        if request.headers.hasKey("Authorization"):
            try:
                let authInfo = request.headers["Authorization"]
                                    .replace("Basic ", "")
                                    .decode()
                                    .split(":")
                if authInfo[0] == username and authInfo[1] == password:
                    return
            except:
                break 
    addHeader("WWW-Authenticate", &"Basic realm=\"{forbiddenMessage}\"")
    send(Http401)
