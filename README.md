# repl

access norns' repl from a script

## implementation details

i couldn't make cqueue & COPAS-based websocket client work reliably withinh a norns script (especially the listening that tends to block everything).

the other approach is to do use a websocket <-> OSC gateway, written in Gol (approach & good chunk of the code stolen from @infinitedigits' [dust2dust](https://github.com/schollz/dust2dust)).

compiling the go executable is a bit too intensive for norns (it slows it down to a crawl). hence i recommend transpiling from a more beefy computer using:

    $ env GOOS=linux GOARCH=arm go build -o repl-ws-osc-gw
