# Package

version       = "0.3.0"
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
    exec("nimble doc2 --errorMax:0 --outdir:docs --git.url:https://github.com/ire4ever1190/mike --git.commit:master --index:on --project src/mike.nim")
    exec("nim buildIndex -o:docs/theindex.html docs")
    writeFile("docs/index.html", """
    <!DOCTYPE html>
    <html>
      <head>
        <meta http-equiv="Refresh" content="0; url=opentdb.html" />
      </head>
      <body>
        <p>Click <a href="opentdb.html">this link</a> if this does not redirect you.</p>
      </body>
    </html>
    """)

task workspace, "Internal use, loads up all the files":
    exec("micro src/mike.nim src/mike/*.nim")
