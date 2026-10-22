---
title: The machine from the go course, and one compiler more
version: 1
---

Every lesson of this course asks you to type something and read what comes back. **The machine you
type at is the one the `go` course built**, and this section checks that it still answers. It adds
one thing the `go` course never needed: a C compiler, because the race detector this course leans
on from this lesson to lesson 16 cannot work without one.

## The three paths, in brief

Lesson 3 of `go` gives them in full, with what each costs your computer. Here they are again, and
the course recommends the same one:

| path | what you get | what it means for this course |
|---|---|---|
| **installed** (recommended) | Go 1.27.1 unpacked into `/usr/local/go`, plus `gcc` from your system | every transcript runs as printed on Ubuntu 24.04, and nearly so on macOS |
| **a virtual machine** | an Ubuntu 24.04 machine with the same two things inside it | the same, byte for byte, at the price of a second operating system's disk and memory |
| **online** | the Go Playground at go.dev/play | lessons 1 to 15 in fragments; no terminal, so nowhere to type `go run -race` or `go test` |

The Playground is a fine place to try a fragment on the bus. It is the wrong place for this
course, because half of what the course teaches is how to read what the go command prints, and the
timings in this lesson would be measured on somebody else's machine.

## Go, as the `go` course left it

If you took `go`, you have nothing to install. The archive went into `/usr/local/go` and two lines
went into `~/.profile`. If you did not, lesson 3 of `go` is the long version, and the short one is
the archive from **go.dev/dl**, unpacked after the old directory is removed:

```sh
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.27.1.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.profile
```

That block was **not run in this lab**, which cannot reach go.dev; the lab took the same release
from the module proxy, as lesson 3 of `go` explains. **Use the same release the course was recorded
with**, 1.27.1, and do not keep a second Go beside it. Two toolchains on one `PATH` means the one
that runs is whichever comes first, and a transcript that differs from the lesson is then a puzzle
about your machine rather than about Go.

## The C compiler

**`go run -race` and `go test -race` build your program with the race detector inside it**, and
the race detector is ThreadSanitizer, a runtime written in C++. The go command links it in through
cgo, Go's bridge to C, and cgo needs a C compiler on the machine. On Ubuntu 24.04 that is one
package from the system's own archive:

```sh
sudo apt install gcc
```

That line was **not run in this lab** either, because the lab machine had `gcc` already. `apt`
lists the packages it is about to add and the disk they will take, and asks before it does
anything; the compiler pulls in the assembler, the linker and the C library's headers with it. On
macOS the equivalent is `xcode-select --install`, which installs Apple's command-line tools.

## Checking that each tool answers

Four commands, and every line they print is worth comparing with yours:

```
ana@vm:~/promise$ go version
go version go1.27.1 linux/amd64
ana@vm:~/promise$ command -v go gofmt gcc
/usr/local/go/bin/go
/usr/local/go/bin/gofmt
/usr/bin/gcc
ana@vm:~/promise$ gcc --version | head -1
gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
ana@vm:~/promise$ go env CGO_ENABLED CC
1
gcc
```

The first two lines are the `go` course's machine, unchanged. The last command is the one this
course adds. **`CGO_ENABLED` is `1` because the go command looked for `gcc` and found it**; that is
not a setting anybody wrote, and section 05 shows it turning to `0` on a machine where the search
fails.

One more check proves the whole chain, from the go command to the C runtime. **Every program in
this course lives in a directory of its own in your home**, `~/promise` for this lesson, with a
`go.mod` made by `go mod init example.com/promise` as lesson 38 of `go` showed. Each lesson names
its directory the first time it uses it. This one starts with a program of three goroutines, the
subject of lesson 2, each printing a line, saved as `order.go`:

```go
// Command order starts three goroutines that each print a line.
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	for _, name := range []string{"ana", "bia", "caio"} {
		wg.Go(func() { fmt.Println("hello from", name) })
	}
	wg.Wait()
}
```

`wg.Go` starts a function as a goroutine and `wg.Wait` waits until every one of them has returned;
lesson 9 takes the `WaitGroup` apart. Run with the race detector built in, a program that has no
race prints exactly what it prints without one:

```
ana@vm:~/promise$ go run -race order.go
hello from ana
hello from bia
hello from caio
```

**If yours printed three greetings, the lab is ready**, in whatever order they came. Section 04
explains why the order is not yours to choose.
