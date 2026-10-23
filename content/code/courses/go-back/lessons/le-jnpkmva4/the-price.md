---
title: The price of a dependency
version: 1
---

A framework's cost is not its download size. **It is everything that comes with letting someone
else's code decide how your service is shaped**, paid a little at a time for as long as the service
lives. Lesson 4 measured the first part of it.

## Modules you now look after

Gin brought 55 modules into the module graph, Fiber 25, Beego 102. Each is code that runs inside your
process with all of its permissions. **When one of them has a known vulnerability, your service has
it**, whether or not you call the vulnerable function, until somebody checks and upgrades. Go has a
tool that reads the module graph against a database of known vulnerabilities and reports only the
ones your code can reach; `go-production` lesson 9 teaches it, and on a service with a hundred modules
it is a weekly job, not a curiosity.

Each module also has a licence, a maintainer who may stop, and its own idea of when to break
compatibility. **`gorilla/mux`, for years the default router of the Go world, was archived in
December 2022**, and every project using it had to decide whether to wait or migrate, until new
maintainers took it over in 2023.

## A major version is every handler

In a framework, **the handler's signature belongs to the framework**. Lesson 4's Echo program was
written for v5, where a handler takes `*echo.Context`. Here is the same file with nothing changed but
the import, built against v4, the major version Echo shipped for years before v5:

```
ana@vm:~/fw/echo4$ sed -i "s#labstack/echo/v5#labstack/echo/v4#g" main.go && grep echo/v4 main.go
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
ana@vm:~/fw/echo4$ go mod tidy
go: finding module for package github.com/labstack/echo/v4/middleware
go: finding module for package github.com/labstack/echo/v4
go: downloading github.com/labstack/echo/v4 v4.16.0
go: found github.com/labstack/echo/v4 in github.com/labstack/echo/v4 v4.16.0
go: found github.com/labstack/echo/v4/middleware in github.com/labstack/echo/v4 v4.16.0
go: downloading golang.org/x/crypto v0.53.0
go: downloading github.com/labstack/gommon v0.5.0
go: downloading golang.org/x/net v0.56.0
go: downloading github.com/valyala/fasttemplate v1.2.2
go: downloading github.com/mattn/go-colorable v0.1.15
go: downloading github.com/mattn/go-isatty v0.0.22
go: downloading golang.org/x/sys v0.46.0
ana@vm:~/fw/echo4$ go build -o server .
# example.com/fw/echo4
./main.go:33:23: cannot use func(c *echo.Context) error {…} (value of type func(c *echo.Context) error) as echo.HandlerFunc value in argument to e.GET
./main.go:34:29: c.Param undefined (type *echo.Context is pointer to interface, not interface)
./main.go:44:12: c.JSON undefined (type *echo.Context is pointer to interface, not interface)
./main.go:46:32: cannot use func(c *echo.Context) error {…} (value of type func(c *echo.Context) error) as echo.HandlerFunc value in argument to e.POST
./main.go:47:27: c.Param undefined (type *echo.Context is pointer to interface, not interface)
./main.go:49:15: c.Bind undefined (type *echo.Context is pointer to interface, not interface)
./main.go:65:12: c.JSON undefined (type *echo.Context is pointer to interface, not interface)
```

**Seven errors, one for every place the file touches the context**, and in a real service it would be
one for every handler and every middleware. In v4, `echo.Context` is an interface and a handler takes
it by value; in v5 it is a struct and a handler takes a pointer. Moving a service from one to the other
is a change to every route it has. It is a mechanical change and a framework is entitled to make it,
which is what a major version is for, and it is exactly the kind of work that **a handler written as
`func(w http.ResponseWriter, r *http.Request)` has never been asked to do since Go 1**.

## A bigger thing to ship

The binary of lesson 4's Gin version was 31.6 MB against 9.8 MB for the standard library's, for the
same two routes. **Size alone rarely matters on a server**, and it matters a little more in the
container image lesson 16 builds, which every deployment pulls, and in the time it takes to build and
scan. It is the smallest of these costs, and the easiest to measure.

## And a second thing to learn

Every developer who joins the team has to learn Go, and then the framework: its context, its binding
rules, its error handler, its defaults. **A Go developer who has never seen boxoffice can read every
line of it on the first day**, because it uses nothing that is not in the standard library's
documentation. That is not true of a Gin or Beego service, however clean.
