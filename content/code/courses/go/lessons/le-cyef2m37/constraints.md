---
title: Constraints are interfaces, read as sets of types
version: 1
---

The part after a type parameter's name looks like special syntax, a list of types with bars between
them. **It is an interface**, the same construct as lesson 27's, and every constraint is one. What it
describes is a set of types: the types `T` may be. The compiler then lets the body do whatever every
type in the set can do, and nothing else.

`any`, lesson 28's interface with no methods, is the widest set there is, so it allows the least. A
value of type `T any` can be stored, passed, returned and put in a slice, and very little else.
Even `==` is refused, because some types cannot be compared. An `Index` that searches a slice, in
`~/generic2-index`:

```go
package main

import "fmt"

func Index[T any](xs []T, v T) int {
	for i, x := range xs {
		if x == v {
			return i
		}
	}
	return -1
}

func main() {
	fmt.Println(Index([]string{"ana", "bia", "caio"}, "bia"))
}
```

```
ana@vm:~/generic2-index$ go run .
# example.com/generic2-index
./main.go:7:6: invalid operation: x == v (incomparable types in type set)
```

`incomparable types in type set` means that somewhere in the set `any` describes there is a type
`==` does not work on, a slice or a map for instance, and the body has to be valid for all of them.
The error is on line 7, inside `Index`, and not at the call: **a generic body is checked once,
against the whole constraint, before anybody calls it.** With `any` changed to `comparable`, the same
program runs:

```
ana@vm:~/generic2-index$ go run .
1
```

`comparable` is predeclared, like `any`, and `go doc` lists what it holds:

```
ana@vm:~/generic2-index$ go doc builtin.comparable
package builtin // import "builtin"

type comparable interface{ comparable }
    comparable is an interface that is implemented by all comparable types
    (booleans, numbers, strings, pointers, channels, arrays of comparable types,
    structs whose fields are all comparable types). The comparable interface may
    only be used as a type parameter constraint, not as the type of a variable.

```

It is the same set of types a map accepts as keys, which lesson 14 showed the compiler enforcing.
That is why `maps.Keys` declares its key type as `K comparable`.

## A union, and the `~` it usually needs

`int | float64` is a **union**: the set holding exactly those two types. Lesson 30 used it for `Sum`,
and it has a gap that a program with types of its own finds at once. Lesson 10's `Celsius` is a
`float64` underneath, so summing a week of readings looks like it should work. In
`~/generic2-celsius`:

```go
package main

import "fmt"

type Celsius float64

func Sum[T int | float64](xs []T) T {
	var total T
	for _, x := range xs {
		total += x
	}
	return total
}

func main() {
	week := []Celsius{20.5, 22, 19.5}
	fmt.Println(Sum(week))
}
```

```
ana@vm:~/generic2-celsius$ go run .
# example.com/generic2-celsius
./main.go:17:17: Celsius does not satisfy int | float64 (possibly missing ~ for float64 in int | float64)
```

Lesson 10 said `Celsius` is a new type with `float64` as its **underlying type**, not another name for
`float64`, and the union holds `float64` itself and nothing else. The compiler noticed what was
probably meant and said so: `possibly missing ~ for float64`. **`~float64` is the set of every type
whose underlying type is `float64`**, `float64` included. With the tilde on both members, and the
constraint given a name so it can be reused, in `~/generic2-number`:

```go
package main

import (
	"fmt"
	"slices"
)

type Number interface {
	~int | ~float64
}

func Sum[T Number](xs []T) T {
	var total T
	for _, x := range xs {
		total += x
	}
	return total
}

type Celsius float64

func main() {
	week := []Celsius{20.5, 22, 19.5}
	total := Sum(week)
	fmt.Printf("%v %T\n", total, total)
	fmt.Println(Sum([]int{3, 4, 5}))

	slices.Sort(week)
	fmt.Println(week, slices.Max(week))
}
```

```
ana@vm:~/generic2-number$ go run .
62 main.Celsius
12
[19.5 20.5 22] 22
```

The week's total came back as a `main.Celsius`, so the unit lesson 10 attached to it survived the
trip through a generic function. The last line shows the standard library's `slices.Sort` and
`slices.Max` taking the same slice, and the end of this section says why they can. A constraint
declared like `Number` is an ordinary interface declaration whose body is a union instead of a list
of methods.

The three constraints in this lesson nest inside one another, and seen as sets they look like this:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Three nested type sets. The innermost, int | float64, holds exactly two types, int and float64. Around it, ~int | ~float64 holds those two and every type whose underlying type is int or float64, such as Celsius. Around that, cmp.Ordered holds every ordered type, defined ones included, such as string, int64 and time.Duration. Outside all three are types like bool and []int.\"><rect x=\"20\" y=\"16\" width=\"680\" height=\"254\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">cmp.Ordered</text><text x=\"40\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every ordered type, defined ones included</text><rect x=\"44\" y=\"74\" width=\"450\" height=\"180\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"62\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">~int | ~float64</text><text x=\"62\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and every type whose underlying type is int or float64</text><rect x=\"66\" y=\"132\" width=\"210\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"84\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">int | float64</text><text x=\"84\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">exactly these two types</text><rect x=\"94.2\" y=\"196\" width=\"35.6\" height=\"24\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"112\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">int</text><rect x=\"163.8\" y=\"196\" width=\"64.4\" height=\"24\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"196\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">float64</text><rect x=\"357.8\" y=\"178\" width=\"64.4\" height=\"24\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Celsius</text><rect x=\"571.4\" y=\"108\" width=\"57.2\" height=\"24\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">string</text><rect x=\"575.0\" y=\"158\" width=\"50.0\" height=\"24\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">int64</text><rect x=\"546.2\" y=\"208\" width=\"107.60000000000001\" height=\"24\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">time.Duration</text><text x=\"40\" y=\"302\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in none of the three</text><rect x=\"188.6\" y=\"290\" width=\"42.8\" height=\"24\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">bool</text><rect x=\"255.0\" y=\"290\" width=\"50.0\" height=\"24\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[]int</text></svg>", "caption": "Three constraints as the sets of types they allow. A plain union admits exactly its members; a ~ admits every type built on them, which is where Celsius lands; cmp.Ordered is wider again."}
```

**An interface holding a union is a constraint and nothing else.** Used as the type of a variable, in
`~/generic2-astype`, it is refused:

```go
package main

import "fmt"

type Number interface {
	~int | ~float64
}

func main() {
	var n Number = 3
	fmt.Println(n)
}
```

```
ana@vm:~/generic2-astype$ go run .
# example.com/generic2-astype
./main.go:10:8: cannot use type Number outside a type constraint: interface contains type constraints
```

An interface made only of methods, like the `fmt.Stringer` of lesson 30, works both ways: as a
constraint in `ShowAll` and as an ordinary parameter type in `ShowEach`.

## `cmp.Ordered`, and the signatures of the standard library

You rarely need to write `Number` yourself for comparisons, because the `cmp` package has the
constraint lesson 30 saw on `slices.Sort`:

```
ana@vm:~/generic2-number$ go doc cmp.Ordered | head -7
package cmp // import "cmp"

type Ordered interface {
	~int | ~int8 | ~int16 | ~int32 | ~int64 |
		~uint | ~uint8 | ~uint16 | ~uint32 | ~uint64 | ~uintptr |
		~float32 | ~float64 |
		~string
```

Every member carries a `~`. That is why `slices.Sort` and `slices.Max` accepted the week of
`Celsius` readings in `~/generic2-number` with no conversion, and gave back `[19.5 20.5 22] 22`.
**A constraint in a library is written with `~` on purpose, because the caller's types are usually
types of their own.**

That leaves one piece of the signatures lessons 14, 21 and 24 met and left unexplained, the shape
`S ~[]E`:

```
ana@vm:~/generic2-clone$ go doc slices.Clone | head -3
package slices // import "slices"

func Clone[S ~[]E, E any](s S) S
```

Read it left to right. `E any` is the element type, anything at all. `S ~[]E` is a type whose
underlying type is a slice of `E`, which includes `[]E` itself and every type defined on it. The
parameter is an `S` and so is the result. The reason for the second type parameter shows up beside a
simpler version that takes `[]E` directly, in `~/generic2-clone`:

```go
package main

import (
	"fmt"
	"slices"
)

type Names []string

func CloneFlat[E any](s []E) []E {
	return append([]E(nil), s...)
}

func main() {
	team := Names{"ana", "bia"}
	a := slices.Clone(team)
	b := CloneFlat(team)
	fmt.Printf("%T %T\n", a, b)
}
```

```
ana@vm:~/generic2-clone$ go run .
main.Names []string
```

Both copies hold the same two names. `slices.Clone` gave back a `Names`, so any method `Names` has
(lesson 25) is still there; `CloneFlat` gave back a plain `[]string`, and the caller's type was lost
on the way through. That is all `S ~[]E` is for, and it is why almost every function in `slices`
declares it.
