import mike
import unittest
import ../example
import json
import base64


suite "Test GET handling":
    test "Basic route":
        var response = getMock("/")
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
        let response = getMock("/route404")
        check response.code == Http404

    test "404 status page":
        let response = getMock("/route404")
        check response.code == Http404
        check response.body == "This page does not exist. So this is a 404 error"

    test "Trailing slash":
        let response = getMock("/jsonresponse/")
        check(response.code == Http404)


suite "Test POST handling":
    test "json":
        let response = postMock("/json", $ %*{"msg": "general kenobi"})
        check(response.body == "general kenobi")


    test "form request":
        let response = postMock("/form", form {
            "msg": "you are a bold one"  
        })
        check(response.body == "you are a bold one")

suite "Test authentication in routes":
    test "no username or password":
        let response = getMock("/private")
        check response.code == Http401

    test "wrong username and password":
        let payload = encode("john:432")
        let response = getMock("/private", newHttpHeaders({"Authorization": "Basic " & payload}))
        check response.code == Http401

    test "correct username and password":
        let payload = encode("user:123")
        let response = getMock("/private", newHttpHeaders({"Authorization": "Basic " & payload}))
        check response.code == Http200
        check response.body == "hello me"

suite "Test Cookies":
    test "No cookie":
        let response = getMock("/echocookie")
        check response.code == Http400

    test "Send cookie":
        let response = getMock("/echocookie", newHttpHeaders {"Cookie": "msg=hello world"})
        check response.body == "hello world"

    test "Get cookie":
        let response = getMock("/getcookie")
        check response.headers.hasKey("set-cookie")
        echo(response.headers["set-cookie"])
        check response.headers["set-cookie"] == "hasVisited=true"
        
    test "Remove cookie":
        let response = getMock("/takecookie")
        check response.headers.hasKey("set-cookie")
        check response.headers["set-cookie"] == "hasVisited=; Expires=Thu, 01 Jan 1970 00:00:00 GMT"

suite "Pattern matching in routes":
    test "Variable values in routes":
        let response = getMock("/person/john")
        check response.body == "Hello john"

    test "Two variable values":
        let response = getMock("/person/john/age/18")
        check response.body == "Hello john aged 18"
        
    test "Variable route that extends further":
        let response = getMock("/person/john/hello")
        check response.code == Http404
        check response.body != "7"

suite "Regex":
    test "Regex":
        let response = getMock("/6")
        check response.body == "6"

    test "More complex route":
        let response = getMock("/static_file/js/main")
        check response.body == "main.js"
