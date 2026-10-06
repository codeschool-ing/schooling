---
title: Where a value lives: the stack and the heap
version: 1
---

Programmers who arrive from C bring a rule with them. A local variable lives on the stack and dies
when its function returns, `malloc` puts a value on the heap, and returning the address of a local
is a bug that crashes the program a little later. **In Go you never choose where a value lives. The
compiler chooses, and returning the address of a local is safe because the compiler moves the
local out of the way first.** Lesson 23 returned such a pointer and called it safe; this section
shows the compiler deciding.

The two places are worth naming before the program:

- The **stack** holds the variables of function calls that are still running. Each call gets a
  frame, and the whole frame is given back in one step when the call returns. Nothing has to find
  those values later, so they cost nothing to free.
- The **heap** holds values that may outlive the call that made them. One stays there until the
  garbage collector, section 03, finds that nothing points at it any more.

**The compiler's rule is escape analysis:** if it can prove that a value is not used after its
function returns, the value goes in the frame; if it cannot prove that, the value **escapes** to
the heap. Five small functions in `~/memory`, each doing something different with what it makes:

```schooling-example
{
  "language": "go",
  "file": "funcs.go",
  "parts": [
    {
      "code": "package main\n\ntype point struct{ x, y int }\n",
      "note": "A struct of two `int`s, 16 bytes, from lesson 15."
    },
    {
      "code": "\nfunc sum() int {\n\tnums := [4]int{1, 2, 3, 4}\n\ttotal := 0\n\tfor _, n := range nums {\n\t\ttotal += n\n\t}\n\treturn total\n}\n",
      "note": "**Nothing made here outlives the call.** The array is read and the function returns a copy of one number, so the array lives in `sum`'s frame. The compiler prints no line for it."
    },
    {
      "code": "\nfunc newPoint() *point {\n\tp := point{1, 2}\n\treturn &p\n}\n",
      "note": "The address of `p` leaves in the result, so `p` cannot die with the frame. The compiler says `moved to heap: p`, and the caller's pointer stays good for as long as anybody holds it."
    },
    {
      "code": "\nfunc squares(n int) []int {\n\ts := make([]int, n)\n\tfor i := range s {\n\t\ts[i] = i * i\n\t}\n\treturn s\n}\n",
      "note": "The slice is returned, and with it the array it points into. `make([]int, n) escapes to heap`. The slice itself, a pointer, a length and a capacity, goes back by value like any result."
    },
    {
      "code": "\nfunc count() int {\n\tbuf := make([]int, 0, 8)\n\tbuf = append(buf, 1, 2, 3)\n\treturn len(buf)\n}\n",
      "note": "Same `make`, different fate: only a length leaves this function. `make([]int, 0, 8) does not escape`, and neither does the `append` into it, so the 64-byte array sits in the frame."
    },
    {
      "code": "\nfunc large() int {\n\tvar table [200_000]int\n\ttable[7] = 7\n\treturn table[7]\n}\n",
      "note": "Nothing escapes here either, and the compiler still says `moved to heap: table`. 200,000 `int`s are 1.6 MB, and **a frame has a size limit**: a variable above it goes to the heap whatever escape analysis found."
    }
  ]
}
```

`-gcflags` passes flags to the compiler. The two used here, as the compiler's own help describes
them:

```
ana@vm:~/memory$ go tool compile -help 2>&1 | grep -E "^  -(l|m)\b"
  -l	disable inlining
  -m	print optimization decisions
```

`-m` asks for the compiler's decisions, and `-l` turns inlining off, which keeps each function's
verdict on its own line instead of repeated inside every caller. The `grep` keeps the lines about
`funcs.go`; the rest are about `main.go`, the program that measures, further down:

```
ana@vm:~/memory$ go build -gcflags="-m -l" . 2>&1 | grep funcs.go
./funcs.go:15:2: moved to heap: p
./funcs.go:20:11: make([]int, n) escapes to heap
./funcs.go:28:13: make([]int, 0, 8) does not escape
./funcs.go:29:14: append does not escape
./funcs.go:34:6: moved to heap: table
```

The size limit in the last note is written in the compiler's source, and it is 128 KiB for a
variable you declare:

```
ana@vm:~/memory$ sed -n 8,11p /usr/local/go/src/cmd/compile/internal/ir/cfg.go
	// MaxStackVarSize is the maximum size variable which we will allocate on the stack.
	// This limit is for explicit variable declarations like "var x T" or "x := ...".
	// Note: the flag smallframes can update this value.
	MaxStackVarSize = int64(128 * 1024)
```

## What escaping costs

A value on the heap is an **allocation**: the runtime has to find room for it now, and the collector
has to find it again later. `testing.AllocsPerRun` calls a function many times and reports the
average number of allocations per call. It belongs to the `testing` package, but it is an ordinary
function and `main` can call it:

```go
package main

import (
	"fmt"
	"testing"
)

var (
	keptPoint *point
	keptInts  []int
	n         int
)

func main() {
	fmt.Println("sum      ", testing.AllocsPerRun(100, func() { n = sum() }))
	fmt.Println("newPoint ", testing.AllocsPerRun(100, func() { keptPoint = newPoint() }))
	fmt.Println("squares  ", testing.AllocsPerRun(100, func() { keptInts = squares(100) }))
	fmt.Println("count    ", testing.AllocsPerRun(100, func() { n = count() }))
	fmt.Println("large    ", testing.AllocsPerRun(100, func() { n = large() }))
}
```

```
ana@vm:~/memory$ go run .
sum       0
newPoint  1
squares   1
count     0
large     1
```

The numbers match the compiler's lines one for one: the three functions it named put one value on
the heap per call, and the two it said nothing about, or said `does not escape` about, put none.
The results go into package-level variables so that the compiler cannot decide the calls are
useless and drop them.

**None of this changes what the program means**, only what it costs. `newPoint` is correct either
way, and the same source can be judged differently by the next release of the compiler. Most code
should be written for the reader and measured before anybody rearranges it to avoid an allocation.
The value of `-m` is that the measurement has a reason beside it.

## Lesson 12's first four elements

Lesson 12 section 03 noticed that a slice grown with `append` started at a capacity of 4, and at 1
once the slice was kept in a package-level variable. Its two programs, copied unchanged into
`~/memory-grow` and `~/memory-grow-kept`, give the reason:

```
ana@vm:~/memory-grow$ go build -gcflags="-m -l" . 2>&1 | grep append
./main.go:9:13: append does not escape
ana@vm:~/memory-grow-kept$ go build -gcflags="-m -l" . 2>&1 | grep append
./main.go:11:13: append escapes to heap
ana@vm:~/memory-grow$ grep -n "VariableMakeThreshold = " /usr/local/go/src/cmd/compile/internal/base/flag.go
190:	Debug.VariableMakeThreshold = 32 // 32 byte default for stack allocated make results
```

When the slice never escapes, the compiler gives its first array a 32-byte space in the frame,
which holds four `int`s, and the heap is asked only once the slice outgrows it. When the slice is
kept, nothing of it can be in the frame, and growth starts on the heap at 1.
