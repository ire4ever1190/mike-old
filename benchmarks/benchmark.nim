import osproc
import strformat

#
# Run Benchmarks using wrk
#

# TODO make a wrk parser to better compare
# TODO make all apps use same port
# TODO benchmark more than a simple route

const 
    time = 5
    connections = 100
    port = 8080
    
proc makeWrkCmd(path: string): string =
    return fmt"wrk -t 1 -c {connections} -d {time}s http://127.0.0.1:{port}{path}"

proc runApp(command, path: string) =
    discard execCmd(command)                      # Compile the code
    let process = startProcess("app")             # Run it in the background
    let (output, _) = execCmdEx(makeWrkCmd(path)) # Run Wrk
    echo(output)                                  # Echo the wrk output
    echo("========")                              # Breakup the results
    process.kill()                                # Kill the background process
#
# Static Route benchmarks
#

# Mike benchmark
echo("Basic route")
runApp("nim c -d:danger -f app.nim", "/")
echo("Parameter route")
runApp("", "/person/jake") # Don't recompile the code

# Kemal benchmark
echo("Basic route")
runApp("crystal build app.cr --release", "/")
echo("Parameter route")
runApp("", "/person/jake")

