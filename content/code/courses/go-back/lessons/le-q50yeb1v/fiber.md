---
title: Fiber
version: 1
---

The first three versions of this API have one thing in common that is easy to miss: **underneath,
all of them are `net/http`.** Gin's engine and Echo's are `http.Handler`s; a standard middleware
wraps them, an `http.Server` runs them. Fiber is the exception. **It is built on `fasthttp`**, a
separate HTTP implementation written for raw speed, and its API copies Express, the Node.js framework,
on purpose, so that people coming from JavaScript feel at home. The release here is **v3.6.1**.

```go
// fw/fiber/main.go
package main

import (
	"log"
	"strconv"
	"sync"

	"github.com/gofiber/fiber/v3"
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
	app := fiber.New()
	app.Get("/events/:id", func(c fiber.Ctx) error {
		id, err := strconv.Atoi(c.Params("id"))
		if err != nil {
			return fiber.NewError(fiber.StatusBadRequest, "the event id must be a number")
		}
		mu.Lock()
		defer mu.Unlock()
		e, ok := events[id]
		if !ok {
			return fiber.NewError(fiber.StatusNotFound, "no such event")
		}
		return c.JSON(e)
	})
	app.Post("/events/:id/tickets", func(c fiber.Ctx) error {
		id, _ := strconv.Atoi(c.Params("id"))
		var p purchase
		if err := c.Bind().JSON(&p); err != nil {
			return err
		}
		if p.Quantity < 1 || p.Quantity > 10 {
			return fiber.NewError(fiber.StatusUnprocessableEntity, "quantity must be between 1 and 10")
		}
		mu.Lock()
		defer mu.Unlock()
		e, ok := events[id]
		if !ok {
			return fiber.NewError(fiber.StatusNotFound, "no such event")
		}
		if e.Seats-e.Sold < p.Quantity {
			return fiber.NewError(fiber.StatusConflict, "not enough seats left")
		}
		e.Sold += p.Quantity
		return c.Status(fiber.StatusCreated).JSON(fiber.Map{"event_id": id, "remaining": e.Seats - e.Sold})
	})
	log.Fatal(app.Listen("localhost:8080"))
}
```

It reads like Echo: handlers return an `error`, `fiber.NewError` carries a status, and
`c.Status(201).JSON(...)` answers. `c.Bind().JSON(&p)` decodes. The `Ctx` is an interface value in
v3, not a pointer.

## Building and asking it

```
ana@vm:~/fw/fiber$ go mod tidy
go: finding module for package github.com/gofiber/fiber/v3
go: found github.com/gofiber/fiber/v3 in github.com/gofiber/fiber/v3 v3.6.1
ana@vm:~/fw/fiber$ go build -o server . && ls -l server
-rwxr-xr-x 1 ana ana 15285110 Oct 16 19:44 server
```

```
ana@vm:~/fw/fiber$ curl -si localhost:8080/events/1
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 22:44:32 GMT
Content-Type: application/json; charset=utf-8
Content-Length: 56

{"id":1,"name":"Jazz at the Docks","seats":120,"sold":0}ana@vm:~/fw/fiber$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"event_id":1,"remaining":118}ana@vm:~/fw/fiber$ curl -s --json '{"quantity": 40, "email": "ana"}' localhost:8080/events/1/tickets
quantity must be between 1 and 10ana@vm:~/fw/fiber$ curl -s --json '{"quantity": "two"}' localhost:8080/events/1/tickets
bind "quantity" from body: json: cannot unmarshal string into Go struct field purchase.quantity of type intana@vm:~/fw/fiber$ curl -si -X DELETE localhost:8080/events/1
HTTP/1.1 405 Method Not Allowed
Date: Fri, 16 Oct 2026 22:44:32 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 18
Allow: GET, HEAD

Method Not Allowedana@vm:~/fw/fiber$ curl -si localhost:8080/nothing
HTTP/1.1 404 Not Found
Date: Fri, 16 Oct 2026 22:44:32 GMT
Content-Type: text/plain; charset=utf-8
Content-Length: 9

Not Found
```

The success and the event are JSON. **The errors are plain text**, the message and nothing else,
because Fiber's default error handler writes `err.Error()` as text; an API that wants JSON errors
installs its own handler in `fiber.Config`. The 405 is honest and carries `Allow: GET, HEAD`, as
the standard library's did.

```
ana@vm:~/fw/fiber$ cat -v .server.log

    _______ __
   / ____(_) /_  ___  _____
  / /_  / / __ \/ _ \/ ___/
 / __/ / / /_/ /  __/ /
/_/   /_/_.___/\___/_/          v3.6.1
--------------------------------------------------
INFO Server started on: 	http://127.0.0.1:8080
INFO Total handlers: 		3
INFO Prefork: 			Disabled
INFO PID: 			23515
INFO Total process count: 	1
```

A banner, the address and a count of handlers. No line per request: Fiber's logger is a middleware
you add.

## What "not `net/http`" costs

`fasthttp` gets its speed by reusing memory between requests, and that leaks into the rules for using
Fiber. **A string read from a `fiber.Ctx` belongs to a buffer that the next request reuses**, so a
value kept after the handler returns, put in a map or handed to a goroutine, can change under you
unless it is copied first; Fiber's documentation warns about this, and has a setting that makes
every value a copy at a cost in speed. And because a Fiber handler is not an `http.Handler`:

- **none of the `net/http` middleware in the Go ecosystem plugs in directly**, lesson 2's included;
  Fiber ships an adaptor package to bridge the two, and its own set of middleware;
- `httptest`, which lesson 15 uses to test handlers, does not apply as it is; Fiber has `app.Test`
  instead;
- `fasthttp` does not speak HTTP/2, which `net/http` does without being asked.

The binary is **15,285,110 bytes**, with 25 modules besides your own. **Fiber is fast**, and the
speed is real; the question lesson 5 asks is whether an API that spends its time waiting on a
database ever notices it.
