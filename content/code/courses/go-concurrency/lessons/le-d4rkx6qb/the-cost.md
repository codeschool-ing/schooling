---
title: What a regular expression costs
version: 1
---

RE2 promises that a match will not explode. It does not promise that a match is free, and two
costs are worth measuring. **Compiling a pattern is much more expensive than running it**, and a
regular expression is often slower than two calls from the `strings` package that answer the same
question. The program below asks one question a hundred thousand times, "does this log line end in
a 5xx status?", three ways, saved as `cost/main.go`:

```go
// Command cost compares compiling a pattern once, compiling it every time,
// and not using a regular expression at all.
package main

import (
	"fmt"
	"regexp"
	"strings"
	"time"
)

const n = 100_000

var lines = []string{"GET /orders/1042 200", "GET /health 200", "POST /orders 500"}

func timed(name string, f func(string) bool) {
	start := time.Now()
	hits := 0
	for i := range n {
		if f(lines[i%len(lines)]) {
			hits++
		}
	}
	fmt.Printf("%-16s %6d hits %v\n", name, hits, time.Since(start).Round(100*time.Microsecond))
}

func main() {
	once := regexp.MustCompile(` 5\d\d$`)
	timed("compiled once", once.MatchString)
	timed("compiled each", func(s string) bool {
		return regexp.MustCompile(` 5\d\d$`).MatchString(s)
	})
	timed("strings only", func(s string) bool {
		return strings.HasPrefix(s[strings.LastIndexByte(s, ' ')+1:], "5")
	})
}
```

The same three lines are cycled through, so every way finds the same 33,333 server errors. Built
once and run twice, because one run of a timing is one sample:

```
ana@vm:~/patterns$ go build -o bin/cost ./cost
ana@vm:~/patterns$ bin/cost
compiled once     33333 hits 4.2ms
compiled each     33333 hits 151.4ms
strings only      33333 hits 400µs
ana@vm:~/patterns$ bin/cost
compiled once     33333 hits 3.9ms
compiled each     33333 hits 136.9ms
strings only      33333 hits 500µs
```

**Compiling inside the loop cost about thirty-five times as much as compiling once**: the pattern was
parsed and turned into a machine a hundred thousand times, to run it once each. That is the mistake
a `MustCompile` in a package-level variable prevents, and it is easy to make by accident in a
function that is called per request. The version with no regular expression at all was eight to ten
times faster again than the compiled one.

## When to reach for one

The numbers are not an argument against regular expressions. Four milliseconds for a hundred
thousand lines is fast, and a pattern says in one line what the `strings` version has to work out
in code. **Use `strings` when the question is simple**, a prefix, a suffix, a fixed piece of text;
use a pattern when the shape is the point, as with the log lines of section 02; and compile it once,
in either case where it is used often.

A one-off timing like this is a rough guide, and it can mislead. Lesson 29 shows how to write a
comparison like this one as a benchmark, which is how a claim about speed is settled.
