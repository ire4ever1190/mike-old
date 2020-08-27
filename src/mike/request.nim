import tables
import httpcore
import asyncfutures
import httpx
import options
import strutils
import tables
import uri

type 
    MikeResponse* = object
        body*: string
        code*: HttpCode
        headers*: HttpHeaders
    
    ## Called MikeRequest to reduce confusion with httpx Request
    MikeRequest* = ref object
        path*: string
        body*: string
        httpMethod*: HttpMethod
        queries*: Table[string, string]
        headers*: HttpHeaders
        when not defined(testing):
            response*: MikeResponse
            req*: Request
        else:
            response*: MikeResponse
            futResponse*: Future[MikeResponse]

proc parsePath*(path: string): tuple[path: string, query: Table[string, string]] =
    ## Parses a path into the actual path and it's query parameters
    if path.contains("?"):
        let pathComponents = path.split("?", maxsplit=1)
        result.path = pathComponents[0]
        for param in pathComponents[1].split("&"):
            let values = param.split("=", maxsplit=1)
            result.query[values[0]] = decodeUrl(values[1])
        return
    result.path = path
 
proc newRequest*(httpMethod: HttpMethod, path: string, body: string = "", headers: HttpHeaders = newHttpHeaders()): MikeRequest =
    let (path, queries) = parsePath(path)
    return MikeRequest(
        path: path,
        httpMethod: httpMethod,
        body: body,
        queries: queries,
        headers: headers
    )

proc newResponse*(): MikeResponse =
    return MikeResponse(
        body: "",
        code: Http200,
        headers: newHttpHeaders()
    )

proc toRequest*(req: Request): MikeRequest =
    ## Converts a httpx request into a mike request
    ## This is done to allow easier processing later on
    # Get the body
    result = newRequest(req.httpMethod.get(), req.path.get())
    let body = req.body()
    if body.isSome:
        result.body = body.get()
    else:
        result.body = ""
        

    if req.headers.isSome:
        result.headers = req.headers.get()
    else:
        result.headers = newHttpHeaders()
        
    # Init the other objects
    when not defined(testing):
        result.req = req
    result.response.headers = newHttpHeaders()
