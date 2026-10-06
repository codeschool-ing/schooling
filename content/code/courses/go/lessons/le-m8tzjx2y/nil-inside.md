---
title: An interface holding nil is not nil
version: 1
---

Lesson 6 printed the zero value of an interface as `<nil>`, and promised that an interface holding
a nil pointer is something else. Most people assume the two are one thing: put a nil into an
interface and the interface is nil. **That is the wrong picture, and the check that should catch
the difference lets it through.** Here are both, side by side:

```go
package main

import "fmt"

type Player struct {
	Name string
}

func main() {
	var e any
	var p *Player
	var v any = p

	fmt.Println(e == nil, p == nil, v == nil)
	fmt.Printf("%T %v\n", e, e)
	fmt.Printf("%T %v\n", v, v)
	fmt.Println(v == (*Player)(nil))
}
```

```
ana@vm:~/any-nil$ go run .
true true false
<nil> <nil>
*main.Player <nil>
true
```

`p` is nil and `v` holds `p`, and still `v == nil` is false. The second and third lines say why.
`e` has no type, and `%T` prints `<nil>` for it. `v` has a type, `*main.Player`, and its value is
a nil pointer of that type. Both print `<nil>` under `%v`, which is what makes this so hard to spot
in a log.

Section 02 described an interface value as two words, one for the type and one for the value.
**`== nil` on an interface asks whether both words are empty**, and a nil pointer leaves the value
word empty while filling the type word:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three interface values, each drawn as its two words, the type and the value. var e any holds no type and no value, and e == nil is true. var v any = 42 holds the type int and the value 42, and v == nil is false. var v any = p, where p is a nil *Player, holds the type *main.Player and a nil pointer as its value, and v == nil is still false, because the type word is not empty.\"><text x=\"30\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the statement</text><text x=\"320\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">type word</text><text x=\"470\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">value word</text><text x=\"625\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">== nil</text><text x=\"30\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">var e any</text><rect x=\"245\" y=\"40\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><rect x=\"395\" y=\"40\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"320\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">none</text><text x=\"470\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">none</text><text x=\"625\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">true</text><text x=\"30\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">var v any = 42</text><rect x=\"245\" y=\"96\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"395\" y=\"96\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">int</text><text x=\"470\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">42</text><text x=\"625\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">false</text><text x=\"30\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">var v any = p</text><rect x=\"245\" y=\"152\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"395\" y=\"152\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">*main.Player</text><text x=\"470\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a nil pointer</text><text x=\"625\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">false</text><text x=\"30\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">p is a nil *Player: the value is nil, the type is not</text><text x=\"30\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">only an interface with no type is nil</text></svg>", "caption": "An interface value is two words. It compares equal to nil only when both are empty, and a nil pointer still fills the type word."}
```

The last line of the program compares `v` with an interface holding the same thing, a `*Player`
that is nil, and that comparison is true. It is the right question for this value. It is rarely
written, because the code that has to ask it usually does not know which pointer type it was
handed.

## Where it bites

Nobody writes `var v any = p` and then tests `v` against nil. What people do write is a function
whose result is an interface, returning a pointer that happens to be nil:

```go
package main

import "fmt"

type Player struct {
	Name string
}

var players = map[string]*Player{"ana": {Name: "Ana"}}

func find(name string) *Player {
	return players[name]
}

func lookup(name string) any {
	p := find(name)
	return p
}

func main() {
	for _, name := range []string{"ana", "zoe"} {
		if r := lookup(name); r != nil {
			fmt.Println(name, "found:", r)
		} else {
			fmt.Println(name, "not found")
		}
	}
	r := lookup("zoe")
	fmt.Println(r.(*Player).Name)
}
```

```
ana@vm:~/any-nil-func$ go vet && go run .
ana found: &{Ana}
zoe found: <nil>
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x0 pc=0x499ffb]

goroutine 1 [running]:
main.main()
	/home/ana/any-nil-func/main.go:29 +0x15b
exit status 2
```

There is no `zoe` in the map, so `find` returned a nil `*Player`. `return p` in `lookup` put that
pointer into the `any` result, type and all. The caller tested `r != nil`, the test passed, and the
program announced that it had found `<nil>`. `go vet` said nothing, because nothing here breaks a
rule. The last line goes one step further: the assertion `r.(*Player)` succeeds, since a
`*Player` is exactly what `r` holds, and reading `.Name` through a nil pointer is the panic lesson 23
showed.

The fix is to decide, inside the function, what "nothing" means, and to return the interface's own
nil for it:

```go
package main

import "fmt"

type Player struct {
	Name string
}

var players = map[string]*Player{"ana": {Name: "Ana"}}

func find(name string) *Player {
	return players[name]
}

func lookup(name string) any {
	p := find(name)
	if p == nil {
		return nil
	}
	return p
}

func main() {
	for _, name := range []string{"ana", "zoe"} {
		if r := lookup(name); r != nil {
			fmt.Println(name, "found:", r)
		} else {
			fmt.Println(name, "not found")
		}
	}
}
```

```
ana@vm:~/any-nil-fix$ go run .
ana found: &{Ana}
zoe not found
```

`return nil` in a function whose result is `any` returns an interface with no type, and `r != nil`
now means what it says. The simpler fix is the advice of section 03: `find` already returns a
`*Player`, and a caller comparing a `*Player` with nil gets a true answer every time. **A function
should not return a nil pointer as an interface**, and the easiest way to keep that rule is to
return the concrete type.

This matters most with the interface you will use more than any other. `error` is an interface,
and a function that returns its own nil error type as an `error` returns an error that is not nil.
Lesson 32 shows it happening, and it is the same two words as the figure above.
