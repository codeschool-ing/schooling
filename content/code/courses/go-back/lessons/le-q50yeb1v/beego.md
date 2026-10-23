---
title: Beego
version: 1
---

Gin, Echo and Fiber are web frameworks: routing, binding, middleware, and the rest is yours. **Beego
is a full-stack framework in the tradition of Ruby on Rails and Django.** It brings an MVC structure
with controllers, its own ORM, a configuration system, sessions, a cache, a task scheduler, an admin
page and a command-line tool, `bee`, that generates a project's skeleton. It is used most in China,
where it was written, and the release here is **v2.3.10**.

Its functional routes are the closest it comes to the others, so that is what this version uses:

```go
// fw/beego/main.go
package main

import (
	"encoding/json"
	"net/http"
	"strconv"
	"sync"

	"github.com/beego/beego/v2/server/web"
	"github.com/beego/beego/v2/server/web/context"
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

func fail(ctx *context.Context, status int, msg string) {
	ctx.Output.SetStatus(status)
	ctx.Output.JSON(map[string]string{"error": msg}, false, false)
}

func main() {
	web.BConfig.CopyRequestBody = true
	web.Get("/events/:id", func(ctx *context.Context) {
		id, err := strconv.Atoi(ctx.Input.Param(":id"))
		if err != nil {
			fail(ctx, http.StatusBadRequest, "the event id must be a number")
			return
		}
		mu.Lock()
		defer mu.Unlock()
		e, ok := events[id]
		if !ok {
			fail(ctx, http.StatusNotFound, "no such event")
			return
		}
		ctx.Output.JSON(e, false, false)
	})
	web.Post("/events/:id/tickets", func(ctx *context.Context) {
		id, _ := strconv.Atoi(ctx.Input.Param(":id"))
		var p purchase
		if err := json.Unmarshal(ctx.Input.RequestBody, &p); err != nil {
			fail(ctx, http.StatusBadRequest, err.Error())
			return
		}
		if p.Quantity < 1 || p.Quantity > 10 {
			fail(ctx, http.StatusUnprocessableEntity, "quantity must be between 1 and 10")
			return
		}
		mu.Lock()
		defer mu.Unlock()
		e, ok := events[id]
		if !ok {
			fail(ctx, http.StatusNotFound, "no such event")
			return
		}
		if e.Seats-e.Sold < p.Quantity {
			fail(ctx, http.StatusConflict, "not enough seats left")
			return
		}
		e.Sold += p.Quantity
		ctx.Output.SetStatus(http.StatusCreated)
		ctx.Output.JSON(map[string]int{"event_id": id, "remaining": e.Seats - e.Sold}, false, false)
	})
	web.Run("localhost:8080")
}
```

Two things show the full-stack inheritance. **`web.BConfig.CopyRequestBody = true`** is needed for
`ctx.Input.RequestBody` to hold the body at all, a setting that belongs to Beego's global
configuration object. And the parameter is read as `ctx.Input.Param(":id")`, colon included.

## Building and asking it

```
ana@vm:~/fw/beego$ go mod tidy
go: finding module for package github.com/beego/beego/v2/server/web
go: finding module for package github.com/beego/beego/v2/server/web/context
go: found github.com/beego/beego/v2/server/web in github.com/beego/beego/v2 v2.3.10
go: found github.com/beego/beego/v2/server/web/context in github.com/beego/beego/v2 v2.3.10
go: finding module for package github.com/kr/text
go: found github.com/kr/text in github.com/kr/text v0.2.0
ana@vm:~/fw/beego$ go build -o server . && ls -l server
-rwxr-xr-x 1 ana ana 21684349 Oct 16 19:44 server
```

```
ana@vm:~/fw/beego$ curl -si localhost:8080/events/1
HTTP/1.1 200 OK
Content-Length: 56
Content-Type: application/json; charset=utf-8
Date: Fri, 16 Oct 2026 22:44:37 GMT

{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0}ana@vm:~/fw/beego$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"event_id":1,"remaining":118}ana@vm:~/fw/beego$ curl -s --json '{"quantity": 40, "email": "ana"}' localhost:8080/events/1/tickets
{"error":"quantity must be between 1 and 10"}ana@vm:~/fw/beego$ curl -s --json '{"quantity": "two"}' localhost:8080/events/1/tickets
{"error":"json: cannot unmarshal string into Go struct field purchase.quantity of type int"}ana@vm:~/fw/beego$ curl -si -X DELETE localhost:8080/events/1 | head -5
HTTP/1.1 404 Not Found
Date: Fri, 16 Oct 2026 22:44:37 GMT
Content-Length: 2000
Content-Type: text/html; charset=utf-8

ana@vm:~/fw/beego$ curl -s localhost:8080/nothing | grep -i -e title -e powered
		<title>Not Found</title>
					<a href="/" title="Home" class="button">Go Home</a><br />
					<br>Powered by beego 2.0.0
```

The routes answer like the others. **The two failures nobody wrote are where Beego shows itself**:
the wrong method and the unknown path both get a 404 that is a **2,000-byte HTML page**, with a
stylesheet, a "Go Home" button and a line that says it was powered by beego 2.0.0, though the
module is 2.3.10. A client of a JSON API receives a web page meant for a person in a browser. It
can be replaced, by registering error handlers with Beego, and it is a fair picture of the
trade: **a full-stack framework answers a great many questions before you have asked them**, and
each answer has to be found and changed when it is not the one you wanted.

```
ana@vm:~/fw/beego$ cat -v .server.log
init global config instance failed. If you do not use this, just ignore it.  open conf/app.conf: no such file or directory
2026/10/16 19:44:37.207 ^[[1;34m[I]^[[0m  http server Running on http://localhost:8080
```

The first line complains that `conf/app.conf` does not exist, because Beego expects a project laid
out its way. The second carries terminal colour codes even though nobody was watching a terminal:
`cat -v` shows them as `^[`. **A log meant to be read by a machine should not contain them**, and
lesson 12 is about logs a machine can read.

The binary is **21,684,349 bytes**, and `go list -m all` names **102 modules besides your own**, the
most of the four by far, because the ORM, the cache and the rest come along whether this program
uses them or not.
