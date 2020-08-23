import mike
import unittest

get "/":
    send("hello")

get "/echo":
    # GET /echo?msg=hello
    # response: hello
    send(params["msg"])

post "/json":
    # POST /json body: {"msg": "hello"}
    let body = json()
    echo(body["msg"].getStr())
    
post "/form":
    # POST /form body: msg=hello
    let body = form()
    send(body["msg"])

startServer()

test "Test Basic Test":
    let response = getMock("/")
    check(response.body == $Http200)
