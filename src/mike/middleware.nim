#[
  middle ware will be converted into a proc
  that proc will either be called before or after to either handle the request or the response
]#
import macros
import request

macro middleWare(requestWare: varargs proc (r: var MikeRequest)): untyped =
    result = newStmtList()
