---
title: The first server
version: 1
---

**A Go web server is an ordinary program that never returns from `main`**: it opens a port, waits
for a connection, and hands each request to a function you wrote. The standard library's
`net/http` does the waiting, the parsing and the replying. Your part is the function. Here is the
smallest complete one:

```go
// hello/main.go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "hello from %s %s\n", r.Method, r.URL.Path)
	})
	log.Fatal(http.ListenAndServe("localhost:8080", nil))
}
```

The function given to `HandleFunc` receives two things. **`r` is the request**, already parsed:
the method, the path, the headers, the body waiting to be read. **`w` is where the reply goes**,
and anything written to it is sent to the client. `fmt.Fprintf` writes to any `io.Writer`, and a
`ResponseWriter` is one, so the line that answers is the same call that prints to a file.

`ListenAndServe` opens the port and serves until something fails. It only returns with an error,
which is why `log.Fatal` wraps it: if the port cannot be opened, the program says why and exits
rather than sitting there doing nothing.

## Two terminals

Put the file in a directory called `hello`, give it a module, and start it in one terminal:

```
ana@vm:~/hello$ go mod init example.com/hello
go: creating new go.mod: module example.com/hello
go: to add module requirements and sums:
	go mod tidy
ana@vm:~/hello$ go run .
```

`go run .` prints nothing and does not give you the prompt back. That is the server running. Open
a **second terminal** and be its client:

```
ana@vm:~/hello$ curl -s localhost:8080/
hello from GET /
ana@vm:~/hello$ curl -s localhost:8080/events/7
hello from GET /events/7
ana@vm:~/hello$ curl -s -X POST localhost:8080/anything
hello from POST /anything
```

**The one function answered all three**, whatever the path and whatever the method. The pattern
`"/"` matches every path, because a pattern ending in a slash claims everything below it, and this
one claims the whole site. Sections 05 and 06 are about writing patterns that say more.

`-i` asks `curl` to print the response's status line and headers as well:

```
ana@vm:~/hello$ curl -si localhost:8080/
HTTP/1.1 200 OK
Date: Fri, 16 Oct 2026 22:11:44 GMT
Content-Length: 17
Content-Type: text/plain; charset=utf-8

hello from GET /
```

The handler set none of that. **`net/http` filled in the status, the date, the length and the
type**: 200 because nothing said otherwise, 17 because that is how many bytes were written, and
`text/plain` because it looked at those bytes and guessed. Section 07 is about when that guessing
is welcome and when it is not.

## The port is taken

Start a second copy in a third terminal while the first is still running,
and it refuses:

```
ana@vm:~/hello$ go run .
2026/10/16 19:11:44 listen tcp 127.0.0.1:8080: bind: address already in use
exit status 1
```

**`bind: address already in use` means another program holds the port**, and very often that
program is an earlier copy of your own server, left running in a terminal you forgot. Stop it
with Ctrl+C in its own terminal. If you cannot find which one it was, `ss -ltnp` lists every
listening port with the program behind it. The line came from `log.Fatal`, and `exit status 1`
from `go run`, reporting how the program ended.

## `localhost` and `nil`

Two arguments in that program decide more than they appear to.

**`"localhost:8080"` listens on this machine only.** The error message shows it as `127.0.0.1`, an
address nothing outside the computer can reach. Writing `":8080"` instead listens on every
network interface, which is what a server in production does and what a laptop on café Wi-Fi
should not. This course keeps `localhost` until lesson 16 puts the server in a container, where
the outside of the container is the point.

**`nil` as the handler means `http.DefaultServeMux`**, a router that belongs to the package and
that `http.HandleFunc` registers on. It is convenient and it is shared: any package your program
imports can register a route on it as well. `net/http/pprof` does exactly that, adding a set of
`/debug/pprof/` pages the moment it is imported. **From the next section on, every program makes
its own mux** and passes it in, so the routes a server answers are the routes its `main` can see.
