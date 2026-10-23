---
title: Echo
version: 1
---

**Echo's one big idea is that a handler returns an error.** Where a standard handler and a Gin
handler write their failure and `return`, an Echo handler `return`s the failure, and one function
for the whole server, the HTTP error handler, turns it into a response. That is the shape lesson 3
built by hand with `fail`, moved into the framework. The release used here is **v5.4.0**, the fifth
major version, where the context became a struct passed by pointer, `*echo.Context`.

```go
// fw/echo/main.go
package main

import (
	"net/http"
	"strconv"
	"sync"

	"github.com/labstack/echo/v5"
	"github.com/labstack/echo/v5/middleware"
)

type event struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Seats int    `json:"seats"`
	Sold  int    `json:"sold"`
}

type purchase struct {
	Quantity int    `json:"quantity"`
	Email    string `json:"email"`
}

var (
	mu     sync.Mutex
	events = map[int]*event{1: {ID: 1, Name: "Jazz at the Docks", Seats: 120}}
)

func main() {
	e := echo.New()
	e.Use(middleware.RequestLogger())
	e.GET("/events/:id", func(c *echo.Context) error {
		id, err := strconv.Atoi(c.Param("id"))
		if err != nil {
			return echo.NewHTTPError(http.StatusBadRequest, "the event id must be a number")
		}
		mu.Lock()
		defer mu.Unlock()
		ev, ok := events[id]
		if !ok {
			return echo.NewHTTPError(http.StatusNotFound, "no such event")
		}
		return c.JSON(http.StatusOK, ev)
	})
	e.POST("/events/:id/tickets", func(c *echo.Context) error {
		id, _ := strconv.Atoi(c.Param("id"))
		var p purchase
		if err := c.Bind(&p); err != nil {
			return err
		}
		if p.Quantity < 1 || p.Quantity > 10 {
			return echo.NewHTTPError(http.StatusUnprocessableEntity, "quantity must be between 1 and 10")
		}
		mu.Lock()
		defer mu.Unlock()
		ev, ok := events[id]
		if !ok {
			return echo.NewHTTPError(http.StatusNotFound, "no such event")
		}
		if ev.Seats-ev.Sold < p.Quantity {
			return echo.NewHTTPError(http.StatusConflict, "not enough seats left")
		}
		ev.Sold += p.Quantity
		return c.JSON(http.StatusCreated, map[string]int{"event_id": id, "remaining": ev.Seats - ev.Sold})
	})
	if err := e.Start("localhost:8080"); err != nil {
		e.Logger.Error("server stopped", "error", err)
	}
}
```

- **`return echo.NewHTTPError(status, message)`** is the failure, and the handler stops there.
- **`return c.JSON(status, value)`** is the success, because writing can fail too.
- **`c.Bind(&p)`** decodes the body; Echo has no validation of its own, so the quantity check stayed
  in the handler.
- **`middleware.RequestLogger()`** is the access log, opted into rather than attached by default.

## Building and asking it

```
ana@vm:~/fw/echo$ go mod tidy
go: finding module for package github.com/labstack/echo/v5/middleware
go: finding module for package github.com/labstack/echo/v5
go: found github.com/labstack/echo/v5 in github.com/labstack/echo/v5 v5.4.0
go: found github.com/labstack/echo/v5/middleware in github.com/labstack/echo/v5 v5.4.0
ana@vm:~/fw/echo$ go build -o server . && ls -l server
-rwxr-xr-x 1 ana ana 11094543 Oct 16 19:44 server
```

```
ana@vm:~/fw/echo$ curl -si localhost:8080/events/1
HTTP/1.1 200 OK
Content-Type: application/json
Date: Fri, 16 Oct 2026 22:44:26 GMT
Content-Length: 57

{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0}
ana@vm:~/fw/echo$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"event_id":1,"remaining":118}
ana@vm:~/fw/echo$ curl -s --json '{"quantity": 40, "email": "ana"}' localhost:8080/events/1/tickets
{"message":"quantity must be between 1 and 10"}
ana@vm:~/fw/echo$ curl -s --json '{"quantity": "two"}' localhost:8080/events/1/tickets
{"message":"Bad Request"}
ana@vm:~/fw/echo$ curl -si -X DELETE localhost:8080/events/1
HTTP/1.1 405 Method Not Allowed
Allow: OPTIONS, GET
Content-Type: application/json
Date: Fri, 16 Oct 2026 22:44:26 GMT
Content-Length: 33

{"message":"Method Not Allowed"}
ana@vm:~/fw/echo$ curl -si localhost:8080/nothing
HTTP/1.1 404 Not Found
Content-Type: application/json
Date: Fri, 16 Oct 2026 22:44:26 GMT
Content-Length: 24

{"message":"Not Found"}
```

**Every error came back as JSON, `{"message": ...}`, without anybody writing a format**: the 422,
the 405, the 404 for a path nobody registered. That is the central error handler at work, and it is
the thing lesson 3 section 05 could not get from `ServeMux` without losing the 405. Echo kept it,
with an `Allow` header that lists `OPTIONS` and `GET`.

**The type error is the interesting one.** The client was told only `Bad Request`. The detail, which
field and which type, was kept back. Here is why:

```
ana@vm:~/fw/echo$ cat -v .server.log
{"time":"2026-10-16T19:44:26.383712874-03:00","level":"INFO","msg":"Echo (v5.4.0). High performance, minimalist Go web framework https://echo.labstack.com","version":"5.4.0"}
{"time":"2026-10-16T19:44:26.383770378-03:00","level":"INFO","msg":"http(s) server started","address":"127.0.0.1:8080"}
{"time":"2026-10-16T19:44:26.591283396-03:00","level":"INFO","msg":"REQUEST","method":"GET","uri":"/events/1","status":200,"latency":116616,"host":"localhost:8080","bytes_in":"","bytes_out":57,"user_agent":"curl/8.5.0","remote_ip":"127.0.0.1","request_id":""}
{"time":"2026-10-16T19:44:26.612118897-03:00","level":"INFO","msg":"REQUEST","method":"POST","uri":"/events/1/tickets","status":201,"latency":168526,"host":"localhost:8080","bytes_in":"43","bytes_out":31,"user_agent":"curl/8.5.0","remote_ip":"127.0.0.1","request_id":""}
{"time":"2026-10-16T19:44:26.628513814-03:00","level":"ERROR","msg":"REQUEST_ERROR","method":"POST","uri":"/events/1/tickets","status":422,"latency":60899,"host":"localhost:8080","bytes_in":"32","bytes_out":48,"user_agent":"curl/8.5.0","remote_ip":"127.0.0.1","request_id":"","error":"code=422, message=quantity must be between 1 and 10"}
{"time":"2026-10-16T19:44:26.643519826-03:00","level":"ERROR","msg":"REQUEST_ERROR","method":"POST","uri":"/events/1/tickets","status":400,"latency":41588,"host":"localhost:8080","bytes_in":"19","bytes_out":26,"user_agent":"curl/8.5.0","remote_ip":"127.0.0.1","request_id":"","error":"code=400, message=Bad Request, err=json: cannot unmarshal string into Go struct field purchase.quantity of type int"}
{"time":"2026-10-16T19:44:26.659903952-03:00","level":"ERROR","msg":"REQUEST_ERROR","method":"DELETE","uri":"/events/1","status":405,"latency":29069,"host":"localhost:8080","bytes_in":"","bytes_out":33,"user_agent":"curl/8.5.0","remote_ip":"127.0.0.1","request_id":"","error":"Method Not Allowed"}
{"time":"2026-10-16T19:44:26.676634416-03:00","level":"ERROR","msg":"REQUEST_ERROR","method":"GET","uri":"/nothing","status":404,"latency":23047,"host":"localhost:8080","bytes_in":"","bytes_out":24,"user_agent":"curl/8.5.0","remote_ip":"127.0.0.1","request_id":"","error":"Not Found"}
```

The log is JSON, one object per line, and the 400's line carries the whole story in `error`:
`json: cannot unmarshal string into Go struct field purchase.quantity of type int`. **Echo decided
that a decoding error's text is for the operator, not for the caller**, which is the cautious
default; lesson 3 decided the opposite for its own rewritten messages, because those said nothing
about the code. Both are defensible; what matters is that the framework made the choice and you
should know which one it made.

The binary is **11,094,543 bytes**, and `go list -m all` names eight modules besides your own, the fewest
of the four. Echo keeps its dependencies short on purpose, and much of what it does not include, like
validation, is left to you.
