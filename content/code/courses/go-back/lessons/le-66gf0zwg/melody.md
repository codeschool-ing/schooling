---
title: Melody, a hub you do not write
version: 1
---

Section 03 wrote a hub: a set of connections, a way to join and leave, and a send to all of them that does
not wait for the slow ones. Nearly every WebSocket server has one, and **Melody** is that hub as a
library. It sits on gorilla/websocket and gives you sessions, broadcasts and a function to call when
something happens.

The smallest thing worth building with it is a room, where every message anybody sends goes to
everybody. It is a program of its own, in `~/room`:

```go
// room/main.go
package main

import (
	"log"
	"net/http"

	"github.com/olahol/melody"
)

func main() {
	m := melody.New()
	m.HandleConnect(func(s *melody.Session) {
		log.Printf("joined: %d in the room", m.Len())
	})
	m.HandleMessage(func(s *melody.Session, msg []byte) {
		m.Broadcast(msg)
	})
	m.HandleDisconnect(func(s *melody.Session) {
		log.Printf("left: %d in the room", m.Len())
	})

	mux := http.NewServeMux()
	mux.HandleFunc("GET /room", func(w http.ResponseWriter, r *http.Request) {
		m.HandleRequest(w, r)
	})
	log.Fatal(http.ListenAndServe("localhost:8081", mux))
}
```

Three functions describe the room. `HandleConnect` and `HandleDisconnect` log the head count, and
`HandleMessage` sends whatever arrives to every session, the sender included. `HandleRequest` does the
upgrade and then runs the session until it ends.

```
ana@vm:~/room$ go mod init example.com/room
go: creating new go.mod: module example.com/room
go: to add module requirements and sums:
	go mod tidy
ana@vm:~/room$ go mod tidy
go: finding module for package github.com/olahol/melody
go: found github.com/olahol/melody in github.com/olahol/melody v1.4.0
```

With the room running in another terminal, two clients from section 05 join it: the first only listens,
for two seconds, and the second joins half a second later and says one thing:

```
ana@vm:~/room$ ~/boxoffice/watchws ws://localhost:8081/room 2s
connected: 101 Switching Protocols
19:36:01 doors open at 19:00
stopped: context deadline exceeded
ana@vm:~/room$ ~/boxoffice/watchws ws://localhost:8081/room 1s 'doors open at 19:00'
connected: 101 Switching Protocols
19:36:01 doors open at 19:00
stopped: context deadline exceeded
```

Both received the message, the second because `Broadcast` includes the sender; `BroadcastOthers` leaves
the sender out. The room's own log counts them in and out:

```
ana@vm:~/room$ cat .server.log
2026/10/22 19:36:00 joined: 1 in the room
2026/10/22 19:36:01 joined: 2 in the room
2026/10/22 19:36:02 left: 1 in the room
2026/10/22 19:36:02 left: 0 in the room
```

## What it decides for you

A library that holds connections makes the decisions section 03 had to make, and they are worth reading
before trusting it. These are Melody's defaults, from its `config.go`:

| setting | default | what it means |
|---|---|---|
| `MessageBufferSize` | 256 | messages waiting per session; past that, new ones are dropped and the error handler is called |
| `WriteWait` | 10 s | the time a single write may take |
| `PingPeriod` and `PongWait` | 54 s and 60 s | a ping every 54 seconds, and a session silent for 60 is closed |
| `MaxMessageSize` | 512 bytes | a larger message from a client closes its connection |

**The buffer that drops is the same decision as section 03's**, made with 256 instead of 8. The pings are
something boxoffice's handler does not do, and section 08 explains why they matter.

**One default is wrong for production.** `melody.New` builds its upgrader with a `CheckOrigin` that
accepts every origin, which is the opposite of coder/websocket's default, so any site's page can join the
room. Before a Melody server faces the internet, it gets a check of its own:

```go
m.Upgrader.CheckOrigin = func(r *http.Request) bool {
	return r.Header.Get("Origin") == "https://tickets.example.com"
}
```

## Which one

**Melody fits when the shape is rooms and broadcasts**: chats, a live board that every viewer sees the
same, a game lobby. `BroadcastFilter` sends to the sessions a function picks, and `Set` and `Get` keep
values on a session, such as the event a viewer is watching, so boxoffice's hub could be written with it
in a few lines. coder/websocket fits when each connection is its own conversation with a handler, as in
section 05, where a context ends everything and there is no room to manage. Both are a few hundred lines
from the bytes on the wire, and switching later is an afternoon.
