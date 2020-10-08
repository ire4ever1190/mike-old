******************************
Mike, The Mikro web framework
******************************

.. image:: https://github.com/ire4ever1190/mike/workflows/Tests/badge.svg

very simple to use web framework

.. code-block:: nim

    import mike

    get "/":
        send "hello"
    
    startServer(1234) # Port by default is 8080 but you can change that
    # you can also specify the number of threads when compiling with threads on
    # startServer(numOfThreads=2) 

`index <theindex.html>`__

Installation
============

.. code-block::

    $ nimble install mike

How To
=======

The `example <https://github.com/ire4ever1190/mike/blob/master/example.nim>`__ file is a good example for how to use the lib


Routing
=======

Mike supports the following type of routes
    * normal
    * parameter
Regex routing will be supported in the next release

A normal route is just a plain path with nothing fancy. It is defined like so.

.. code-block:: nim

    get "/home": # This can be any http verb e.g. get, post, put, patch, etc
        send "<h1> This is the home page </h1>"
        
Parameter routes are routes that contain variables in them.

.. code-block:: nim

    get "/account/{id}":
        send "Your ID is: " & id # The variable is automatically created

Testing
=======

testing is also easy with the built in mock testing
just have `-d:testing` defined somewhere when running your tests and you will be able to test your api

.. code-block:: nim

    include example.nim # The file you are testing
    import unittesting

    test "Test root returns hello":
        let response = getMock("/")
        check response.body == "hello"


you can also add middleware to be called before all your requests

.. code-block:: nim

    proc logCall(request: MikeRequest) =
        echo("Got call: " & request.path)
    
    beforeRequest:
        # Anything in this block is called before a request
        logCall(request)
    
    get "/":
        send("hello")
 
    startServer()

Middleware
=========

Mike currently supports running code before a request is processed and after a response is sent

.. code-block:: nim

    var callsCompleted = 0
    proc logCall(request: MikeRequest) =
        echo("Got call: " & request.path)
    
    afterRequest: # Will run after every response
        callsCompleted += 1
    
    beforeRequest: # Will run before every request is handled
        await sleepAsync(1000) # TODO remove this for speed up
    
    beforeRequest: # Will only be run before the routes specified in this block
        logCall(request)
        get "/":
            send "hello"
    
    get "/analytics": # Will not be logged because the middleware is not applied
        send $callsCompleted & " calls have been completed"
    startServer()

Cookies
=======

Mike supports adding and removing cookies from a client 

.. code-block:: nim

    get "/haveibeenhere":
        if request.cookies.haskey("beenHere"):
            send("Yes you have")
        else:
            request.addCookie("beenHere", $true)
            send("No, but you have now")
        
made in `Nim <https://nim-lang.org/>`__ with `httpx <https://github.com/xflywind/httpx>`__ backend, inspired by `Kemal <https://kemalcr.com/>`__
