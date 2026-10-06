---
title: GOPATH then, and workspaces now
version: 1
---

Older tutorials, and plenty of answers on the web, say that **Go code has to live under
`~/go/src`**, in a directory named after its import path. That was true once and is wrong now.
Before modules arrived, the go command found every package by looking inside `GOPATH`, and code
anywhere else could not be built. The go command still says so itself:

```
ana@vm:~/setup$ go help gopath | sed -n '21,24p'
The GOPATH environment variable is also used by a legacy behavior of the
toolchain called GOPATH mode that allows some older projects, created before
modules were introduced in Go 1.11 and never updated to use modules,
to continue to build.
```

That old mode can still be switched on with `GO111MODULE=off`, and it shows the rule better than a
description does. Here is a program in `~/setup-work/hello` that imports a package called
`example.com/greet`, run in GOPATH mode:

```
ana@vm:~/setup-work/hello$ GO111MODULE=off go run .
main.go:6:2: cannot find package "example.com/greet" in any of:
	/usr/local/go/src/example.com/greet (from $GOROOT)
	/home/ana/go/src/example.com/greet (from $GOPATH)
```

**In GOPATH mode, an import path was a directory under one of two roots**, the standard library's
and yours, and those two lines are the whole search. A module changes the question: a directory
with a `go.mod` at its root says what its code is called, wherever on the disk it sits, which is
why lesson 4 could build `~/hello`.

What `~/go` holds today is what the go command downloads and installs for you:

```
ana@vm:~/setup$ ls ~/go ~/go/pkg
/home/ana/go:
bin
pkg

/home/ana/go/pkg:
mod
sumdb
```

`bin` is section 03's `GOBIN`. `pkg/mod` is the module cache, and `pkg/sumdb` is the go command's
own notes on the checksum database. There is no `src`, and nothing of yours belongs in here.

## Two modules of your own, before either is published

The program above is half of a pair. `~/setup-work` holds two modules side by side, each with its
own `go.mod`:

```
ana@vm:~/setup-work$ find . -type f | sort
./greet/go.mod
./greet/greet.go
./hello/go.mod
./hello/main.go
```

`greet` is a library with one function:

```go
// Package greet builds greetings.
package greet

// Hello returns a greeting for name.
func Hello(name string) string {
	return "Hello, " + name
}
```

and `hello` is a program that calls it:

```go
package main

import (
	"fmt"

	"example.com/greet"
)

func main() {
	fmt.Println(greet.Hello("Ana"))
}
```

How an import path maps to a module and why `Hello` starts with a capital letter are lessons 38
and 39. What matters here is that, in module mode, `hello` cannot see its neighbour:

```
ana@vm:~/setup-work/hello$ go run .
main.go:6:2: no required module provides package example.com/greet; to add it:
	go get example.com/greet
```

The suggested fix is the wrong one for this case. `go get` would look for `example.com/greet` on
the network, through the module proxy, and the code is one directory away on this disk. **A
workspace is the way to say "use my copy of that module"**: a file called `go.work` that lists
module directories, which the go command treats as one build. `go work init` creates it and
`go work use` adds to it:

```
ana@vm:~/setup-work$ go work init ./hello
ana@vm:~/setup-work$ go work use ./greet
ana@vm:~/setup-work$ cat go.work
go 1.27.1

use (
	./greet
	./hello
)
ana@vm:~/setup-work$ go run ./hello
Hello, Ana
ana@vm:~/setup-work/hello$ go run .
Hello, Ana
ana@vm:~/setup-work$ cat hello/go.mod
module example.com/hello

go 1.27.1
```

The second `go run` was typed inside `hello` and still found the workspace, because the go command
looks for a `go.work` in the current directory and in every directory above it. And `hello/go.mod`
did not change: it still names no dependency at all. **The workspace lives beside the modules, not
inside them**, so it describes how your disk is arranged and promises nothing to anybody who
downloads `hello` alone.

That is what workspaces are for: changing a library and the program that uses it in the same
afternoon, with neither published yet. A single module, which is every exercise in this course
until lesson 39, needs no `go.work` at all.
