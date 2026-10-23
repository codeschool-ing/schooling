---
title: CORS, from the server's side
version: 1
---

The wrong picture first, because almost everybody starts with it: **CORS is not a lock on the
server.** It does not decide who may call boxoffice. `curl`, a script, another server: all of them
can call any route of any server, and no header boxoffice sends will stop them.

What CORS governs is one particular client, the **browser**, and one particular situation: a page
loaded from one origin running JavaScript that calls a server on another. An origin is the scheme,
the host and the port together, so `https://tickets.example.com` and `http://localhost:8080` are
two. **By default the browser sends such a request and then refuses to let the page read the
answer.** That rule, the same-origin policy, is what stops a page you happen to visit from reading
your webmail with your cookies. CORS is how a server tells the browser to make an exception for
pages from origins it names.

So the question the middleware answers is narrow: **which web pages may read boxoffice's answers?**
The box office sells through its own site, `https://tickets.example.com`, and nobody else's.

```go
// boxoffice/cors.go
package main

import (
	"net/http"
	"slices"
)

// cors lets pages served from the allowed origins read boxoffice's answers.
func cors(allowed ...string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Add("Vary", "Origin")
			origin := r.Header.Get("Origin")
			if origin == "" || !slices.Contains(allowed, origin) {
				next.ServeHTTP(w, r)
				return
			}
			w.Header().Set("Access-Control-Allow-Origin", origin)
			if r.Method == http.MethodOptions && r.Header.Get("Access-Control-Request-Method") != "" {
				w.Header().Set("Access-Control-Allow-Methods", "GET, POST, DELETE")
				w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
				w.Header().Set("Access-Control-Max-Age", "600")
				w.WriteHeader(http.StatusNoContent)
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}
```

## An origin it knows, and one it does not

```
ana@vm:~/boxoffice$ curl -si -H 'Origin: https://tickets.example.com' localhost:8080/events/1
HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://tickets.example.com
Vary: Origin
Date: Fri, 16 Oct 2026 22:29:24 GMT
Content-Length: 41
Content-Type: text/plain; charset=utf-8

Jazz at the Docks: 120 of 120 seats left
ana@vm:~/boxoffice$ curl -si -H 'Origin: https://elsewhere.example.net' localhost:8080/events/1
HTTP/1.1 200 OK
Vary: Origin
Date: Fri, 16 Oct 2026 22:29:24 GMT
Content-Length: 41
Content-Type: text/plain; charset=utf-8

Jazz at the Docks: 120 of 120 seats left
```

The browser adds `Origin` by itself to a cross-origin request; `-H` plays the browser here. For the
ticket site, boxoffice answered with `Access-Control-Allow-Origin` naming it back, and the browser
would hand the body to the page. For the other origin there is no such header, and the browser
would hide the body from the page.

**Look at the second answer again: 200, and the whole body.** The server did all the work and sent
the data; only the browser's refusal keeps it from that page. That is exactly why CORS cannot
protect anything private. Anything a stranger must not read needs authentication, which is section
06, and not a missing header.

`Vary: Origin` goes on every answer, allowed or not. **The answer now depends on a request header**,
and a cache between the two, a CDN or the browser's own, has to know that, or it may hand the copy
it stored for one origin to a page from another.

## The preflight

A request a browser considers risky is asked about first. Any method other than `GET`, `HEAD` or
`POST`, any header beyond a short list, or a body typed as JSON makes the browser send an
`OPTIONS` request ahead of the real one, naming the method and headers it intends to use. A request
carrying a staff token in `Authorization` is one of those:

```
ana@vm:~/boxoffice$ curl -si -X OPTIONS -H 'Origin: https://tickets.example.com' -H 'Access-Control-Request-Method: GET' -H 'Access-Control-Request-Headers: authorization' localhost:8080/admin/report
HTTP/1.1 204 No Content
Access-Control-Allow-Headers: Authorization, Content-Type
Access-Control-Allow-Methods: GET, POST, DELETE
Access-Control-Allow-Origin: https://tickets.example.com
Access-Control-Max-Age: 600
Vary: Origin
Date: Fri, 16 Oct 2026 22:29:24 GMT
```

**204 with the permissions, and no body.** The browser compares the method and headers it wants
against the lists, and if they fit, sends the real request. `Access-Control-Max-Age: 600` lets it
remember the answer for ten minutes instead of asking before every call.

Two things about where this sits. **The preflight carries no token**, by the rules browsers follow,
so it must be answered before authentication, and `cors` sits outside `requireStaff` in section 07
for that reason. And the middleware answers the preflight itself and does not call `next`, because
no handler of boxoffice has anything to say to an `OPTIONS` request.

## The mistake to avoid

The tempting shortcut is to copy whatever `Origin` arrives into `Access-Control-Allow-Origin`, or
to send `*`. For a public API with nothing private in it, `*` is honest. **For anything that uses
cookies, combining a reflected origin with `Access-Control-Allow-Credentials: true` lets every web
page on the internet read the answer with the visitor's cookies attached.** boxoffice uses no
cookies and names one origin, and a list of names is the safe default for anything else.
