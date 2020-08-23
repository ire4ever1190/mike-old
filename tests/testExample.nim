import mike
import unittest
import ../example
import json

test "get root":
    let response = getMock("/")
    check(response.body == "hello")

test "query params":
    let response = getMock("/echo?msg=hello there")
    check(response.body == "hello there")

test "POST json":
    let response = postMock("/json", $ %*{"msg": "general kenobi"})
    check(response.body == "general kenobi")

test "form request":
    let response = postMock("/form", form {
        "msg": "you are a bold one"  
    })
    check(response.body == "you are a bold one")
