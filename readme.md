## Mike, The Mikro web framework

very simple to use web framework for easy testing of stuff

```nim
import mike

get "/":
    send("hello")
    
startServer()
```
