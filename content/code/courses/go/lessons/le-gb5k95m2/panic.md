---
title: What a panic is, and what it is for
version: 1
---

Somebody arriving from Java or Python looks for Go's `throw`, finds `panic`, and starts using it to
report a missing file. **A panic is not Go's exception.** It does unwind the calls the way an
exception does, but lesson 32 already gave failures their mechanism, the `error` value. A panic
says something else: the program itself is wrong, and carrying on would only make it wrong in more
places.

## What happens when a program panics

This program in `~/panic` reads one element past the end of a two-element slice:

```go
// Command panic reads one element past the end of a slice.
package main

import "fmt"

func main() {
	scores := []int{7, 9}
	fmt.Println("scores:", len(scores))
	i := len(scores)
	fmt.Println(scores[i])
	fmt.Println("never printed")
}
```

```
ana@vm:~/panic$ go vet && go run .; echo $?
scores: 2
panic: runtime error: index out of range [2] with length 2

goroutine 1 [running]:
main.main()
	/home/ana/panic/main.go:10 +0x73
exit status 2
1
```

`go vet` had nothing to say and the compiler built it, because the value of `i` is only known when
the program runs. The first `Println` worked. Line 10 asked for element 2 of a slice of length 2,
and at that moment the program stopped: `never printed` was not. What came out instead has three
parts.

- The line beginning `panic:` is **what went wrong**. `runtime error` means the Go runtime itself
  noticed, and the rest is the message lesson 12 met when it read past a slice's length.
- From `goroutine 1 [running]:` down is **where it went wrong**, a stack trace: the function that
  was running, `main.main`, and its file and line, `main.go:10`. Lesson 37 reads traces like this
  one frame by frame.
- The **exit status is 2**. The `exit status 2` line and the `1` below it are the go command's own:
  `go run` reports how the program ended and then fails itself with 1. The program on its own says
  2 directly:

```
ana@vm:~/panic$ go build && ./panic; echo $?
scores: 2
panic: runtime error: index out of range [2] with length 2

goroutine 1 [running]:
main.main()
	/home/ana/panic/main.go:10 +0x73
2
```

**A panic stops the program at the line that went wrong, says where, and exits with status 2.** A
program that reports an error and stops by itself usually exits with 1, as the next program does,
so the 2 is worth noticing in a script that runs Go programs.

This course has met the rest of the family already, each time as one line of a lesson about
something else: an integer divided by zero in lesson 7, a write to a nil map in lesson 14, a nil
function called in lesson 21, a nil pointer followed in lesson 23, a type assertion that did not
hold in lesson 28. Every one is the runtime finding that the program asked for something that
cannot be done. And every one is a bug: there is no input for which reading `scores[2]` is the
right thing to do.

## `panic`, called by hand

`panic` is also a built-in function, and a program can call it with any value. The standard library
calls it in one kind of place, and `regexp` shows which. `~/panic-must` checks a word against a
pattern written in the source and against a second pattern typed on the command line, which arrives
in `os.Args` after the program's own name:

```go
// Command must checks a word against a pattern written in the source
// and against one typed on the command line.
package main

import (
	"fmt"
	"os"
	"regexp"
)

var word = regexp.MustCompile(`^[a-z]+$`)

func main() {
	fmt.Println("word:", word.MatchString(os.Args[1]))
	re, err := regexp.Compile(os.Args[2])
	if err != nil {
		fmt.Println("bad pattern:", err)
		os.Exit(1)
	}
	fmt.Println("pattern:", re.MatchString(os.Args[1]))
}
```

```
ana@vm:~/panic-must$ go build && ./must gopher 'go+'
word: true
pattern: true
ana@vm:~/panic-must$ ./must gopher 'go('; echo $?
word: true
bad pattern: error parsing regexp: missing closing ): `go(`
1
```

`regexp.Compile` returns an `error`, and a pattern with an unclosed bracket got one, printed as a
message with exit status 1. Now the same program in `~/panic-mustbug`, with one character lost from
the pattern in the source, `^[a-z+$`:

```
ana@vm:~/panic-mustbug$ go build && ./must gopher 'go+'; echo $?
panic: regexp: Compile(`^[a-z+$`): error parsing regexp: missing closing ]: `[a-z+$`

goroutine 1 [running]:
regexp.MustCompile({0x4ba5a0, 0x7})
	/usr/local/go/src/regexp/regexp.go:312 +0xb4
main.init()
	/home/ana/panic-mustbug/main.go:11 +0x1f
2
```

The program never reached `main`. A package-level variable is set before `main` starts, in the step
the trace calls `main.init`, which lesson 39 comes back to; `MustCompile` panicked there, on line
11. Its source is seven lines of ordinary Go:

```
ana@vm:~/panic-mustbug$ sed -n 309,315p $(go env GOROOT)/src/regexp/regexp.go
func MustCompile(str string) *Regexp {
	regexp, err := Compile(str)
	if err != nil {
		panic(`regexp: Compile(` + quote(str) + `): ` + err.Error())
	}
	return regexp
}
```

It calls `Compile` and turns its error into a panic. **The difference between the two functions is
who wrote the pattern.** A pattern a user typed can be wrong on any run, and the program has to say
so and carry on, so it gets an `error`. A pattern written in the source is wrong only if the
programmer made a mistake. Then it fails on the first run, at the programmer's desk and before
`main`, which is the best place for a bug to be found.

## Bugs panic, failures return

That gives the rule, and the standard library keeps to it:

| what went wrong | who caused it | what Go uses |
|---|---|---|
| a file is missing, a number was mistyped, a server did not answer | the world the program runs in | an `error`, lessons 32 to 35 |
| an index past the end, a nil map written to, a pattern in the source that does not compile | the program's own code | a panic |

**If a caller could cause it with input, return an error. Panic only for what cannot happen in a
correct program.** A library that panics on bad input turns every caller's input into a way to crash
the caller. A `Must` function is the deliberate exception, and its name says so.
