import src/mike
import json
import options
import strformat

type 
    Person = object 
        name: string
        age:  int

get "/":
    send("hello")

get "/echo":
    # GET /echo?msg=hello
    # response: hello
    request.send(request.queries["msg"])

post "/json":
    # POST /json body: {"msg": "hello"}
    let body = json()
    request.send(body["msg"].getStr())

get "/jsonresponse":
    let body = %*{
        "fish": "fingers"
    }
    request.send(body)
    
post "/form":
    # POST /form body: msg=hello
    let form = request.form()
    request.send(form["msg"])

post "/jsontype":
    let person = json(Person)
    request.send(fmt"hello {person.name} who is aged {person.age}")

startServer()
