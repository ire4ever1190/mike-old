import src/mike
import src/mike/basicAuth
import json
import options
import strformat

type
    Person* = object 
        name*: string
        age*:  int

get "/":
    # Just a basic request
    send("hello")

get "/echo":
    # Get query parameters
    send(request.queries["msg"])

post "/json":
    # Get json from request
    let body = json()
    request.send(body["msg"].getStr()) # You can use the request object instead of using the templates

get "/jsonresponse":
    # Send json back (With content type automatically set)
    let body = %*{
        "fish": "fingers"
    }
    send(body)
    
post "/form":
    # get form data
    let form = request.form()
    send(form["msg"])

post "/jsontype":
    # Get json from request and turn it into an object
    let person = json(Person)
    send(fmt"hello {person.name} who is aged {person.age}")


get "/fred":
    # Send an object back as json
    let person = Person(name: "Fred", age: 54)
    send(person)

basicAuth("user", "123"):
    get "/private":
        send "hello me"

    get "/private2":
        send "hello me again"


startServer(middlewares = [callLogging]) # The callLogging middleware echos each request
