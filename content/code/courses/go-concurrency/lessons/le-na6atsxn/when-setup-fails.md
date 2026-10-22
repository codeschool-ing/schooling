---
title: When the setup fails
version: 1
---

Lesson 3 of `go` covers the failures of Go itself: `go: command not found`, a `go.mod` asking for a
newer release, a module proxy that cannot be reached. This section covers the ones this course
adds, which all come down to the C compiler. **Each has one cause, and the message names it.** The
lab machine has `gcc`, so to show what a machine without one says, the commands below give the
shell a `PATH` holding only Go's own directory. The go command looks for `gcc` there, finds
nothing, and behaves exactly as it would on a machine where `gcc` was never installed.

## `-race requires cgo`

```
ana@vm:~/promise$ PATH=/usr/local/go/bin go env CGO_ENABLED
0
ana@vm:~/promise$ PATH=/usr/local/go/bin go run -race count.go; echo $?
go: -race requires cgo; enable cgo by setting CGO_ENABLED=1
2
```

**The first line is the diagnosis and the second is the symptom.** With no C compiler in sight the
go command turns cgo off by itself, `CGO_ENABLED` reads `0`, and the race detector, which needs
cgo, refuses before compiling anything. Everything without `-race` keeps working, which is why
this failure tends to surface on the first day somebody asks for the detector.

The message suggests setting `CGO_ENABLED=1`. On a machine without a compiler that only moves the
failure one step further:

```
ana@vm:~/promise$ PATH=/usr/local/go/bin CGO_ENABLED=1 go run -race count.go; echo $?
# runtime/cgo
cgo: C compiler "gcc" not found: exec: "gcc": executable file not found in $PATH
1
```

Now the go command tried to compile the C half of the runtime and named the program it could not
find. **The repair for both is the one in section 02, `sudo apt install gcc`**, after which
`go env CGO_ENABLED` prints `1` without anybody setting it.

## The same message on a machine that has `gcc`

The refusal also appears where a compiler is installed, because `CGO_ENABLED` was set to `0` by
hand somewhere:

```
ana@vm:~/promise$ CGO_ENABLED=0 go run -race count.go; echo $?
go: -race requires cgo; enable cgo by setting CGO_ENABLED=1
2
```

It is a common setting, because a program built with cgo off is fully static and copies to any
Linux machine, and many build scripts and container recipes set it for that reason. It may sit in
your shell's environment, in `~/.profile`, or in the go command's own file written by `go env -w`.
`go env -changed` lists every setting that differs from the default, wherever it came from, as
lesson 3 of `go` showed; `go env -u CGO_ENABLED` removes it from the go command's file, and
`unset CGO_ENABLED` removes it from the shell.

## A short check, before you ask anyone

Five commands answer most questions about this course's lab:

1. `go version`: `go1.27.1`, and no other release.
2. `command -v go gcc`: which files those are, and that both exist.
3. `go env CGO_ENABLED CC`: `1` and `gcc`.
4. `go env -changed`: anything somebody set, in any of the three places.
5. `go run -race order.go`, with section 02's program: three greetings, in any order.
