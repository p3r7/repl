package main

import (
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"time"

	"github.com/gorilla/websocket"
	"github.com/hypebeast/go-osc/osc"
	log "github.com/schollz/logger"
)

const (
	// NB: change to e.g. "norns" to target a remote norns instance froma dev computer
	NORNS_HOST      = "localhost"
	WS_SCHEME       = "ws"
	WS_PORT_MAIDEN  = 5555
	WS_PORT_SC      = 5556
	NORNS_OSC_PORT  = 10111
	OSC_PATH_MAIDEN = "/repl-gw-maiden"
	OSC_PATH_SC     = "/repl-gw-sc"
	GW_HOST         = "localhost"
	GW_OSC_PORT     = 10666
)

func main() {
	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt)

	wsMaiden, _, doneMaiden := makeWsToOscGw(WS_PORT_MAIDEN, OSC_PATH_MAIDEN)
	defer wsMaiden.Close()
	wsSc, _, doneSc := makeWsToOscGw(WS_PORT_SC, OSC_PATH_SC)
	defer wsSc.Close()

	// log.Debugf("setting up osc server at %s", *oscrecv)
	go func() {
		d := osc.NewStandardDispatcher()
		registerOscToWsHandler(d, OSC_PATH_MAIDEN, wsMaiden)
		registerOscToWsHandler(d, OSC_PATH_SC, wsSc)
		server := &osc.Server{
			Addr:       GW_HOST + ":" + strconv.Itoa(GW_OSC_PORT),
			Dispatcher: d,
		}
		server.ListenAndServe()
	}()

	for {
		select {
		case <-doneMaiden:
			return
		case <-doneSc:
			return
		case <-interrupt:
			log.Debug("interrupt")

			// Cleanly close the connection by sending a close message and then
			// waiting (with timeout) for the server to close the connection.
			errCloseMaiden := wsMaiden.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
			errCloseSc := wsSc.WriteMessage(websocket.CloseMessage, websocket.FormatCloseMessage(websocket.CloseNormalClosure, ""))
			if errCloseMaiden != nil && errCloseSc != nil {
				// log.Debug("write close:", err)
				return
			}
			select {
			case <-doneMaiden:
			case <-doneSc:
			case <-time.After(time.Second):
			}
			return
		}
	}
}

func makeWsToOscGw(wsPort int, oscPath string) (ws *websocket.Conn, oscClient *osc.Client, done chan struct{}) {
	u := url.URL{Scheme: WS_SCHEME, Host: NORNS_HOST + ":" + strconv.Itoa(wsPort)}

	ws, _, err := websocket.DefaultDialer.Dial(u.String(), http.Header{"Sec-WebSocket-Protocol": {"bus.sp.nanomsg.org"}})
	if err != nil {
		log.Error("dial:", err)
		os.Exit(1)
	}

	oscClient = osc.NewClient(NORNS_HOST, NORNS_OSC_PORT)

	done = make(chan struct{})

	go func() {
		defer close(done)
		for {
			_, msg, errmsg := ws.ReadMessage()
			if errmsg != nil {
				// log.Debug("read:", errmsg)
				return
			}
			// log.Debugf("recv: %s", msg)
			oscMsg := osc.NewMessage(oscPath)
			oscMsg.Append(string(msg))
			errOsc := oscClient.Send(oscMsg)
			if errOsc != nil {
				// log.Error(errOsc)
			}
		}
	}()

	return
}

func registerOscToWsHandler(d *osc.StandardDispatcher, oscPath string, ws *websocket.Conn) {
	d.AddMsgHandler(oscPath, func(msg *osc.Message) {
		// log.Debugf("local norns: %s", msg)
		msgString := msg.String()
		// log.Debug(msgString)
		data := strings.Split(msgString, oscPath+" ,s ")
		if len(data) == 2 {
			// log.Debug(data[1])
			errWrite := ws.WriteMessage(websocket.TextMessage, []byte(data[1]))
			if errWrite != nil {
				panic(errWrite)
			}
		}
	})

}
