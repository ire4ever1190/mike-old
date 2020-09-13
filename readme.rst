******************************
Mike, The Mikro web framework
******************************

.. image:: https://github.com/ire4ever1190/mike/workflows/Tests/badge.svg

very simple to use web framework for easy prototyping and rapid development

.. code-block:: nim

    import mike

    get "/":
        send "hello"
    
    startServer()

`index <theindex.html>`__

Installation
============

.. code-block::

    $ nimble install mike

How To
=======

The `example <https://github.com/ire4ever1190/mike/blob/master/example.nim>`__ file is a good example for how to use the lib

testing is also easy with the built in mock testing
just have :code:`-d:testing` defined somewhere when running your tests and you will be able to mock test like so

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

Cookies? no problem

.. code-block:: nim
  get "/haveibeenhere":
      if request.cookies.haskey("beenHere"):
          send("Yes you have")
      else:
          request.addCookie("beenHere", $true)
          send("No, but you have now")

You can also put parameters in your routes.

.. code-block:: nim
    get "/person/{name}":
        send("Hello" & name) # Name variable is automatically created
        
made in `Nim <https://nim-lang.org/>`__ with `httpx <https://github.com/xflywind/httpx>`__ backend, inspired by `Kemal <https://kemalcr.com/>`__
