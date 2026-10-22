---
title: Shutting down
version: 1
---

A server is stopped many times in its life: a deploy, a restart, a machine taken away. The naive
stop is the process dying, and every request in flight dies with it, half a payment, half an
upload. **A graceful shutdown stops accepting new work, lets the work already inside finish, and
only then exits**, with a limit on how long it is willing to wait. In Go that is two pieces of the
standard library meeting a context.

- **`signal.NotifyContext`** turns a signal from the operating system into a context that ends.
  `SIGINT` is what Ctrl+C sends; `SIGTERM` is what a service manager or a container platform sends
  when it wants a process to stop.
- **`http.Server.Shutdown`** closes the listener at once, then waits for every active request to
  finish, or for the context it was given to end, whichever comes first.

The server below answers every request after one second. It is saved in `~/cases/shutdown` as
`shutdown.go`:

```go
// Command shutdown serves until it is told to stop, then lets requests in flight finish.
package main

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func slow(w http.ResponseWriter, r *http.Request) {
	time.Sleep(time.Second)
	fmt.Fprintln(w, "slow answer, delivered")
	fmt.Println("server: answered", r.URL.Path)
}

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	srv := &http.Server{Addr: "127.0.0.1:8412", Handler: http.HandlerFunc(slow)}
	served := make(chan error, 1)
	go func() { served <- srv.ListenAndServe() }()
	fmt.Println("server: listening on", srv.Addr)

	<-ctx.Done()
	fmt.Println("server: signal received, shutting down")

	waitFor, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(waitFor); err != nil {
		fmt.Println("server: shutdown:", err)
	}
	if err := <-served; !errors.Is(err, http.ErrServerClosed) {
		fmt.Println("server:", err)
	}
	fmt.Println("server: stopped cleanly")
}
```

`main` has two phases, and the context marks the line between them. Until a signal arrives it sits
in `<-ctx.Done()`. After it, `Shutdown` gets a context of its own, five seconds from now, because
the shutdown must not be cut short by the signal context that has already ended. `ListenAndServe`
returns `http.ErrServerClosed` once `Shutdown` starts, which is the ordinary way it ends, so only a
different error is worth printing.

To see it work, a request has to be in flight at the moment of the signal. A short script does
that: it starts the server, sends one slow request, interrupts the server while the request is
being answered, and then tries a second request. It is saved beside it as `demo.sh`:

```sh
#!/usr/bin/env bash
# demo.sh: start the server, send it a slow request, interrupt it halfway through.
./shutdown &
server=$!
sleep 0.5
curl -s 127.0.0.1:8412/report &
sleep 0.3
kill -INT "$server"
sleep 0.1
curl -sS 127.0.0.1:8412/late
wait
```

```
ana@vm:~/cases$ go build -o shutdown/shutdown ./shutdown
ana@vm:~/cases/shutdown$ bash demo.sh
server: listening on 127.0.0.1:8412
server: signal received, shutting down
curl: (7) Failed to connect to 127.0.0.1 port 8412 after 0 ms: Couldn't connect to server
server: answered /report
slow answer, delivered
server: stopped cleanly
```

Follow the lines in time order:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"The shutdown in demo.sh along a time axis from 0 to 1.6 seconds. The server listens from 0. At 0.5 seconds the request for /report arrives and runs for one second, until 1.5. At 0.8 seconds SIGINT arrives and Shutdown starts: the listener closes at once, so the request for /late at 0.9 is refused, while /report carries on to its end. When /report is answered, Shutdown returns and the server stops cleanly.\"><defs><marker id=\"l12drain-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"65\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">server</text><text x=\"65\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/report</text><text x=\"65\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/late</text><rect x=\"130.0\" y=\"50\" width=\"275.0\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"267.5\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">listening</text><rect x=\"405.0\" y=\"50\" width=\"240.60000000000002\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"525.3\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">draining: no new connections</text><rect x=\"301.9\" y=\"110\" width=\"343.70000000000005\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"473.75\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">answered in full</text><rect x=\"439.4\" y=\"170\" width=\"70\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"474.4\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">refused</text><path d=\"M405.0 36 V46 M405.0 82 V106 M405.0 142 V166 M405.0 202 V214\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"405.0\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">SIGINT: Shutdown starts</text><path d=\"M645.6 82 V106 M645.6 142 V214\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"641.6\" y=\"228\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Shutdown returns</text><path d=\"M130 252 H690\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12drain-paper-dim)\"></path><path d=\"M130.0 247 V257\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"130.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M267.5 247 V257\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"267.5\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.4 s</text><path d=\"M405.0 247 V257\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"405.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.8 s</text><path d=\"M542.5 247 V257\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"542.5\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.2 s</text><path d=\"M680.0 247 V257\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"680.0\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.6 s</text><text x=\"65\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "demo.sh on a time line. Shutdown closes the door first and then waits for the requests already inside."}
```

The interrupt arrived 0.3 seconds into the one-second request. `Shutdown` closed the listener at
once, so the request for `/late`, a tenth of a second later, found nobody listening and `curl`
reported `Couldn't connect to server`. **The request for `/report` was already inside and was
answered in full**: the server logged it and `curl` printed `slow answer, delivered`. Only then did
`Shutdown` return and the program print `stopped cleanly`.

Two details decide whether this works in production. The five-second limit is a promise to
whoever sent the signal: a platform that sends `SIGTERM` waits only so long before it kills the
process outright, so the limit has to be shorter than that wait. And the handlers have to look at
`r.Context()` when their work is long, as section 02 showed, because `Shutdown` waits for them; it
does not cancel them.
