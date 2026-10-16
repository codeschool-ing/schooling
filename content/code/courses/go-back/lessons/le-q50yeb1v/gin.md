---
title: Gin
version: 1
---

**Gin is the best known Go web framework**, with more GitHub stars than any other, and its shape is
the one the others react to. Its handlers take a single argument, a `*gin.Context`, which
carries the request, the response, the route's parameters and a set of helpers. Here is the
yardstick API written for it:

```go
// fw/gin/main.go
package main

import (
	"net/http"
	"strconv"
	"sync"

	"github.com/gin-gonic/gin"
)

type event struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Seats int    `json:"seats"`
	Sold  int    `json:"sold"`
}

type purchase struct {
	Quantity int    `json:"quantity" binding:"required,min=1,max=10"`
	Email    string `json:"email" binding:"required,email"`
}

var (
	mu     sync.Mutex
	events = map[int]*event{1: {ID: 1, Name: "Jazz at the Docks", Seats: 120}}
)

func main() {
	r := gin.Default()
	r.GET("/events/:id", func(c *gin.Context) {
		id, err := strconv.Atoi(c.Param("id"))
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "the event id must be a number"})
			return
		}
		mu.Lock()
		defer mu.Unlock()
		e, ok := events[id]
		if !ok {
			c.JSON(http.StatusNotFound, gin.H{"error": "no such event"})
			return
		}
		c.JSON(http.StatusOK, e)
	})
	r.POST("/events/:id/tickets", func(c *gin.Context) {
		id, _ := strconv.Atoi(c.Param("id"))
		var p purchase
		if err := c.ShouldBindJSON(&p); err != nil {
			c.JSON(http.StatusUnprocessableEntity, gin.H{"error": err.Error()})
			return
		}
		mu.Lock()
		defer mu.Unlock()
		e, ok := events[id]
		if !ok {
			c.JSON(http.StatusNotFound, gin.H{"error": "no such event"})
			return
		}
		if e.Seats-e.Sold < p.Quantity {
			c.JSON(http.StatusConflict, gin.H{"error": "not enough seats left"})
			return
		}
		e.Sold += p.Quantity
		c.JSON(http.StatusCreated, gin.H{"event_id": id, "remaining": e.Seats - e.Sold})
	})
	r.Run("localhost:8080")
}
```

What changed against the standard version:

- **`gin.Default()`** builds the router with two middlewares already attached, a logger and a panic
  recovery, the two lesson 2 wrote by hand.
- **`:id` in the pattern** and `c.Param("id")` to read it, the httprouter spelling.
- **`c.JSON(status, value)`** sets the type, the status and the body in one call. `gin.H` is a
  `map[string]any` with a shorter name.
- **`binding:"required,min=1,max=10"`** on the struct, and `c.ShouldBindJSON(&p)` both decodes the
  body and checks those rules, using the `go-playground/validator` library that lesson 3 section 04
  mentioned. The quantity check is no longer code in the handler.

## Building it

```
ana@vm:~/fw/gin$ go mod tidy
go: finding module for package github.com/gin-gonic/gin
go: found github.com/gin-gonic/gin in github.com/gin-gonic/gin v1.12.0
ana@vm:~/fw/gin$ go build -o server . && ls -l server
-rwxr-xr-x 1 ana ana 31606863 Oct 16 19:44 server
```

`go mod tidy` read the import, found Gin's latest release, **v1.12.0**, and wrote it and everything
it needs into `go.mod` and `go.sum`. The binary is **31,606,863 bytes**; the standard library version
was 9,807,673. Section 07 counts what makes up the difference.

## Asking it

```
ana@vm:~/fw/gin$ curl -si localhost:8080/events/1
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
Date: Fri, 16 Oct 2026 22:44:21 GMT
Content-Length: 56

{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0}ana@vm:~/fw/gin$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"event_id":1,"remaining":118}ana@vm:~/fw/gin$ curl -s --json '{"quantity": 40, "email": "ana"}' localhost:8080/events/1/tickets
{"error":"Key: 'purchase.Quantity' Error:Field validation for 'Quantity' failed on the 'max' tag\nKey: 'purchase.Email' Error:Field validation for 'Email' failed on the 'email' tag"}ana@vm:~/fw/gin$ curl -s --json '{"quantity": "two"}' localhost:8080/events/1/tickets
{"error":"json: cannot unmarshal string into Go struct field purchase.quantity of type int"}ana@vm:~/fw/gin$ curl -si -X DELETE localhost:8080/events/1
HTTP/1.1 404 Not Found
Content-Type: text/plain
Date: Fri, 16 Oct 2026 22:44:21 GMT
Content-Length: 18

404 page not foundana@vm:~/fw/gin$ curl -si localhost:8080/nothing
HTTP/1.1 404 Not Found
Content-Type: text/plain
Date: Fri, 16 Oct 2026 22:44:21 GMT
Content-Length: 18

404 page not found
```

The prompt lands on the same line as each body because **Gin writes JSON without a final newline**,
which matters to nobody but a person reading `curl`. Three answers matter more:

- **The validation message is the library's, word for word**: `Key: 'purchase.Quantity'
  Error:Field validation for 'Quantity' failed on the 'max' tag`. It names Go struct fields and tag
  names, not the JSON keys a client sent. Gin gives you the rules for free and leaves the message to
  you; a real API would translate those errors into something like lesson 3's `errors` map.
- **`DELETE /events/1` got 404, not 405.** Gin's router can answer 405, and does not by default: the
  setting `HandleMethodNotAllowed` is off unless you turn it on. A client sending the wrong method is
  told the event does not exist.
- The wrong type got `encoding/json`'s own message, because Gin decodes with it.

## What it said on the way up

```
ana@vm:~/fw/gin$ cat -v .server.log
[GIN-debug] [WARNING] Creating an Engine instance with the Logger and Recovery middleware already attached.

[GIN-debug] [WARNING] Running in "debug" mode. Switch to "release" mode in production.
 - using env:	export GIN_MODE=release
 - using code:	gin.SetMode(gin.ReleaseMode)

[GIN-debug] GET    /events/:id               --> main.main.func1 (3 handlers)
[GIN-debug] POST   /events/:id/tickets       --> main.main.func2 (3 handlers)
[GIN-debug] [WARNING] You trusted all proxies, this is NOT safe. We recommend you to set a value.
Please check https://github.com/gin-gonic/gin/blob/master/docs/doc.md#dont-trust-all-proxies for details.
[GIN-debug] Listening and serving HTTP on localhost:8080
[GIN] 2026/10/16 - 19:44:21 | 200 | 75.499M-BM-5s |       127.0.0.1 | GET      "/events/1"
[GIN] 2026/10/16 - 19:44:21 | 201 | 291.122M-BM-5s |       127.0.0.1 | POST     "/events/1/tickets"
[GIN] 2026/10/16 - 19:44:21 | 422 | 87.433M-BM-5s |       127.0.0.1 | POST     "/events/1/tickets"
[GIN] 2026/10/16 - 19:44:21 | 422 | 56.053M-BM-5s |       127.0.0.1 | POST     "/events/1/tickets"
[GIN] 2026/10/16 - 19:44:21 | 404 |    398ns |       127.0.0.1 | DELETE   "/events/1"
[GIN] 2026/10/16 - 19:44:21 | 404 |    422ns |       127.0.0.1 | GET      "/nothing"
```

**Read the warnings, because each is a decision Gin made for you.** Debug mode prints the routes and
these notes; `GIN_MODE=release` silences them. The proxy warning is a security matter: by default
`c.ClientIP()` believes the `X-Forwarded-For` header from anybody, so any client can claim any
address, and a rate limit or an audit log keyed on it can be fooled. `SetTrustedProxies` names the
proxies whose word counts.

One more thing is invisible in the log. **`r.Run` starts the server with `http.ListenAndServe`**,
which lesson 1 section 08 showed has no timeouts at all. A Gin engine is an `http.Handler`, so the
fix is the one boxoffice already uses: build an `http.Server` with the four deadlines, put the
engine in its `Handler` field, and never call `Run`.
