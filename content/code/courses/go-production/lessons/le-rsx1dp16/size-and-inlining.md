---
title: Size, and the inliner
version: 1
---

Section 03's values escaped because something could reach them later. **Two other things decide where
a value lives, and neither is about who points at it.** One is size: a stack frame has a size fixed
when the function is compiled, so a value whose size is unknown then, or too large, cannot be in it.
The other is inlining, which changes what "the function" is: once a callee is copied into its caller,
its values belong to the caller's frame and are judged there.

## Too big, or not known

`why/makes.go`:

```go
package why

// Fixed makes a slice whose length is a constant.
func Fixed() int {
	s := make([]int, 64)
	return len(s)
}

// Sized makes a slice whose length arrives at run time.
func Sized(n int) int {
	s := make([]int, n)
	return len(s)
}

// Huge makes a slice of 10,000 ints, 80,000 bytes.
func Huge() int {
	s := make([]int, 10000)
	return len(s)
}

// Grid declares an array of 1 MiB.
func Grid() int {
	var g [1 << 20]byte
	return len(g)
}
```

```
ana@vm:~/escape$ go build -gcflags=-m ./why 2>&1 | grep makes.go
why/makes.go:4:6: can inline Fixed
why/makes.go:10:6: can inline Sized
why/makes.go:16:6: can inline Huge
why/makes.go:22:6: can inline Grid
why/makes.go:5:11: make([]int, 64) does not escape
why/makes.go:11:11: make([]int, n) does not escape
why/makes.go:17:11: make([]int, 10000) escapes to heap
why/makes.go:23:6: moved to heap: g
ana@vm:~/escape$ go build -gcflags=-m=2 ./why 2>&1 | grep "too large"
why/makes.go:17:11:     from make([]int, 10000) (too large for stack) at why/makes.go:17:11
why/makes.go:23:6:     from g (too large for stack) at why/makes.go:23:6
```

`Fixed` makes 64 ints, 512 bytes, and they stay on the stack. `Huge` makes 10,000, 80,000 bytes,
which is over the 64 KiB limit for a value `make` creates, and `Grid` declares 1 MiB, over the
128 KiB limit for a declared variable; `-m=2` gives both the same reason, **`too large for stack`**.
Nothing points at either from outside, and nothing else in the functions differs from `Fixed`.

**`Sized` is the case where "does not escape" does not mean "never allocates".** Its length arrives as
an argument, so the compiler cannot reserve the right amount of frame. What it does instead is
described in a comment in its source, `cmd/compile/internal/walk/builtin.go`: it reserves a fixed
32 bytes in the frame and compiles a check, so that a slice that fits in them uses them and one that
does not is allocated on the heap, at run time. 32 bytes is four `int`s. `make([]int, 4)` costs
nothing and `make([]int, 5)` costs an allocation, from the same line, and section 05 counts both.
The report says `does not escape` for both, because escaping is about lifetime, and the slice does
not outlive `Sized`.

## The inliner changes the answer

`why/inline.go` calls section 02's `New`, whose report said `&Point{...} escapes to heap`:

```go
package why

import "example.com/escape/point"

// Distance builds a Point with point.New and reads it straight back.
func Distance(x, y int) int {
	return point.Sum(point.New(x, y))
}
```

```
ana@vm:~/escape$ go build -gcflags=-m ./why 2>&1 | grep inline.go
why/inline.go:6:6: can inline Distance
why/inline.go:7:28: inlining call to point.New
why/inline.go:7:18: inlining call to point.Sum
why/inline.go:7:28: &point.Point{...} does not escape
```

**The same expression, `&point.Point{...}`, now does not escape.** `New` is small, `can inline New`
said so, and its body was copied into `Distance`. The copy of `&Point{...}` is a value made in
`Distance`, read by `Sum`, inlined too, and never returned: it stays in `Distance`'s frame. Both
reports are right. `New` called from anywhere it is not inlined allocates; inlined, it does not.

Go inlines a function whose cost, an estimate of its size, is under a budget, 80 in this release
(`inlineMaxBudget` in `cmd/compile/internal/inline`), and `-m=2` prints each function's cost:

```
ana@vm:~/escape$ go build -gcflags=-m=2 ./point 2>&1 | grep "can inline New"
point/point.go:8:6: can inline New with cost 7 as: func(int, int) *Point { return &Point{...} }
```

That budget, a profile given to the compiler, or a change in the callee can each move a call from
one side of the line to the other. To see it happen, Ana forbids inlining `New` with a **directive**, a comment with no space
after the slashes, directly above the function:

```
ana@vm:~/escape$ sed -i "s|^func New(|//go:noinline\nfunc New(|" point/point.go
ana@vm:~/escape$ grep -B1 "^func New" point/point.go
//go:noinline
func New(x, y int) *Point {
ana@vm:~/escape$ go build -gcflags=-m ./point ./why 2>&1 | grep "point.go:10\|inline.go"
point/point.go:10:9: &Point{...} escapes to heap
why/inline.go:6:6: can inline Distance
why/inline.go:7:18: inlining call to point.Sum
```

`New`'s own verdict is unchanged, one line lower because of the comment. `Distance` lost two lines:
`inlining call to point.New` and `&point.Point{...} does not escape` are gone, because `Distance` now
calls `New`, and the `Point` is `New`'s, made on the heap and returned. Nothing in `Distance`
changed. Then the directive comes out again:

```
ana@vm:~/escape$ sed -i "/^\/\/go:noinline$/d" point/point.go
```

**`-l` is the same experiment for a whole build**: section 03 used it on `Total`. It is the way to see
what each function decides on its own, and the wrong way to judge a program, because the binary that
ships is built with inlining on. Read the report of the build you ship, and expect it to change when
a callee grows past the budget.
