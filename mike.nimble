# Package

version       = "0.4.4"
author        = "Jake Leahy"
description   = "A very simple micro web framework"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.2.0"
requires "httpx == 0.1.0"

task r, "runs the example":
    exec("nim c -d:debug -r example")

task genDoc, "Generates the doc":
    rmDir("docs")
    ## TODO only generate docs for helpers and stuff
    exec("nimble doc2 --git.url:https://github.com/ire4ever1190/mike --git.commit:master --index:on --outdir:docs -d:docs --project src/mike.nim; exit 0")
    exec("nim buildIndex -o:docs/theindex.html docs")
    writeFile("docs/index.html", """
    <!DOCTYPE html>
    <html>
      <head>
        <meta http-equiv="Refresh" content="0; url=theindex.html" />
      </head>
      <body>
        <p>Click <a href="theindex.html">this link</a> if this does not redirect you.</p>
      </body>
    </html>
    """)

task workspace, "Internal use, loads up all the files":
    exec("micro src/mike.nim src/mike/*.nim")
