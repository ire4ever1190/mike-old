import mike
import unittest
import ../example
import json
import base64

test "GET root":
    let response = getMock("/")
    check(response.body == "hello")

test "GET query params":
    let response = getMock("/echo?msg=hello there")
    check(response.body == "hello there")

test "POST json":
    let response = postMock("/json", $ %*{"msg": "general kenobi"})
    check(response.body == "general kenobi")

test "GET json response":
    let response = getMock("/jsonresponse")
    let headers = response.headers
    let responseJson = parseJson(response.body)
    check(headers["content-type"] == "application/json")
    check(responseJson["fish"].getStr() == "fingers")

test "POST form request":
    let response = postMock("/form", form {
        "msg": "you are a bold one"  
    })
    check(response.body == "you are a bold one")

test "GET object response":
    let response = getMock("/fred")
    let responseBody = parseJson(response.body).to(Person)
    check(responseBody.name == "Fred")

test "GET 404":
    let response = getMock("/404")
    check response.code == Http404

test "AUTH basic no username or password":
    let response = getMock("/private")
    check response.code == Http401

test "AUTH basic wrong username and password":
    let payload = encode("john:432")
    let response = getMock("/private", newHttpHeaders({"Authorization": "Basic " & payload}))
    check response.code == Http401

test "AUTH basic correct username and password":
    let payload = encode("user:123")
    let response = getMock("/private", newHttpHeaders({"Authorization": "Basic " & payload}))
    check response.code == Http200
    check response.body == "hello me"
    
