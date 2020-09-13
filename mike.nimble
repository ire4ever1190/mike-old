# Package

version       = "0.5.0"
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
    exec("nimble doc2 --git.url:https://github.com/ire4ever1190/mike --git.commit:master --index:on --outdir:docs -d:docs --project src/mike.nim; exit 0")
    exec("nim buildIndex -o:docs/theindex.html docs")
    exec("nim rst2html -o:docs/index.html readme.rst")
    # Adds a fix for dark theme on the index
    var index = readFile("docs/index.html")
    index &= """
        <script>
        const currentTheme = localStorage.getItem('theme') ? localStorage.getItem('theme') : null;
        if (currentTheme) {
            document.documentElement.setAttribute('data-theme', currentTheme);
        }
        </script>
        """
    writeFile("docs/index.html", index)

task workspace, "Internal use, loads up all the files":
    exec("micro src/mike.nim src/mike/*.nim")
