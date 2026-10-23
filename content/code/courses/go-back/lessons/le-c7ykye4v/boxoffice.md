---
title: The chain in boxoffice
version: 1
---

Four middlewares, and two places they could go: around everything, or around some routes. boxoffice
uses both. **The routes file says which is which**, so the whole of the API and everything that
stands in front of it can still be read on one screen:

```go
// boxoffice/routes.go
package main

import "net/http"

func routes(store *memStore, tokens map[string]string) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /events", listEvents(store))
	mux.HandleFunc("GET /events/{id}", getEvent(store))

	admin := http.NewServeMux()
	admin.HandleFunc("GET /admin/report", salesReport(store))
	mux.Handle("/admin/", requireStaff(tokens)(admin))

	return chain(mux, logRequests, recoverPanics, cors("https://tickets.example.com"))
}
```

## Around some routes: a mux inside the mux

`admin` is a second mux holding the staff routes, with their full paths, `/admin/report`. The main
mux registers it, wrapped in `requireStaff`, under the subtree pattern `/admin/`, so **every path
under `/admin/` passes the token check before the inner mux even looks at it**, and every path
outside it never meets the check. A route added to `admin` next month is protected without anyone
remembering to protect it, which is the point of putting the check on the subtree rather than on
each handler.

## Around everything: the order

`chain` puts the first middleware outermost, and the order is not a matter of taste:

| position | middleware | why there |
|---|---|---|
| outermost | `logRequests` | it must see the final answer to every request, including the 500 that `recoverPanics` makes out of a panic and the 204 `cors` gives a preflight |
| second | `recoverPanics` | everything inside it is protected, the other middlewares included; if it sat outside the logger, a panic would skip the log line |
| third | `cors` | preflights carry no token, so it must answer them before `requireStaff` is reached |
| on `/admin/` only | `requireStaff` | the public routes must stay public |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 230\" role=\"img\" aria-label=\"A request enters logRequests, then recoverPanics, then cors, then the mux. The mux sends /events paths straight to their handlers, and /admin/ paths through requireStaff into a second mux holding salesReport.\"><defs><marker id=\"gb-l2-chain-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"60\" width=\"105\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"67\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">logRequests</text><path d=\"M 120 82 L 135 82\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-chain-ah)\"></path><rect x=\"135\" y=\"60\" width=\"105\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"187\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">recoverPanics</text><path d=\"M 240 82 L 255 82\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-chain-ah)\"></path><rect x=\"255\" y=\"60\" width=\"105\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"307\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cors</text><path d=\"M 360 82 L 375 82\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-chain-ah)\"></path><rect x=\"375\" y=\"60\" width=\"70\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"410\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mux</text><path d=\"M 445 75 L 475 75 L 475 35 L 493 35\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-chain-ah)\"></path><rect x=\"495\" y=\"12\" width=\"180\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"585\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/events, /events/{id}</text><text x=\"585\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">listEvents, getEvent</text><path d=\"M 445 92 L 475 92 L 475 150 L 493 150\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-chain-ah)\"></path><rect x=\"495\" y=\"126\" width=\"105\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"547\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">/admin/</text><text x=\"547\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">requireStaff</text><path d=\"M 547 172 L 547 188\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l2-chain-ah)\"></path><rect x=\"475\" y=\"190\" width=\"145\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"547\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">admin: salesReport</text><text x=\"15\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">every request passes these three</text></svg>", "caption": "Three middlewares around everything, one around the staff routes only."}
```

## `main` reads the tokens

```go
// boxoffice/main.go
package main

import (
	"log"
	"net/http"
	"os"
	"time"
)

func main() {
	tokens := map[string]string{}
	for role, name := range map[string]string{
		"manager": "BOXOFFICE_MANAGER_TOKEN",
		"door":    "BOXOFFICE_DOOR_TOKEN",
	} {
		if t := os.Getenv(name); t != "" {
			tokens[t] = role
		}
	}
	if len(tokens) == 0 {
		log.Fatal("no staff tokens: set BOXOFFICE_MANAGER_TOKEN")
	}
	srv := &http.Server{
		Addr:              "localhost:8080",
		Handler:           routes(newMemStore(), tokens),
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("boxoffice listening on %s", srv.Addr)
	log.Fatal(srv.ListenAndServe())
}
```

The loop reads the two variables and keeps whichever are set, so a deployment with no door staff
simply leaves one out. **With neither, the program refuses to start**: a server whose staff routes
nobody can open is a mistake to catch now, not a 401 to puzzle over later.

## Running the whole lesson

```
ana@vm:~/boxoffice$ ls
admin.go
auth.go
cors.go
events.go
go.mod
main.go
middleware.go
recover.go
routes.go
store.go
ana@vm:~/boxoffice$ go vet ./...
ana@vm:~/boxoffice$ go run .
2026/10/16 19:29:24 no staff tokens: set BOXOFFICE_MANAGER_TOKEN
exit status 1
```

Ten files now, all `package main`. After exporting the two tokens as section 06 showed, `go run .`
starts the server, and every request of sections 03 to 06 went through this chain. **Here is the
server's log for all of them, in the order they were made:**

```
2026/10/16 19:29:24 boxoffice listening on localhost:8080
2026/10/16 19:29:24 GET /events 200 77B 25µs
2026/10/16 19:29:24 GET /events/9 404 14B 19µs
2026/10/16 19:29:24 POST /events 405 19B 29µs
2026/10/16 19:29:24 GET /events/1 200 41B 18µs
2026/10/16 19:29:24 GET /events/1 200 41B 15µs
2026/10/16 19:29:24 OPTIONS /admin/report 204 0B 4µs
2026/10/16 19:29:24 GET /admin/report 401 26B 18µs
2026/10/16 19:29:24 GET /admin/report 401 26B 21µs
2026/10/16 19:29:24 GET /admin/report 403 41B 19µs
2026/10/16 19:29:24 GET /admin/report 200 51B 19µs
```

Every one is there: the 404 and 405 the mux wrote, the preflight `cors` answered without reaching
the mux, the two 401s and the 403 that `requireStaff` and the handler returned. **No token appears
in it**, though three of those requests carried one. The 200 for the report is the only line that
says a manager was here, which lesson 12 will want to say in so many words.
