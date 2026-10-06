---
title: A slice is a window onto an array
version: 1
---

The usual first description of a slice is "a dynamic array", an array that grows. It is the wrong
picture, and most surprises with slices come from holding it. **A slice holds no elements
at all. It is a small value that points into an array somebody else holds**, and says how much of
that array it shows. Slicing an array with `a[low:high]` makes one:

```go
package main

import "fmt"

func main() {
	a := [5]int{10, 20, 30, 40, 50}
	s := a[1:3]
	fmt.Printf("%v %T len=%d cap=%d\n", s, s, len(s), cap(s))

	s[0] = 99
	fmt.Println(a)

	t := a[2:5]
	t[0] = 77
	fmt.Println(s, t, a)

	fmt.Println(&s[0] == &a[1])
}
```

```
ana@vm:~/arrays-slice$ go run .
[20 30] []int len=2 cap=4
[10 99 30 40 50]
[99 77] [77 40 50] [10 99 77 40 50]
true
```

`a[1:3]` starts at index 1 and stops before index 3, so `s` shows two elements, `20` and `30`.
Its type is `[]int`, with no number between the brackets: **a slice's length is a value it
carries, not part of its type**, which is why one function can take slices of any length.

Then `s[0] = 99` changed `a`. Nothing was copied when `s` was made, so the first element of `s`
*is* the second element of `a`. The last line confirms it: `&s[0] == &a[1]` asks whether the
two have the same address, and they do. `&` is lesson 23's subject; here it only proves that both
names lead to one place in memory.

## Three words

What a slice holds is exactly three things, and the figure draws them for `s`:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"The array a holds five ints, 10, 99, 30, 40 and 50, at indices 0 to 4. The slice s, made by a[1:3], is three words: a pointer to element 1 of a, a length of 2 and a capacity of 4. The length covers elements 1 and 2, which is what s can index; the capacity runs from element 1 to the end of the array. The slice holds no elements of its own.\"><defs><marker id=\"sa-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"135.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the slice s</text><text x=\"227.0\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">s := a[1:3]</text><rect x=\"60\" y=\"40\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"74\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ptr</text><text x=\"190\" y=\"55\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">•</text><rect x=\"60\" y=\"70\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"74\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">len</text><text x=\"190\" y=\"85\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">2</text><rect x=\"60\" y=\"100\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"74\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">cap</text><text x=\"190\" y=\"115\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">4</text><text x=\"135.0\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">three words, and no elements</text><text x=\"236\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the array a</text><text x=\"236\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">index</text><rect x=\"250\" y=\"190\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">10</text><text x=\"290.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><rect x=\"330\" y=\"190\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"370.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">99</text><text x=\"370.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><rect x=\"410\" y=\"190\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"450.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">30</text><text x=\"450.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><rect x=\"490\" y=\"190\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">40</text><text x=\"530.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"570\" y=\"190\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">50</text><text x=\"610.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><path d=\"M196 55 L370.0 55 L370.0 164\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sa-phosphor)\"></path><path d=\"M330 238 L330 244 L490 244 L490 238\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"410\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">len(s) = 2</text><text x=\"410\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">what s[0] and s[1] read</text><path d=\"M330 288 L330 294 L650 294 L650 288\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"490\" y=\"308\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">cap(s) = 4</text><text x=\"490\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">from s&#x27;s start to the end of the array</text></svg>", "caption": "A slice is a pointer into an array, a length and a capacity. Writing s[0] = 99 wrote into a[1], because that is where s points."}
```

- a pointer to the element where the slice starts, here `a[1]`;
- a length, `len(s)`, how many elements it shows, here 2. Reading `s[2]` is out of range,
  even though the array has an element there;
- a capacity, `cap(s)`, how many elements there are from where it starts to the end of the
  array, here 4.

The capacity is the number this lesson only names. What it allows, and what happens when a slice
needs more than it has, are lesson 12's whole subject.

**Two slices of one array share its elements.** `t := a[2:5]` starts one element after `s`
does, so `s[1]` and `t[0]` are both `a[2]`. Writing 77 through `t` changed what `s` prints and
what `a` prints, in the third line of output. Nobody wrote to `s` or to `a` by name.

## A slice literal makes the array for you

Most slices are never sliced from an array you declared. A slice literal, the brackets with nothing
between them, builds an array behind the scenes and returns a slice over all of it:

```go
package main

import "fmt"

func main() {
	s := []int{1, 2, 3}
	fmt.Printf("%v %T len=%d cap=%d\n", s, s, len(s), cap(s))
}
```

```
ana@vm:~/arrays-literal$ go run .
[1 2 3] []int len=3 cap=3
```

The array is still there; it simply has no name, so the slice is the only way to reach it. That is
the ordinary case, and it is easy to forget the array exists until two slices share it.

## Slices do not compare

Arrays compared with `==` in section 01. Slices do not:

```go
package main

import "fmt"

func main() {
	s := []int{1, 2, 3}
	u := []int{1, 2, 3}
	fmt.Println(s == u)
}
```

```
ana@vm:~/arrays-equal$ go run .
# example.com/arrays-equal
./main.go:8:14: invalid operation: s == u (slice can only be compared to nil)
```

Two slices could be equal in two senses that disagree: the same elements, or the same window onto
the same array. Rather than pick one, Go refuses both and leaves the choice to you. The standard
library's `slices.Equal` compares the elements, and `nil`, the one comparison allowed, is lesson
12's.
