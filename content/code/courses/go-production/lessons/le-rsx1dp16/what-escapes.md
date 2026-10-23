---
title: What makes a value escape
version: 1
---

Section 02 met the first reason in `At`: **an address handed back to the caller**. Every other reason
is the same rule in a different form, and none of them is spelled `&` in the source. An interface
holds a pointer to its contents, a closure holds pointers to the variables it uses, a map holds its
keys, and a method value holds its receiver. When the thing doing the holding outlives the call, so
does what it points at.

Each case below is one small file in a second package, `why`, and each is asked about on its own by
filtering the compiler's report with `grep` for that file's name. The whole package is built every
time, so a file's lines do not depend on which other files are there.

## A value in an interface

`why/iface.go`:

```go
package why

import "fmt"

// Show prints n.
func Show(n int) {
	fmt.Println(n)
}

// Box returns n inside an interface.
func Box(n int) any {
	return n
}
```

```
ana@vm:~/escape$ go build -gcflags=-m ./why 2>&1 | grep iface.go
why/iface.go:6:6: can inline Show
why/iface.go:11:6: can inline Box
why/iface.go:7:13: inlining call to fmt.Println
why/iface.go:7:13: ... argument does not escape
why/iface.go:7:14: n escapes to heap
why/iface.go:12:9: n escapes to heap
```

**`n escapes to heap` on a plain `int`, twice.** An interface value is two words, a type and a
pointer to the data, so an `int` put into `any` needs somewhere to be pointed at. In `Box` the
interface is returned, so that somewhere must outlive the call. In `Show` nothing is returned, and the
reason is one level down:

```
ana@vm:~/escape$ go build -gcflags=-m=2 ./why 2>&1 | grep -A9 "iface.go:7:14: n escapes to heap in"
why/iface.go:7:14: n escapes to heap in Show:
why/iface.go:7:14:   flow: {storage for ... argument} ← &{storage for n}:
why/iface.go:7:14:     from n (spill) at why/iface.go:7:14
why/iface.go:7:14:     from ... argument (slice-literal-element) at why/iface.go:7:13
why/iface.go:7:14:   flow: fmt.a ← &{storage for ... argument}:
why/iface.go:7:14:     from ... argument (spill) at why/iface.go:7:13
why/iface.go:7:14:     from fmt.a := ... argument (assign-pair) at why/iface.go:7:13
why/iface.go:7:14:   flow: {heap} ← *fmt.a:
why/iface.go:7:14:     from fmt.Fprintln(os.Stdout, fmt.a...) (call parameter) at why/iface.go:7:13
why/iface.go:7:13: ... argument does not escape
```

Read from the top: `n` is stored in the slice that holds `Println`'s arguments, the slice becomes
`fmt.a`, and `fmt.Fprintln(os.Stdout, fmt.a...)` is a call whose parameter leaks to the heap.
**`Println` was inlined, `Fprintln` was not**, and the summary the compiler wrote when it compiled
package `fmt` says that `Fprintln`'s arguments leak. The report stops there: a summary from another
package is used as it is, and its own reasons are in that package's report. The last line is the
other half of the story: `... argument does not escape`. The slice of arguments itself stays on the
stack; only the values put into it move. Every `fmt.Println(x)` of a non-pointer value in a hot loop
is this case, and section 05 shows that the runtime sometimes gets away without the allocation the
compiler predicted.

## A closure

`why/closure.go`:

```go
package why

// Counter returns a function that counts its own calls.
func Counter() func() int {
	n := 0
	return func() int {
		n++
		return n
	}
}

// Each calls f on every element of xs.
func Each(xs []int, f func(int)) {
	for _, x := range xs {
		f(x)
	}
}

// Total adds up xs with a closure that never leaves the call.
func Total(xs []int) int {
	t := 0
	Each(xs, func(x int) { t += x })
	return t
}
```

```
ana@vm:~/escape$ go build -gcflags=-m ./why 2>&1 | grep closure.go
why/closure.go:4:6: can inline Counter
why/closure.go:6:9: can inline Counter.func1
why/closure.go:13:6: can inline Each
why/closure.go:20:6: can inline Total
why/closure.go:22:11: can inline Total.func1
why/closure.go:22:6: inlining call to Each
why/closure.go:22:6: inlining call to Total.func1
why/closure.go:5:2: moved to heap: n
why/closure.go:6:9: func literal escapes to heap
why/closure.go:13:11: xs does not escape
why/closure.go:13:21: f does not escape
why/closure.go:20:12: xs does not escape
```

`Counter`'s closure increments `n` after `Counter` has returned, so `n` cannot live in `Counter`'s
frame: **`moved to heap: n`**, and the function value that refers to it, returned too, is a `func
literal` that escapes. `Total` builds a closure as well and gets no verdict at all, because `Each` and
the closure were both inlined into it and there is no closure left. Turning inlining off with `-l`
shows what `Total` decides on its own:

```
ana@vm:~/escape$ go build -gcflags='-m -l' ./why 2>&1 | grep closure.go:22
why/closure.go:22:11: func literal does not escape
```

The closure stays on `Total`'s stack even when it is a real closure passed to a real call, and the
reason is the line `f does not escape` above it, written for `Each`. **A callee's summary of its
parameters is what lets a caller keep its values**: `Each` calls `f` and keeps nothing, so `Total`'s
closure, and the `t` it modifies, can be in `Total`'s frame.

## A map key

`why/words.go`:

```go
package why

// Add counts the word in b.
func Add(m map[string]int, b []byte) {
	m[string(b)]++
}

// Get reads the count for the word in b.
func Get(m map[string]int, b []byte) int {
	return m[string(b)]
}
```

```
ana@vm:~/escape$ go build -gcflags=-m ./why 2>&1 | grep words.go
why/words.go:4:6: can inline Add
why/words.go:9:6: can inline Get
why/words.go:4:10: m does not escape
why/words.go:4:28: b does not escape
why/words.go:5:11: string(b) escapes to heap
why/words.go:9:10: m does not escape
why/words.go:9:28: b does not escape
why/words.go:10:18: string(b) does not escape
```

The same conversion, `string(b)`, gets opposite verdicts. **A map stores the keys it is given**, and
the map lives on the heap, so the string `Add` builds must be there too. `Get` only looks the key up,
and nothing keeps the string once the lookup is done. Section 06 finds this exact line inside `hits`.

## Appending to a slice that was passed in

`why/push.go`:

```go
package why

// Push appends v to s and returns the result.
func Push(s []int, v int) []int {
	return append(s, v)
}
```

```
ana@vm:~/escape$ go build -gcflags=-m ./why 2>&1 | grep push.go
why/push.go:4:6: can inline Push
why/push.go:4:11: leaking param: s to result ~r0 level=0
why/push.go:5:15: append escapes to heap
```

Two lines about one statement. **`leaking param: s to result`** says the array behind `s` may come
back out in the result, which is what `append` does when there is room; whether that array escapes is
up to each caller. **`append escapes to heap`** is about the other case: when there is no room,
`append` allocates a new array, and since it is returned, it is allocated on the heap.

## A method value

`why/method.go`:

```go
package why

// Clock counts ticks.
type Clock struct{ ticks int }

// Tick moves the clock on by one.
func (c *Clock) Tick() { c.ticks++ }

// TickTwice uses a method value inside the function.
func TickTwice(c *Clock) {
	f := c.Tick
	f()
	f()
}

// Ticker hands a method value to the caller.
func Ticker(c *Clock) func() {
	return c.Tick
}
```

```
ana@vm:~/escape$ go build -gcflags=-m ./why 2>&1 | grep method.go
why/method.go:7:6: can inline (*Clock).Tick
why/method.go:17:6: can inline Ticker
why/method.go:7:7: c does not escape
why/method.go:10:16: c does not escape
why/method.go:11:8: c.Tick does not escape
why/method.go:17:13: leaking param: c
why/method.go:18:10: c.Tick escapes to heap
```

`c.Tick` without the call is a method value: a function with `c` bound into it, which is a closure
by another name. **Used inside `TickTwice`, it stays on the stack** (`c.Tick does not escape`), and so
`c` does not escape either. Returned from `Ticker`, it escapes, and it takes its receiver with it:
`leaking param: c`, with no "to result", is the form of the summary that means the heap itself. A
caller that writes `Ticker(&clk)` will find `moved to heap: clk` in its own report.
