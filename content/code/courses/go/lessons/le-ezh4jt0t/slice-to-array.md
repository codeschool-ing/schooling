---
title: From a slice to an array
version: 1
---

The other direction has a wrong idea attached to it that used to be true: that a slice cannot be
turned into an array at all, only copied into one by hand. Two
conversions exist, and they behave differently in the one way that matters. **`[4]int(s)` copies
the first four elements into a new array; `(*[4]int)(s)` copies nothing and points at the four the
slice already has.**

```go
package main

import "fmt"

func main() {
	s := []int{1, 2, 3, 4, 5, 6}

	c := [4]int(s)
	c[0] = 100
	fmt.Println(s, c)

	p := (*[4]int)(s)
	p[0] = 100
	fmt.Println(s, *p)
}
```

```
ana@vm:~/slicearray-conv$ go run .
[1 2 3 4 5 6] [100 2 3 4]
[100 2 3 4 5 6] [100 2 3 4]
```

`s` has six elements and both conversions asked for four, which is allowed: they take the first
four and ignore the rest. After `c[0] = 100`, `s` still starts with 1, because `c` is an array of
its own, and an array is a value. After `p[0] = 100`, `s` starts with 100, because `p` is a pointer
to the first four elements of the array `s` views. `*p` is the array it points at, and `p[0]` is
shorthand for `(*p)[0]`; pointers are lesson 23's subject.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The slice s views an array holding 1 to 6. p := (*[4]int)(s) is a pointer to the first four elements of that same array, so writing through p changes s. c := [4]int(s) is a new array holding a copy of 1, 2, 3 and 4, so writing to c leaves s alone.\"><defs><marker id=\"sac-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"sac-phosphor-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><text x=\"260\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">s := []int{1, 2, 3, 4, 5, 6}</text><path d=\"M262 52 L262 46\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M262 46 L458 46\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M458 46 L458 52\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">*p</text><rect x=\"260\" y=\"58\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"310\" y=\"58\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"360\" y=\"58\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><rect x=\"410\" y=\"58\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><rect x=\"460\" y=\"58\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"485.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><rect x=\"510\" y=\"58\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6</text><text x=\"572\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the array behind s</text><text x=\"30\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">p := (*[4]int)(s)</text><rect x=\"60\" y=\"58\" width=\"70\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">p</text><path d=\"M130 73 L256 73\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sac-phosphor)\"></path><text x=\"30\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the same array:</text><text x=\"30\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">writing through p changes s</text><path d=\"M285 92 L285 162\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sac-phosphor-dim)\"></path><path d=\"M335 92 L335 162\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sac-phosphor-dim)\"></path><path d=\"M385 92 L385 162\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sac-phosphor-dim)\"></path><path d=\"M435 92 L435 162\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sac-phosphor-dim)\"></path><text x=\"472\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">copied</text><rect x=\"260\" y=\"168\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"310\" y=\"168\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"360\" y=\"168\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><rect x=\"410\" y=\"168\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><text x=\"30\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">c := [4]int(s)</text><text x=\"472\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a new array of its own:</text><text x=\"472\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">writing to c leaves s alone</text></svg>", "caption": "Two conversions of one slice. The pointer conversion shares the slice's array; the array conversion copies out of it."}
```

So the choice is the one lesson 12 kept asking: who else sees this memory? Take the array
conversion when you want a value nobody else can change. Take the pointer only when you mean to
work on the slice's own elements through a fixed-size type.

## Older Go refused both

The two conversions arrived at different times, and the `go` line in `go.mod` decides which ones a
module may use, as lesson 2 showed. Moving that line back is the quickest way to see when:

```
ana@vm:~/slicearray-conv$ go mod edit -go=1.19 && go build
# example.com/conv
./main.go:8:14: cannot convert s (variable of type []int) to type [4]int: conversion of slice to array requires go1.20 or later (-lang was set to go1.19; check go.mod)
ana@vm:~/slicearray-conv$ go mod edit -go=1.16 && go build
# example.com/conv
./main.go:8:14: cannot convert s (variable of type []int) to type [4]int: conversion of slice to array requires go1.20 or later (-lang was set to go1.16; check go.mod)
./main.go:12:17: cannot convert s (variable of type []int) to type *[4]int: conversion of slice to array pointer requires go1.17 or later (-lang was set to go1.16; check go.mod)
ana@vm:~/slicearray-conv$ go mod edit -go=1.27.1 && go build && echo built
built
```

The pointer conversion needs Go 1.17 and the array conversion Go 1.20. Code older than that copies
by hand or with `copy`, and you will still read plenty of it; nothing about the new form makes the
old one wrong.

## Too short is a panic

Asking for more elements than the slice has cannot be checked by the compiler, for the same reason
lesson 12's `mid[3]` could not: a slice's length is only known when the program runs.

```go
package main

import "fmt"

func main() {
	s := []int{1, 2}
	fmt.Println([4]int(s))
}
```

```
ana@vm:~/slicearray-short$ go run .
panic: runtime error: cannot convert slice with length 2 to array or pointer to array with length 4

goroutine 1 [running]:
main.main()
	/home/ana/slicearray-short/main.go:7 +0x9
exit status 2
```

The message names both lengths and covers both conversions. **Longer is fine and shorter panics**,
so a conversion of data you did not produce yourself belongs after a check of `len`.

## Where it is used

The conversion earns its place where an API asks for an array because the size is part of the
meaning. An IPv4 address is exactly four bytes, and `net/netip` says so in its types:

```
ana@vm:~/slicearray-ip$ go doc net/netip.AddrFrom4
package netip // import "net/netip"

func AddrFrom4(addr [4]byte) Addr
    AddrFrom4 returns the address of the IPv4 address given by the bytes in
    addr.

```

Bytes that arrive from a file or a network come as a slice. Here six of them, of which the first
four are an address:

```go
package main

import (
	"fmt"
	"net/netip"
)

func main() {
	raw := []byte{192, 168, 0, 10, 0, 80}
	addr := netip.AddrFrom4([4]byte(raw))
	fmt.Println(addr)
}
```

```
ana@vm:~/slicearray-ip$ go run .
192.168.0.10
```

`[4]byte(raw)` took the first four bytes and left the two after them alone. `addr` now holds its
own copy of those four, whatever later happens to `raw`.

It is tempting to write `[4]byte(raw[:4])` instead, because it says "four" twice and looks more
careful. **It is less careful: `raw[:4]` is measured against the capacity, so it can reach past the
length and hand the conversion bytes that are not part of the slice.** A buffer reused from one
record to the next is exactly that situation:

```go
package main

import "fmt"

func main() {
	buf := []byte{192, 168, 0, 10, 0, 80}
	short := buf[:3]

	fmt.Println([4]byte(short[:4]))
	fmt.Println([4]byte(short))
}
```

```
ana@vm:~/slicearray-stale$ go run .
[192 168 0 10]
panic: runtime error: cannot convert slice with length 3 to array or pointer to array with length 4

goroutine 1 [running]:
main.main()
	/home/ana/slicearray-stale/main.go:10 +0x8a
exit status 2
```

`short` holds three bytes. The first line still printed four, because `short[:4]` reached into the
capacity and picked up the `10` that was left in the buffer, and nothing complained. The second
line converted `short` itself, and the conversion checked its length and refused. Convert the slice
you have, and let the conversion do the checking it was designed to do.
