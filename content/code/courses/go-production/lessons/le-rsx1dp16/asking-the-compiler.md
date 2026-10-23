---
title: Asking the compiler
version: 1
---

**Nothing in Go's syntax says where a value lives.** The belief carried over from C and Java is that
`new` and `&` put a value on the heap and everything else sits on the stack. In Go neither half
holds: `&Point{}` can live on the stack, and a plain `int` can end up on the heap. The compiler decides,
value by value, with a pass called escape analysis. A value may stay in its function's stack frame
only if nothing can reach it after the function returns and its size is known when the code is
compiled. Everything else is allocated on the heap, and the garbage collector of lesson 19 has to find
it and free it later.

The decision is made once, at compile time, and it is visible: **one flag makes the compiler print
it**. Ana works in a new module, `~/escape`, that grows one small package per question:

```
ana@vm:~/escape$ go mod init example.com/escape
go: creating new go.mod: module example.com/escape
go: to add module requirements and sums:
	go mod tidy
```

The first package is a value type and four functions that handle it through pointers. Save it as
`point/point.go`:

```go
// Package point is a small value type and the functions that use it.
package point

// Point is a position on a grid.
type Point struct{ X, Y int }

// New returns a pointer to a new Point.
func New(x, y int) *Point {
	return &Point{X: x, Y: y}
}

// At does the same with a named variable.
func At(x, y int) *Point {
	p := Point{x, y}
	return &p
}

// Sum reads through a pointer and keeps nothing.
func Sum(p *Point) int {
	return p.X + p.Y
}

// Farther returns whichever of a and b is farther from the origin.
func Farther(a, b *Point) *Point {
	if Sum(a) >= Sum(b) {
		return a
	}
	return b
}
```

## `-gcflags=-m`

`-gcflags` hands a list of flags to the compiler, `go tool compile`, for every package it builds, and
the compiler's `-m` is documented as "print optimization decisions". `go build` on a package that is
not `main` compiles it and throws the result away, which makes it the cheap way to ask:

```
ana@vm:~/escape$ go build -gcflags=-m ./point
# example.com/escape/point
point/point.go:8:6: can inline New
point/point.go:13:6: can inline At
point/point.go:19:6: can inline Sum
point/point.go:24:6: can inline Farther
point/point.go:25:8: inlining call to Sum
point/point.go:25:18: inlining call to Sum
point/point.go:9:9: &Point{...} escapes to heap
point/point.go:14:2: moved to heap: p
point/point.go:19:10: p does not escape
point/point.go:24:14: leaking param: a to result ~r0 level=0
point/point.go:24:17: leaking param: b to result ~r0 level=0
```

Every line starts with a file, a line and a column, and **what follows is one of a handful of
sentences**:

| message | what it says | here |
|---|---|---|
| `can inline New` | the function is small enough to be copied into its callers | all four |
| `inlining call to Sum` | it was copied in at this call | the two calls in `Farther` |
| `&Point{...} escapes to heap` | the value this expression makes is allocated on the heap | `New`, line 9 |
| `moved to heap: p` | the same verdict for a named variable | `At`, line 14 |
| `p does not escape` | the function keeps nothing this parameter points at | `Sum` |
| `leaking param: a to result ~r0 level=0` | what `a` points at may come back out as the result | `Farther` |

`New` and `At` are the same function written two ways, and they get the same verdict in two
spellings: **a pointer returned to the caller outlives the frame it was made in**, so the `Point`
cannot be in that frame. `Sum` reads through its pointer and keeps nothing, which is what makes
`Sum(&q)` free for any caller: `q` can stay on the caller's stack.

`Farther` is the subtle one. **"Leaking param" is not an allocation.** It is a summary the compiler
writes for each parameter. It analyses one function at a time, callees first, and a caller
needs to know what a callee does with a pointer it is handed. `to result ~r0` names where `a` goes:
into the first result, which has no name in the source, so the compiler calls it `~r0`. `level=0`
says the pointer itself goes there, not something reached through it. Whether `a`'s `Point` then
escapes is decided in each caller, by what the caller does with what `Farther` returns. A parameter
that leaks to the heap rather than to a result says plain `leaking param: c`, and section 03 meets
one.

## `-m=2`: the reason

Doubling the flag, `-m=2`, adds the path the compiler followed to each verdict. The `grep -v inlin`
drops the inlining lines, which at this level come with a cost figure beside them:

```
ana@vm:~/escape$ go build -gcflags=-m=2 ./point 2>&1 | grep -v inlin
# example.com/escape/point
point/point.go:9:9: &Point{...} escapes to heap in New:
point/point.go:9:9:   flow: ~r0 ← &{storage for &Point{...}}:
point/point.go:9:9:     from &Point{...} (spill) at point/point.go:9:9
point/point.go:9:9:     from return &Point{...} (return) at point/point.go:9:2
point/point.go:9:9: &Point{...} escapes to heap
point/point.go:14:2: p escapes to heap in At:
point/point.go:14:2:   flow: ~r0 ← &p:
point/point.go:14:2:     from &p (address-of) at point/point.go:15:9
point/point.go:14:2:     from return &p (return) at point/point.go:15:2
point/point.go:14:2: moved to heap: p
point/point.go:19:10: p does not escape
point/point.go:24:14: parameter a leaks to ~r0 for Farther with derefs=0:
point/point.go:24:14:   flow: ~r0 ← a:
point/point.go:24:14:     from return a (return) at point/point.go:26:3
point/point.go:24:17: parameter b leaks to ~r0 for Farther with derefs=0:
point/point.go:24:17:   flow: ~r0 ← b:
point/point.go:24:17:     from return b (return) at point/point.go:28:2
point/point.go:24:14: leaking param: a to result ~r0 level=0
point/point.go:24:17: leaking param: b to result ~r0 level=0
```

**Each `flow:` line is one step, written as destination ← source**, and the `from` lines under it
name the code that made the step. For `At`: the result `~r0` receives `&p`, the address of `p`,
because of the `return` on line 15. On a two-line function the reason is obvious; section 06 follows
one through three functions of `hits`, where it is not. `derefs=0` is the same fact as `level=0` in
the short form.

## The decision, drawn

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 412\" role=\"img\" aria-label=\"Escape analysis asks two questions of every value made inside a function. First, can its address still be reached after the function returns: returned as a pointer, kept in a global or a map, captured by a closure that leaves, given to a parameter that leaks. If yes, it goes on the heap. If no, second: is its size known at compile time and under the limit? A declared variable may be up to 128 KiB, new, &amp;T{} or make up to 64 KiB, and make([]T, n) with a size known only at run time gets 32 bytes on the stack, checked when it runs. If yes, the value goes on the stack and is freed when the function returns; if no, it goes on the heap, allocated at run time and later found and freed by the collector.\"><defs><marker id=\"ea-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ea-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"ea-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"320\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a value made inside a function</text><text x=\"180\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p := Point{...}   &amp;T{...}   make(...)   func() {...}</text><rect x=\"20\" y=\"100\" width=\"320\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1. Can its address still be reached</text><text x=\"180\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">after the function returns?</text><rect x=\"20\" y=\"206\" width=\"320\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2. Is its size known at compile time,</text><text x=\"180\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">and under the limit?</text><rect x=\"20\" y=\"312\" width=\"320\" height=\"62\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"330\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">on the stack</text><text x=\"180\" y=\"348\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">freed when the function returns</text><text x=\"180\" y=\"364\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">does not escape</text><rect x=\"420\" y=\"100\" width=\"280\" height=\"274\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">on the heap</text><text x=\"560\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">allocated at run time, then found</text><text x=\"560\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">and freed by the collector</text><text x=\"560\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">escapes to heap   moved to heap: p</text><text x=\"436\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">reached after the return</text><text x=\"436\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">returned as a pointer</text><text x=\"436\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">kept in a global or a map</text><text x=\"436\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">captured by a closure that leaves</text><text x=\"436\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">given to a parameter that leaks</text><text x=\"436\" y=\"292\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">too big, or size unknown</text><text x=\"436\" y=\"310\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a declared variable over 128 KiB</text><text x=\"436\" y=\"326\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">new, &amp;T{} or make over 64 KiB</text><text x=\"436\" y=\"342\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">make([]T, n) over 32 bytes, at run time</text><path d=\"M180 66 V96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ea-phosphor)\"></path><path d=\"M180 156 V202\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ea-phosphor)\"></path><text x=\"192\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">no</text><path d=\"M180 262 V308\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ea-phosphor)\"></path><text x=\"192\" y=\"285\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">yes</text><path d=\"M340 128 H416\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ea-amber)\"></path><text x=\"378\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">yes</text><path d=\"M340 234 H416\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ea-amber)\"></path><text x=\"378\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">no</text><text x=\"20\" y=\"398\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">The compiler asks both questions of every value, once, when it compiles; -gcflags=-m prints each answer.</text></svg>", "caption": "Two questions, asked once per value at compile time. The answers are what -gcflags=-m prints."}
```

The limits in the second question come from the compiler's source, `cmd/compile/internal/ir/cfg.go`
in the Go tree: 128 KiB for a variable declared with `var` or `:=`, 64 KiB for the implicit ones that
`new`, `&T{}` and `make` create. Section 04 runs into both, and into the third line of that list,
which is the one place where the answer is settled at run time.

## Asking about the right packages

**Without a pattern, `-gcflags` applies only to the packages named on the command line.** The runs
above named `./point`, and nothing else was reported. It also means that building a
program, `go build -gcflags=-m .`, reports on package `main` and on none of the packages `main`
imports, which in a real module is where the interesting code is. A pattern in front of the flags
chooses the packages:

| flag | reports on |
|---|---|
| `-gcflags=-m` | the packages named on the command line |
| `-gcflags='example.com/escape/...=-m'` | every package whose path matches, here the whole module |
| `-gcflags=all=-m` | every package in the build, the standard library included |

`go help build` describes the pattern form, and section 06 measures all three on `hits`. Two more
compiler flags travel the same way: `-l` turns inlining off, and section 04 uses it to see what each
function decides on its own.
