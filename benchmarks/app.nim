import ../src/mike



get "/":
    send("Hello World!")

get "/person/{name}":
    send("Hello " & name)

startServer()
