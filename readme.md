## Mike, The Mikro web framework
![Tests](https://github.com/ire4ever1190/mike/workflows/Tests/badge.svg)

very simple to use web framework for easy prototyping and rapid development

```nim
import mike

get "/":
    send "hello"
    
startServer()
```

testing is also easy with the built in mock testing
just have `-d:testing` defined somewhere when running your tests and you will be able to mock test like so

```nim
include example.nim # The file you are testing
import unittesting

test "Test root returns hello":
    let response = getMock("/")
    check response.body == "hello"
```
