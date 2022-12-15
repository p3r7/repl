# repl

access norns' repls (both maiden and supercollider) either:
- as a script
- at any time when another script is launched (`repl` mod)

- `E3`: switch between
- `E2`: scroll UP/DOWN
- `K1` + `E2`: scroll LEFT/RIGHT

using a keyboard, one can type / edit at the prompt.

additionally:

- `Enter`: submit prompt to current REPL
- `Alt` + directional arrows: scroll UP/DOWN/LEFT/RIGHT
- standard Unix/Emacs bindings (`Ctrl+A`, `Ctrl+E`, `Ctrl+W`, `Ctrl+K`, `Ctrl+L`) work


## implementation details

i couldn't make cqueue & COPAS-based websocket client work reliably within a norns script (generally sending works but registering a callback to listen for messages tends to block everything).

i resorted to using the hackish approach to use a websocket <-> OSC gateway
- [gateway itself](./main.go), written in golang
- [lua binding lib](./lib/repl_osc_gw.lua)

`@infinitedigits` / @[`schollz`](https://github.com/schollz)' [dust2dust](https://github.com/schollz/dust2dust) is the major source of inspiration.

please note that compiling the golang executable is a bit too intensive for norns (it slows it down to a crawl). hence i recommend transpiling from a more beefy computer using:

    $ env GOOS=linux GOARCH=arm go build -o repl-ws-osc-gw
