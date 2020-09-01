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


proc basAuth*(request: MikeRequest, username, password: string): bool =
    ## Handles HTTP Basic Auth
    if request.headers.hasKey("Authorization"):
        var authInfo: seq[string]
        try:
            authInfo = request.headers["Authorization"]
                                .replace("Basic ", "")
                                .decode()
                                .split(":")
        except:
            send(Http401)
        echo(authInfo, username, password)
        if authInfo[0] == username and authInfo[1] == password:
            return true
        else:
            request.response.headers["WWW-Authenticate"] = "Basic realm=\"You are not here\""
            send(Http401)
    else:
        request.response.headers["WWW-Authenticate"] = "Basic realm=\"You are not here\""
        send(Http401)


# TODO make this kinda more generic so it is easier to add new auth methods
macro basicAuth*(username, password: string, body: untyped): untyped =
    for route in body:
        for node in route:
            if node.kind == nnkStmtList:
                # Code put in here gets injected into the start of the route call
                node.insert 0, nnkIfStmt.newTree(
                    nnkElifBranch.newTree(parseExpr(&"request.basAuth(\"{username}\", \"{password}\")"), parseExpr("""echo("hello")"""))
                )
    return body

