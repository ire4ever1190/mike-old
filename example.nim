import src/mike
import src/mike/basicAuth
import json
import options
import strformat
import regex

type
    Person* = object 
        name*: string
        age*:  int

error 404:
    send("This page does not exist. So this is a 404 error")

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


get "/person/{name}":
    send("Hello " & name)

get "/person/{name}/age/{age}":
    send(fmt"Hello {name} aged {age}")

get "/echocookie":
    if request.cookies.hasKey("msg"):
        send(request.cookies["msg"])
    else:
        send(Http400)

get "/getcookie":
    request.addCookie("hasVisited", $true)
    send(Http200)

get "/takecookie":
    request.delCookie("hasVisited")
    send(Http200)


get re"/(\\d)+$": # \\ is needed
    send(matches[0])     
       
get re"/static_file/(\\w+)/(\\w+)$":
    send(matches[1] & "." & matches[0])
    
beforeRequest:
    basicAuth(request, "user", "123")
    get "/private":
        send "hello me"

    get "/private2":
        send "hello me again"

beforeRequest:
    # All calls in here are called before a request
    # Their first parameter must be MikeRequest but you do not pass it here
    request.callLogging("Handling")

startServer() # The callLogging middleware echos each request
