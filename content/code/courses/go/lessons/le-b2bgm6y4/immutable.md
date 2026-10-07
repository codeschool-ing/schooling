---
title: A string never changes
version: 1
---

In C a string is an array of characters, and a program changes one by writing into it. Go's
strings do not work that way, and the compiler says so:

```go
package main

import "fmt"

func main() {
	s := "hello"
	s[0] = 'H'
	fmt.Println(s)
}
```

```
ana@vm:~/strings-mut$ go run .
# example.com/mut
./main.go:7:2: cannot assign to s[0] (neither addressable nor a map index expression)
```

**A string's bytes are fixed when the string is made, and nothing can change them afterwards.**
`s[0]` can be read, which section 04 does, and never written. A variable holding a string can be
given a different string, and that is what "changing" a string means in Go: building a new one and
assigning it.

## What a string variable holds

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"unsafe\"\n)\n\nfunc main() {\n",
      "note": "`unsafe` is the package that lets a program look at what the language normally keeps out of sight. It is used here to look and nothing else."
    },
    {
      "code": "\ts := \"hello, world\"\n\tt := s\n\ts = \"H\" + s[1:]\n\tfmt.Println(s)\n\tfmt.Println(t)\n",
      "note": "`t := s` copies the string, and `s = \"H\" + s[1:]` builds a new one and assigns it to `s`. `t` still reads `hello, world`: **nothing touched the bytes it refers to.**"
    },
    {
      "code": "\n\tfmt.Println(unsafe.Sizeof(t), unsafe.Sizeof(\"a\"), len(t))\n",
      "note": "**A string value is 16 bytes, whatever the length of the text**: `unsafe.Sizeof` gives 16 for the 12-byte `t` and for `\"a\"`. Those 16 bytes are a pointer to the first byte and a length, 8 bytes each on this machine."
    },
    {
      "code": "\n\tw := t[7:]\n\tfmt.Println(unsafe.StringData(t), unsafe.StringData(w), w)\n",
      "note": "`unsafe.StringData` gives the address of a string's first byte. The substring `w` starts at `0x49bfcc`, seven bytes after `t`'s `0x49bfc5`: it points into the same bytes and copied none."
    },
    {
      "code": "\n\tu := t[:5] + \"!\"\n\tfmt.Println(unsafe.StringData(u) == unsafe.StringData(t), u)\n}\n",
      "note": "`+` cannot reuse anything. `u` is new bytes, so its first byte is not `t`'s, and `false` says so."
    }
  ],
  "output": "Hello, world\nhello, world\n16 16 12\n0x49bfc5 0x49bfcc world\nfalse hello!"
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Three string values on the left, each a pointer and a length. t points at the first of the twelve bytes of hello, world, with length 12. w, which is t[7:], points seven bytes further on, at the w of world, with length 5, and no byte is copied. u, which is t[:5] plus an exclamation mark, points at six new bytes, hello!, copied by the + operator.\"><defs><marker id=\"sh-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sh-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a string value: a pointer and a length, 16 bytes</text><text x=\"480\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the bytes of the literal, which nothing writes</text><rect x=\"300\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">h</text><text x=\"315.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">0</text><rect x=\"330\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">e</text><text x=\"345.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">1</text><rect x=\"360\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">l</text><text x=\"375.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">2</text><rect x=\"390\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">l</text><text x=\"405.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">3</text><rect x=\"420\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">o</text><text x=\"435.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">4</text><rect x=\"450\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">,</text><text x=\"465.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">5</text><rect x=\"480\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"495.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">6</text><rect x=\"510\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">w</text><text x=\"525.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">7</text><rect x=\"540\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">o</text><text x=\"555.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">8</text><rect x=\"570\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">r</text><text x=\"585.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">9</text><rect x=\"600\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">l</text><text x=\"615.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">10</text><rect x=\"630\" y=\"60\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">d</text><text x=\"645.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">11</text><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">t</text><rect x=\"20\" y=\"60\" width=\"120\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"140\" y=\"60\" width=\"80\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0x49bfc5</text><text x=\"180\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">len 12</text><path d=\"M222 78 L297 78\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sh-phosphor)\"></path><text x=\"20\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">w := t[7:]</text><rect x=\"20\" y=\"130\" width=\"120\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"140\" y=\"130\" width=\"80\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0x49bfcc</text><text x=\"180\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">len 5</text><path d=\"M222 148 L525.0 148 L525.0 99\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sh-phosphor)\"></path><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">u := t[:5] + &quot;!&quot;</text><rect x=\"20\" y=\"210\" width=\"120\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"140\" y=\"210\" width=\"80\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ptr</text><text x=\"180\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">len 6</text><text x=\"390\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">new bytes, copied by +</text><rect x=\"300\" y=\"210\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"315.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">h</text><rect x=\"330\" y=\"210\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">e</text><rect x=\"360\" y=\"210\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">l</text><rect x=\"390\" y=\"210\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"405.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">l</text><rect x=\"420\" y=\"210\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">o</text><rect x=\"450\" y=\"210\" width=\"30\" height=\"36\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">!</text><path d=\"M222 228 L297 228\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sh-amber)\"></path></svg>", "caption": "What the program in ~/strings-share built. A substring is a new pointer and length over the same bytes; + makes new bytes."}
```

The arrangement is safe because of the rule above. If the bytes of `t` could change, `w` would
change with them behind its owner's back; since they cannot, a substring costs a new header and no
copying at all. There is one cost, and it is the reverse case: a short substring keeps the whole of
the bytes it points into alive in memory. `go doc strings.Clone` describes the fix, a function that
makes a fresh copy "when retaining only a small substring of a much larger string", and lesson 24
is about what memory a program keeps.

## `+` copies, and in a loop that adds up

`+` cannot extend a string in place, so it allocates new bytes and copies both sides into them.
Once, that is nothing. Building a long string with `+=` in a loop copies everything built so far on
every turn. The two programs below each build the same 200,000-byte string from 100,000 pieces;
`for range 100000` repeats its block 100,000 times, and lesson 17 is about loops.

```go
package main

import "fmt"

func main() {
	s := ""
	for range 100000 {
		s += "ab"
	}
	fmt.Println(len(s))
}
```

```go
package main

import (
	"fmt"
	"strings"
)

func main() {
	var b strings.Builder
	for range 100000 {
		b.WriteString("ab")
	}
	s := b.String()
	fmt.Println(len(s))
}
```

```
ana@vm:~/strings-plus$ go build && time ./plus
200000

real	0m3.701s
user	0m2.318s
sys	0m3.136s
```

```
ana@vm:~/strings-builder$ go build && time ./builder
200000

real	0m0.003s
user	0m0.003s
sys	0m0.000s
```

Same output, 3.7 seconds against 3 milliseconds. The `+=` version copied 2 bytes, then 4, then 6,
all the way to 200,000, which adds up to about 10 billion bytes moved for a result of 200,000. A
`strings.Builder` keeps its bytes in a buffer that grows, appends to it, and hands the result over
in `String()` without a final copy. Lesson 6 showed that its zero value is ready to use, which is
why `var b strings.Builder` is the whole set-up. **Join a few strings with `+`; build one up in a
loop with a `strings.Builder`.**
