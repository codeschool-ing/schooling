---
title: Defining flags and reading them
version: 1
---

A program that reads its settings from its own source has to be recompiled to change one. **The
`flag` package turns the words after a command's name into typed values**, with defaults, a help
text written for you, and an error when a value is not what the program asked for. It is what the
go command itself uses, and it is enough for most tools a team writes.

Every program in this lesson lives in a directory of its own under `~/flags`, one module for all of
them. The first says hello, saved as `greet/main.go`:

```go
// Command greet says hello, as many times as it is told.
package main

import (
	"flag"
	"fmt"
	"strings"
	"time"
)

func main() {
	name := flag.String("name", "world", "who to greet")
	times := flag.Int("times", 1, "how many greetings")
	shout := flag.Bool("shout", false, "greet in capitals")
	pause := flag.Duration("pause", 0, "wait between greetings")
	flag.Parse()

	msg := "hello, " + *name
	if *shout {
		msg = strings.ToUpper(msg)
	}
	for i := range *times {
		if i > 0 {
			time.Sleep(*pause)
		}
		fmt.Println(msg)
	}
	fmt.Println("left over:", flag.Args())
}
```

**Each `flag.String`, `flag.Int`, `flag.Bool` and `flag.Duration` declares one flag and returns a
pointer** to where its value will be: a name, a default and a line of help. Nothing is read until
`flag.Parse`, which walks the command line, fills the pointers and stops at the first word that is
not a flag. Whatever is left is `flag.Args()`. The program reads `*name` and `*times` after that,
never before.

One `go build` makes all three programs of the lesson, into `bin`:

```
ana@vm:~/flags$ go build -o bin/ ./...
ana@vm:~/flags$ ls bin
greet
tags
tool
```

Then the flags at work:

```
ana@vm:~/flags$ bin/greet
hello, world
left over: []
ana@vm:~/flags$ bin/greet -name=bia -times 2
hello, bia
hello, bia
left over: []
ana@vm:~/flags$ bin/greet -shout -name caio extra words
HELLO, CAIO
left over: [extra words]
ana@vm:~/flags$ time bin/greet -times 3 -pause 1s
hello, world
hello, world
hello, world
left over: []

real	0m2.003s
user	0m0.000s
sys	0m0.003s
```

`-name=bia` and `-name bia` are the same thing, and so are one dash and two. The duration flag
reads the notation of lesson 20, so `-pause 1s` put a second between greetings, and the three
greetings took two seconds of real time. `extra words` were not flags, so `Parse` left them in
`flag.Args()`.

## The help, and the refusal

Nobody wrote a help text, and there is one:

```
ana@vm:~/flags$ bin/greet -h; echo $?
Usage of bin/greet:
  -name string
    	who to greet (default "world")
  -pause duration
    	wait between greetings
  -shout
    	greet in capitals
  -times int
    	how many greetings (default 1)
0
ana@vm:~/flags$ bin/greet -times=two; echo $?
invalid value "two" for flag -times: parse error
Usage of bin/greet:
  -name string
    	who to greet (default "world")
  -pause duration
    	wait between greetings
  -shout
    	greet in capitals
  -times int
    	how many greetings (default 1)
2
```

**`-h` prints every flag with its type, its help and its default, and exits with status 0**,
because asking for help is not an error. A value that does not fit the flag's type is: `two` is
not an `int`, so `Parse` printed what was wrong, the same usage text below it, and exited with
status 2, the convention for "you called me wrongly". The program's own code never ran.

## Two traps

Both come from the rule that `Parse` stops at the first word that is not a flag, and both fail
quietly:

```
ana@vm:~/flags$ bin/greet bia -times 2
hello, world
left over: [bia -times 2]
ana@vm:~/flags$ bin/greet -shout false
HELLO, WORLD
left over: [false]
```

In the first, `bia` came before the flags, so `Parse` stopped there and `-times 2` became two
leftover words. **Put the flags before everything else**, as the go command itself requires.

In the second, `-shout false` did not turn shouting off. A bool flag takes no separate value,
because `-shout` on its own already means true; so `false` was the first leftover word, and the
greeting came out in capitals. A bool is set to false with `-shout=false`, the equals sign
included.
