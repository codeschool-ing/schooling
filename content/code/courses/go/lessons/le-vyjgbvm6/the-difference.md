---
title: A copy, or the thing itself
version: 1
---

Somebody coming from Java or Python reads `c.IncByValue()` as "do this to `c`", the way `this` and
`self` work there. **In Go a receiver is a parameter, and lesson 22 said what every parameter is: a
copy.** A method declared on `Counter` receives a `Counter` of its own, and whatever it changes, it
changes in that copy. A method declared on `*Counter` receives an address, and changes made through
the address land in the caller's variable. The program below has one of each, in `~/receivers`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\ntype Counter struct {\n\tn int\n}\n",
      "note": "A struct with one field, so that every change is easy to see."
    },
    {
      "code": "\nfunc (c Counter) IncByValue() {\n\tc.n++\n\tfmt.Println(\"  inside IncByValue:\", c.n)\n}\n",
      "note": "**A value receiver: `c` is a `Counter` of the method's own**, filled in from whatever the method was called on. It counts up and prints what it counted."
    },
    {
      "code": "\nfunc (c *Counter) Inc() {\n\tc.n++\n}\n",
      "note": "**A pointer receiver: `c` is a `*Counter`**, the address of a `Counter` that lives somewhere else. `c.n` goes through that address, the way `p.Field` did in lesson 23."
    },
    {
      "code": "\nfunc main() {\n\tvar c Counter\n\tc.IncByValue()\n\tc.IncByValue()\n\tfmt.Println(\"after IncByValue:\", c.n)\n",
      "note": "Two calls with the value receiver. Each one prints 1, and `c.n` is still 0 afterwards: both calls counted a copy."
    },
    {
      "code": "\n\tc.Inc()\n\tc.Inc()\n\tfmt.Println(\"after Inc:\", c.n)\n",
      "note": "Two calls with the pointer receiver, on the same variable, written the same way. This time `c.n` is 2."
    },
    {
      "code": "\n\tp := &c\n\tp.IncByValue()\n\tfmt.Println(\"after p.IncByValue:\", c.n)\n",
      "note": "Calling the value method through a pointer does not change the rule. The method still gets a copy, of what `p` points at: it prints 3 and `c.n` stays 2."
    },
    {
      "code": "\n\tfmt.Printf(\"%T\\n%T\\n\", Counter.IncByValue, (*Counter).Inc)\n}\n",
      "note": "**The method expressions of lesson 25 show what a receiver is: the first parameter.** `%T` prints their types, and the only difference between the two is the asterisk."
    }
  ],
  "output": "  inside IncByValue: 1\n  inside IncByValue: 1\nafter IncByValue: 0\nafter Inc: 2\n  inside IncByValue: 3\nafter p.IncByValue: 2\nfunc(main.Counter)\nfunc(*main.Counter)"
}
```

```
ana@vm:~/receivers$ go run .
  inside IncByValue: 1
  inside IncByValue: 1
after IncByValue: 0
after Inc: 2
  inside IncByValue: 3
after p.IncByValue: 2
func(main.Counter)
func(*main.Counter)
```

`IncByValue` compiles, runs and reports a count of 1 every time, so nothing looks wrong from
inside it. The method did exactly what it says, to a variable that disappeared when it returned.
**A value receiver that assigns to a field is almost always a bug**, and the compiler accepts it
without a word, because changing a parameter is legal everywhere in Go.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Two calls on main&#x27;s variable c, a Counter. In c.IncByValue(), the value receiver is a second Counter, copied from c when the call starts: the method counts the copy up to 1, and main&#x27;s c still holds 0. In c.Inc(), the pointer receiver holds the address of c, so c.n++ inside the method writes into main&#x27;s c, which reads 1.\"><defs><marker id=\"rv-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"rv-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">c.IncByValue()</text><text x=\"150\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">value receiver</text><rect x=\"40\" y=\"48\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c</text><text x=\"158\" y=\"65\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n: 0</text><text x=\"105\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main&#x27;s variable</text><rect x=\"300\" y=\"48\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"312\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c Counter</text><text x=\"418\" y=\"65\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n: 1</text><text x=\"365\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the receiver</text><path d=\"M170 65 L296 65\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rv-amber)\"></path><text x=\"233\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">copied at the call</text><text x=\"470\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the method counts its copy;</text><text x=\"470\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">main&#x27;s c is never touched,</text><text x=\"470\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">and the copy is dropped</text><path d=\"M20 150 L700 150\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">c.Inc()</text><text x=\"85\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pointer receiver</text><rect x=\"40\" y=\"200\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"52\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c</text><text x=\"158\" y=\"217\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n: 1</text><text x=\"105\" y=\"247\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main&#x27;s variable</text><rect x=\"300\" y=\"200\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"314\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">•</text><text x=\"326\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c *Counter</text><text x=\"365\" y=\"247\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the receiver</text><path d=\"M308 217 L174 217\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rv-phosphor)\"></path><text x=\"240\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the address of c</text><text x=\"470\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">c.n++ goes through the</text><text x=\"470\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">address and writes into</text><text x=\"470\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">main&#x27;s own c</text></svg>", "caption": "A value receiver is a copy made for the call; a pointer receiver is the address of the variable the method was called on."}
```

## The & you did not write

`c` is a `Counter`, and `Inc` wants a `*Counter`. The call `c.Inc()` still compiles, because Go
rewrites it as `(&c).Inc()`: when a method needs a pointer and you call it on a variable, the
compiler takes the variable's address for you. It works in the other direction too. `p.IncByValue()`
is `(*p).IncByValue()`, and the output shows what that costs: the method copied the `Counter` that
`p` points at, counted the copy to 3, and left `c` at 2.

That is why the two kinds of method look identical at the call. **Whether a call can change your
variable is decided by the method's declaration, and you cannot see it from the call site.** Reading
the receiver is the only way to know, and `go doc` prints it with every method, as section 04 shows.

## Where there is no address to take

The automatic `&` needs something with an address. A map element and a literal have none that Go
will give out, so calling a pointer method on either is refused:

```go
package main

import "fmt"

type Counter struct {
	n int
}

func (c *Counter) Inc() {
	c.n++
}

func main() {
	byName := map[string]Counter{"ana": {}}
	byName["ana"].Inc()

	Counter{}.Inc()

	list := []Counter{{}, {}}
	list[0].Inc()
	fmt.Println(list)
}
```

```
ana@vm:~/receivers-addr$ go build
# example.com/addr
./main.go:15:16: cannot call pointer method Inc on Counter
./main.go:17:12: cannot call pointer method Inc on Counter
```

Two errors, on lines 15 and 17, and none on line 20. Lesson 23 showed `&nums[0]` accepted and
`&ages["ana"]` refused, and this is the same rule reached through a method call. A slice element
lives in an array that stays where it is. A map's entries do not: when a map grows, the runtime
copies them into a new table (`grow` in `/usr/local/go/src/internal/runtime/maps/table.go`), and an
address handed out before that would point at the old one. A literal like `Counter{}` is a value
that was never stored in a variable, so there is nothing whose address could be taken.

The fix is lesson 23's too: **keep pointers in the map, so that the element already is an address.**

```go
package main

import "fmt"

type Counter struct {
	n int
}

func (c *Counter) Inc() {
	c.n++
}

func main() {
	byName := map[string]*Counter{"ana": {}}
	byName["ana"].Inc()
	byName["ana"].Inc()

	list := []Counter{{}, {}}
	list[0].Inc()
	fmt.Println(byName["ana"].n, list)
}
```

```
ana@vm:~/receivers-addr-fix$ go run .
2 [{1} {0}]
```

`{}` inside a `map[string]*Counter` literal is short for `&Counter{}`, so each entry starts as the
address of a fresh `Counter`. Both calls go through that address and the count reaches 2, and
`list[0].Inc()` changed the first element of the slice in place.
