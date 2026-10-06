---
title: The Go 1 promise, and the line that keeps it
version: 1
---

A common habit with programming languages is to stay on an old release for as long as possible,
because the new one will break something. Go was designed against that habit. The document that
came with Go 1, published at go.dev/doc/go1compat, says it in one sentence: **"It is intended that
programs written to the Go 1 specification will continue to compile and run correctly, unchanged,
over the lifetime of that specification."** The same document draws the line at source code:
a program is compiled again by the new release, and the files a release produced are not promised
to work with the next one.

A promise like that leaves a question. Go has improved for fourteen years since, and some of the
improvements change what existing code does. The answer is a line lesson 4 writes into the first
module of the course: the `go` line of `go.mod`.

## One program, two answers

The program below collects three small functions inside a loop and calls them after the loop has
finished. How a function can remember a variable is lesson 21; what matters here is that each
function returns the `i` it saw:

```go
// Command loop keeps a function from each turn of a loop and calls them afterwards.
package main

import "fmt"

func main() {
	var funcs []func() int
	for i := 0; i < 3; i++ {
		funcs = append(funcs, func() int { return i })
	}
	var got []int
	for _, f := range funcs {
		got = append(got, f())
	}
	fmt.Println(got)
}
```

Same file, same compiler, go1.27.1 both times. Only the `go` line changes:

```
ana@vm:~/history-loop$ go mod edit -go=1.21 && cat go.mod
module example.com/loop

go 1.21
ana@vm:~/history-loop$ go run .
[3 3 3]
ana@vm:~/history-loop$ go mod edit -go=1.22 && go run .
[0 1 2]
```

`go mod edit -go=` rewrites that one line, which is safer than editing the file by hand. Under
`go 1.21` the loop has a single `i`, shared by all three functions, and by the time they are called
it has reached 3. Under `go 1.22` every turn of the loop gets an `i` of its own, so the functions
return 0, 1 and 2. The release notes of 1.22 give the reason: a shared variable caused "accidental
sharing bugs", and `[0 1 2]` is what almost everybody who wrote that loop meant.

**The `go` line says which version of the language the module was written for, and the compiler
keeps that version's meaning.** A module that still says `go 1.21` gets `[3 3 3]` from every
release, so upgrading the toolchain changed nothing for it. A module changes behaviour on the day
somebody edits its `go` line, which is a change in a file that a reviewer can see.

## The line is also a minimum

The `go` line works in the other direction too. This program uses generics, from Go 1.18, which
lessons 30 and 31 teach:

```go
// Command biggest uses a generic function.
package main

import "fmt"

func Biggest[T int | float64](a, b T) T {
	if a > b {
		return a
	}
	return b
}

func main() {
	fmt.Println(Biggest(3, 7), Biggest(2.5, 1.5))
}
```

```
ana@vm:~/history-generic$ go mod edit -go=1.17 && go build; echo $?
# example.com/biggest
./main.go:6:14: type parameter requires go1.18 or later (-lang was set to go1.17; check go.mod)
./main.go:6:16: embedding interface element int | float64 requires go1.18 or later (-lang was set to go1.17; check go.mod)
./main.go:7:5: invalid operation: a > b (type parameter T cannot use operator >)
./main.go:14:14: implicit function instantiation requires go1.18 or later (-lang was set to go1.17; check go.mod)
1
ana@vm:~/history-generic$ go mod edit -go=1.18 && go run .
7 2.5
```

go1.27.1 knows generics perfectly well and refused them anyway, because the module said `go 1.17`.
The messages say exactly that: `-lang was set to go1.17; check go.mod`. **A feature newer than the
`go` line is a compile error, even when the compiler has it**, so a module never uses something
that the release it claims to need would not understand. Lesson 13 uses this to find out when two
conversions arrived.

## GODEBUG: the same idea for the library

The loop is the language. Changes in the standard library's behaviour are kept compatible in a
different way: each one gets a named setting in `GODEBUG`, and the `go` line chooses its default.
`go list` shows the defaults a module gets:

```
ana@vm:~/history-loop$ go mod edit -go=1.21 && go list -f '{{.DefaultGODEBUG}}' . | tr , '\n' | grep http
httpcookiemaxnum=0
httplaxcontentlength=1
httpmuxgo121=1
httpservecontentkeepheaders=1
ana@vm:~/history-loop$ go mod edit -go=1.27.1 && go list -f '[{{.DefaultGODEBUG}}]' .
[]
ana@vm:~/history-loop$ grep httpmuxgo121 /usr/local/go/src/internal/godebugs/table.go
	{Name: "httpmuxgo121", Package: "net/http", Changed: 22, Old: "1"},
```

With `go 1.21`, the module gets a list of settings that hold behaviour back; `grep http` keeps the
four that belong to `net/http`. `httpmuxgo121=1` keeps `net/http`'s request router, `ServeMux`,
behaving as it did in Go 1.21, and the Go source's own table says why: the default `Changed` in
1.22, and `Old: "1"` restores what came before. The old router is still in the library, frozen, in
a file called `servemux121.go`. With the `go` line at 1.27.1 the list is empty, because nothing is held
back. The brackets in the template are only there so that an empty answer still prints something.

You do not normally set any of these. They exist so that a module written in 2023 behaves the way
it did in 2023 until somebody moves its `go` line, and so that you can still switch one setting back
by hand, through the `GODEBUG` environment variable, while you fix whatever depended on the old
behaviour.
