---
title: Installing sqlc
version: 1
---

sqlc is a Go program, and the Go way to install a Go program is `go install`, which downloads its
source, builds it and puts the binary in `~/go/bin`, the directory lesson 1 section 02 put on your
`PATH`. **It needs one more thing than most Go tools: a C compiler.** sqlc understands PostgreSQL's
SQL by using PostgreSQL's own parser, written in C and compiled into sqlc through cgo, Go's bridge to
C. That is why lesson 1 named the compiler among the things this course needs.

## Three ways to get it

| path | what it costs | for this course |
|---|---|---|
| **`go install`** (recommended) | gcc from Ubuntu's archive, about 80 MB, and a minute or more of compiling | the binary every transcript used |
| **a release binary** from sqlc's GitHub page | one download, no compiler | the same program, if you take the same version |
| **the `sqlc/sqlc` container image** | a container engine, which lesson 16 installs | works, with the project mounted into the container |

The C compiler is worth having anyway: lesson 15's race detector needs it too. On Ubuntu it is one
package, and it is the same one `go-concurrency` installed for its race detector in lesson 1:

```sh
sudo apt install -y gcc
```

Then sqlc itself, at the release this lesson was written with:

```
ana@vm:~$ go install github.com/sqlc-dev/sqlc/cmd/sqlc@v1.31.1
ana@vm:~$ sqlc version; command -v sqlc
v1.31.1
/home/ana/go/bin/sqlc
```

The `go install` above printed nothing because the lab had already built this release once, which took
just over a minute of compiling on four cores; the first time, it prints a list of downloads and then
works silently for a while. **Pin the version, `@v1.31.1`, rather than `@latest`**: generated code
carries the version that made it, and two developers on two versions regenerate each other's files
back and forth.

## When the compiler is missing

On a machine with no C compiler, the build stops at the first package that needs one:

```
ana@vm:~$ CC=gcc-missing go install github.com/sqlc-dev/sqlc/cmd/sqlc@v1.31.1
# runtime/cgo
cgo: C compiler "gcc-missing" not found: exec: "gcc-missing": executable file not found in $PATH
ana@vm:~$ gcc --version | head -1
gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1) 13.3.0
```

The lab has gcc, so this failure was produced by pointing `CC`, the variable cgo reads to find the
compiler, at one that does not exist; **without gcc installed, the message is the same with `gcc` in
it.** `runtime/cgo` is the first package that needs C. The fix is the `apt install` above, and the
second command shows what a working compiler answers.
