# Package

version       = "0.1.0"
author        = "Jake Leahy"
description   = "A very simple micro web framework"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.2.0"
requires "httpx"

task r, "runs the example":
    exec("nim c -r example")
