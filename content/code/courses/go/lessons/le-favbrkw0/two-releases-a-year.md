---
title: Two releases a year
version: 1
---

Software is often released "when it is ready", and a language that worked that way would leave you
guessing when the next one comes and how long yours is looked after. **Go is released on a
calendar: a new version every February and every August.** That is not a claim to take on trust,
because the module proxy, the server the go command downloads from, publishes a record for every
release. Each toolchain is a module there, and its `.info` file carries the time it was recorded:

```
ana@vm:~/history$ for v in 21 22 23 24 25 26 27; do curl -s https://proxy.golang.org/golang.org/toolchain/@v/v0.0.1-go1.$v.0.linux-amd64.info; echo; done
{"Version":"v0.0.1-go1.21.0.linux-amd64","Time":"2023-08-04T20:14:06Z"}
{"Version":"v0.0.1-go1.22.0.linux-amd64","Time":"2024-02-02T18:09:55Z"}
{"Version":"v0.0.1-go1.23.0.linux-amd64","Time":"2024-08-07T19:21:44Z"}
{"Version":"v0.0.1-go1.24.0.linux-amd64","Time":"2025-02-10T23:33:55Z"}
{"Version":"v0.0.1-go1.25.0.linux-amd64","Time":"2025-08-08T19:33:32Z"}
{"Version":"v0.0.1-go1.26.0.linux-amd64","Time":"2026-02-10T01:22:00Z"}
{"Version":"v0.0.1-go1.27.0.linux-amd64","Time":"2026-08-18T21:24:23Z"}
```

August, February, August, February, August, February, August. The loop asks for seven releases by
their number, and the name has `linux-amd64` in it because a toolchain is published once per system.
The times are in UTC and fall a few days before each release was announced: go1.21.0 was recorded
on 4 August 2023 and announced on the 8th, the date section 02 gave.

## Two supported at a time

A release is not looked after forever. The Go installation says how long, in its own
`SECURITY.md`:

```
ana@vm:~/history$ sed -n 3,5p /usr/local/go/SECURITY.md
## Supported Versions

We support the past two Go releases (for example, Go 1.17.x and Go 1.18.x when Go 1.18.x is the latest stable release).
```

The release history puts the same rule another way: **each major release is supported until there
are two newer major releases**, and critical problems, security ones included, are fixed in a
supported release by issuing a minor revision. In a version like `go1.27.1`, 27 is the major
release and 1 the minor revision: the first fix release of 1.27. With a release every six months,
supported means about a year.

The proxy shows the rule being applied. Here is what came out around go1.27.0:

```
ana@vm:~/history$ for v in 1.25.14 1.26.7 1.27.0 1.26.8 1.27.1; do curl -s https://proxy.golang.org/golang.org/toolchain/@v/v0.0.1-go$v.linux-amd64.info; echo; done
{"Version":"v0.0.1-go1.25.14.linux-amd64","Time":"2026-08-18T21:44:21Z"}
{"Version":"v0.0.1-go1.26.7.linux-amd64","Time":"2026-08-18T21:44:21Z"}
{"Version":"v0.0.1-go1.27.0.linux-amd64","Time":"2026-08-18T21:24:23Z"}
{"Version":"v0.0.1-go1.26.8.linux-amd64","Time":"2026-08-28T16:20:06Z"}
{"Version":"v0.0.1-go1.27.1.linux-amd64","Time":"2026-08-28T16:20:06Z"}
ana@vm:~/history$ curl -s https://proxy.golang.org/golang.org/toolchain/@v/v0.0.1-go1.25.15.linux-amd64.info; echo
not found: golang.org/toolchain@v0.0.1-go1.25.15.linux-amd64: reading https://go.dev/dl/mod/golang.org/toolchain/@v/v0.0.1-go1.25.15.linux-amd64.info: 404 Not Found
```

On 18 August 2026 go1.27.0 arrived, and within the same hour fix releases for the two before it,
go1.25.14 and go1.26.7. Ten days later came go1.27.1 and go1.26.8, recorded in the same second. There
is no go1.25.15: once 1.27 existed, 1.25 had two newer releases and stopped receiving fixes. **The
release in this lab is a fix release of the newest version, which is the place to be.** On a server,
the rule of thumb that follows is to run the latest minor revision of a supported release, and to
move up at least once a year.

## The go command can fetch another Go

Since Go 1.21 the go command does not have to run the release it came with. The environment
variable `GOTOOLCHAIN` decides, and its default ships in the installation's `go.env`:

```
ana@vm:~/history-auto$ go env GOTOOLCHAIN
local
ana@vm:~/history-auto$ grep GOTOOLCHAIN /usr/local/go/go.env
GOTOOLCHAIN=auto
ana@vm:~/history-auto$ GOTOOLCHAIN=go1.26.0 go version
go: downloading go1.26.0 (linux/amd64)
go version go1.26.0 linux/amd64
ana@vm:~/history-auto$ GOTOOLCHAIN=go1.26.0 go version
go version go1.26.0 linux/amd64
```

The release ships `auto`; the lab sets `local`, as lesson 3 shows, so that every transcript in this
course comes from go1.27.1 and never from a release fetched behind your back. Naming a release
forces it: **`GOTOOLCHAIN=go1.26.0` made the go command download that whole toolchain from the
module proxy and run it**, by itself, with nothing installed by hand. The second time there was no
download, because it was already in the module cache under `~/go`.

`auto` is the everyday setting, and what it does depends on the module. This one asks for 1.25.0:

```go
// Command which prints the release of Go that compiled it.
package main

import (
	"fmt"
	"runtime"
)

func main() {
	fmt.Println("compiled by", runtime.Version())
}
```

```
ana@vm:~/history-auto$ cat go.mod
module example.com/which

go 1.25.0
ana@vm:~/history-auto$ go run .
compiled by go1.27.1
ana@vm:~/history-auto$ GOTOOLCHAIN=go1.24.0+auto go run .
go: downloading go1.25.0 (linux/amd64)
compiled by go1.25.0
```

go1.27.1 is newer than the 1.25.0 the module asks for, so it compiled the program itself. To see
what an older installation does, `go1.24.0+auto` tells the go command to begin as if 1.24.0 were the
release installed and still switch when a module asks for more. The module asked for 1.25.0, so the
go command downloaded go1.25.0 and ran it. **Under `auto`, a `go` line newer than your Go is not an
error: the go command fetches the release the module needs and carries on.** Under `local` it is
the refusal lesson 3 shows.

The `toolchain` line is the module saying which release it would rather be built with, which can be
newer than the minimum its `go` line demands:

```
ana@vm:~/history-auto$ go mod edit -go=1.22 -toolchain=go1.26.0 && cat go.mod
module example.com/which

go 1.22

toolchain go1.26.0
ana@vm:~/history-auto$ GOTOOLCHAIN=go1.24.0+auto go run .
compiled by go1.26.0
ana@vm:~/history-auto$ go run .
compiled by go1.27.1
```

`go 1.22` alone would have been satisfied by 1.24.0. The `toolchain` line pushed the choice up to
go1.26.0, already in the cache. Under `local`, go1.27.1 compiled it itself: it is newer than both
lines, and `local` forbids a switch anyway.

So a `go.mod` answers three questions. **The `go` line is the minimum release and the language
version the code means; the `toolchain` line is the release the module prefers; `GOTOOLCHAIN` is
whether your go command may fetch either one.**
