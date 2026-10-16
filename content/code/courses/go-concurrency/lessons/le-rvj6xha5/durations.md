---
title: A duration is a number of nanoseconds
version: 1
---

`time.Sleep(time.Second)` has appeared in this course since lesson 1, and it reads like a unit
attached to a number. **A `time.Duration` is an `int64` counting nanoseconds, with a type of its
own**, and almost everything this section shows follows from that one sentence: how a duration
prints, why it multiplies the way it does, and how long a span it can hold.

The first program takes a duration apart, saved as `dur.go`:

```go
// Command dur shows what a time.Duration is and how it prints.
package main

import (
	"fmt"
	"time"
)

func main() {
	d := 90 * time.Minute
	fmt.Println(d, int64(d))
	fmt.Println(d.Hours(), d.Minutes())

	p, err := time.ParseDuration("1h15m30.5s")
	fmt.Println(p, err)
	_, err = time.ParseDuration("3 days")
	fmt.Println(err)

	n := 4
	fmt.Println(time.Duration(n) * time.Second)
	fmt.Println(d.Round(time.Hour), d.Truncate(time.Hour))
}
```

```
ana@vm:~/clock$ go run dur.go
1h30m0s 5400000000000
1.5 90
1h15m30.5s <nil>
time: unknown unit " days" in duration "3 days"
4s
2h0m0s 1h0m0s
```

Ninety minutes printed as `1h30m0s`, because `Duration` has a `String` method, and as
5,400,000,000,000 once converted to a plain `int64`: that many nanoseconds. `Hours` and `Minutes`
return a `float64`, so `1.5` and `90`. **`ParseDuration` reads the same notation `String` writes**,
which makes it the natural format for a duration in a flag or a configuration file, as lesson 21
does. Its units stop at the hour. `3 days` is refused, because a day is not always 24 hours where
clocks change, and the package leaves that judgement to you. `Round` and `Truncate` move to a
multiple of the unit, which is how every timing in this course was printed.

An `int64` of nanoseconds holds about 292 years, which no program measuring an interval reaches.

## The type is the point

The fifth line converted `n` before multiplying, and it had to. Without the conversion, in a
directory of its own as `main.go`:

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	n := 4
	fmt.Println(n * time.Second)
}
```

```
ana@vm:~/clock/mismatch$ go build .
# example.com/clock/mismatch
./main.go:10:14: invalid operation: n * time.Second (mismatched types int and time.Duration)
```

`4 * time.Second` compiles, because an untyped constant takes whatever type it is used with, as
lesson 10 of `go` showed. A variable has a type already, and Go converts nothing on your behalf.
**The refusal is what makes `Duration` worth having.** A function taking a `time.Duration` cannot be
handed a bare `4` by accident, and nobody has to wonder whether it meant seconds or milliseconds.

## Two clocks inside one reading

A computer's wall clock can jump: a person corrects it, or the network time service pulls it
forward or back. An interval measured with it can come out wrong, or even negative. **So
`time.Now` takes two readings, the wall clock and a monotonic clock that only moves forwards**, and
the second rides along in the value. Saved as `mono.go`:

```go
// Command mono measures an interval with the clock that cannot go backwards.
package main

import (
	"fmt"
	"strings"
	"time"
)

func main() {
	start := time.Now()
	s := start.String()
	fmt.Println("reading carries:", s[strings.Index(s, "m="):])
	time.Sleep(250 * time.Millisecond)
	fmt.Println("elapsed:", time.Since(start).Round(time.Millisecond))
	fmt.Println("stripped:", strings.Contains(start.Round(0).String(), "m="))
}
```

```
ana@vm:~/clock$ go run mono.go
reading carries: m=+0.000103412
elapsed: 251ms
stripped: false
```

The `m=+0.000103412` at the end of a printed `time.Time` is the monotonic reading, in seconds since
the process started. `time.Since` and `Sub` use it whenever both values carry one, so the 251
milliseconds above would have been right even if somebody had moved the wall clock during the
sleep. `Round(0)` throws it away, which is what a value written to a file or compared with one from
another machine should do anyway: the monotonic reading means nothing outside the process that took
it.
