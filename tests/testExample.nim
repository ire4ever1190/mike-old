import mike
import unittest
import ../example
import json
import base64


suite "Test GET handling":
    test "Basic route":
        let response = getMock("/")
        check(response.body == "hello")

    test "Query params":
        let response = getMock("/echo?msg=hello there")
        check(response.body == "hello there")

    test "JSON response":
        let response = getMock("/jsonresponse")
        let headers = response.headers
        let responseJson = parseJson(response.body)
        check(headers["content-type"] == "application/json")
        check(responseJson["fish"].getStr() == "fingers")

    test "Object response":
        let response = getMock("/fred")
        let responseBody = parseJson(response.body).to(Person)
        check(responseBody.name == "Fred")

    test "404":
        let response = getMock("/404")
        check response.code == Http404

suite "Test POST handling":
    test "POST json":
        let response = postMock("/json", $ %*{"msg": "general kenobi"})
        check(response.body == "general kenobi")


    test "POST form request":
        let response = postMock("/form", form {
            "msg": "you are a bold one"  
        })
        check(response.body == "you are a bold one")

suite "Test authentication in routes":
    test "Basic: no username or password":
        let response = getMock("/private")
        check response.code == Http401

    test "Basic: wrong username and password":
        let payload = encode("john:432")
        let response = getMock("/private", newHttpHeaders({"Authorization": "Basic " & payload}))
        check response.code == Http401

    test "Basic: correct username and password":
        let payload = encode("user:123")
        let response = getMock("/private", newHttpHeaders({"Authorization": "Basic " & payload}))
        check response.code == Http200
        check response.body == "hello me"
    
# suite "Pattern matching in routes":
    # test "optional values in routes":
        # var response = getMock("/number/5")
        # check(response.body == "5")
# 
        # response = getMock("/number/928")
        # check(response.body == "928")
