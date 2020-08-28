import mike
import unittest
import ../example
import json

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
