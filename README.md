# repl

access norns' repls (both maiden and supercollider) either:
- as a script
- at any time when another script is launched (`repl` mod)


## implementation details

i couldn't make cqueue & COPAS-based websocket client work reliably within a norns script (generally sending works but registering a callback to listen for messages tends to block everything).

i resorted to using the hackish approach to use a websocket <-> OSC gateway, written in golang (@infinitedigits' [dust2dust](https://github.com/schollz/dust2dust) is the major source of inspiration).

please note that compiling the golang executable is a bit too intensive for norns (it slows it down to a crawl). hence i recommend transpiling from a more beefy computer using:

    $ env GOOS=linux GOARCH=arm go build -o repl-ws-osc-gw
