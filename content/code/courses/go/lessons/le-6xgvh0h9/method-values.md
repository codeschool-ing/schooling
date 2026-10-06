---
title: Methods as values, and methods that are promoted
version: 1
---

Lesson 21 passed functions around as values: stored in a variable, handed to `slices.SortFunc`. A
method can be used the same way, in two spellings that look alike and give different things.
Between them they show what a receiver really is. The program is in `~/methods-values`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"strings\"\n)\n\ntype Rect struct {\n\tW, H float64\n}\n\nfunc (r Rect) Area() float64 {\n\treturn r.W * r.H\n}\n",
      "note": "Section 02's `Rect`, with its one method."
    },
    {
      "code": "\ntype Shift int\n\nfunc (s Shift) Rotate(r rune) rune {\n\tif r < 'a' || r > 'z' {\n\t\treturn r\n\t}\n\treturn 'a' + (r-'a'+rune(s))%26\n}\n",
      "note": "A defined `int` whose method moves a lower-case letter `s` places along the alphabet, wrapping from `z` back to `a`, and leaves anything else alone."
    },
    {
      "code": "\nfunc main() {\n\tr := Rect{W: 3, H: 4}\n\tarea := r.Area\n\tfmt.Printf(\"%T  %v\\n\", area, area())\n",
      "note": "**`r.Area` without the brackets is a method value**: a function with the receiver already filled in. Its type is `func() float64`, no parameters, because `r` is part of it."
    },
    {
      "code": "\tfmt.Printf(\"%T  %v\\n\", Rect.Area, Rect.Area(r))\n",
      "note": "**`Rect.Area`, named through the type, is a method expression**, and its type is `func(main.Rect) float64`. The receiver has become what it always was underneath: the first parameter."
    },
    {
      "code": "\n\tr.W = 10\n\tfmt.Println(area(), r.Area())\n",
      "note": "`area` still says 12 after `r` changed. The receiver was copied into the method value when `r.Area` was evaluated, and a value receiver is a copy, which lesson 26 is about."
    },
    {
      "code": "\n\tfmt.Println(strings.Map(Shift(13).Rotate, \"hello, gopher\"))\n}\n",
      "note": "A method value goes anywhere a function of its type is wanted. `strings.Map` wants a `func(rune) rune`, and `Shift(13).Rotate` is one, carrying its 13 with it."
    }
  ],
  "output": "func() float64  12\nfunc(main.Rect) float64  12\n12 40\nuryyb, tbcure\n"
}
```

`strings.Map`'s signature says what it wants, and the method value fits it without a wrapper:

```
ana@vm:~/methods-values$ go doc strings.Map | head -4
package strings // import "strings"

func Map(mapping func(rune) rune, s string) string
    Map returns a copy of the string s with all its characters modified
```

The method expression is the strongest evidence for section 02's first sentence. `r.Area()` and
`Rect.Area(r)` are the same call, written two ways; **a method is a function whose first parameter
is written before its name**, and the dot syntax is how Go lets you call it on a value. Lesson 26
uses method expressions to compare the two kinds of receiver side by side.

The method value is what you will meet more often. A function that wants a callback can take a
method of a value that has state, with nothing to declare: a `Shift` that remembers its 13, a
logger's method that remembers where it writes. Lesson 21's closures did the same job with a
function literal, and a method value is the shorter spelling when the method already exists.

## Promoted methods

Lesson 16 embedded a `Person` in an `Employee` and found `e.Name` promoted from the inner struct.
Methods are promoted by the same search, and lesson 16 section 04's rule decides which wins when two
have the same name: the shallower one. The program in `~/methods-embed` has a `Person` with two
methods, a `Contractor` that embeds `Person` and adds nothing, and an `Employee` that embeds
`Person` and declares its own `Greet`:

```go
type Person struct {
	Name string
}

func (p Person) Greet() string {
	return "Hello, I am " + p.Name
}

func (p Person) Introduce() string {
	return p.Greet() + "."
}

type Contractor struct {
	Person
	Agency string
}

type Employee struct {
	Person
	Company string
}

func (e Employee) Greet() string {
	return e.Person.Greet() + " from " + e.Company
}

func main() {
	c := Contractor{Person: Person{Name: "Caio"}, Agency: "Temps"}
	e := Employee{Person: Person{Name: "Ana"}, Company: "Acme"}

	fmt.Println(c.Greet())
	fmt.Println(e.Greet())
	fmt.Println(e.Person.Greet())
	fmt.Println(e.Introduce())
}
```

```
ana@vm:~/methods-embed$ go run .
Hello, I am Caio
Hello, I am Ana from Acme
Hello, I am Ana
Hello, I am Ana.
```

`Contractor` has no `Greet`, so `c.Greet()` is promoted from `Person`. `Employee` has one at depth 0,
so `e.Greet()` finds it first, and `e.Person.Greet()` still reaches the inner one by its full path,
which is how `Employee`'s own `Greet` builds on it.

The fourth line is the one to keep. **A promoted method runs on the embedded value, not on the outer
one.** `e.Introduce()` is `e.Person.Introduce()`: its receiver `p` is a `Person`, so `p.Greet()`
inside it is `Person`'s `Greet`, and `Employee`'s is never asked. In a language with inheritance the
call would usually go to the outer type's version. In Go the method has no way to know an `Employee`
is around it, which is lesson 16 section 03's point about embedding, now with methods:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Two calls on e, an Employee that embeds a Person. e.Greet() finds the Greet declared on Employee itself, at depth 0, and prints Hello, I am Ana from Acme. e.Introduce() finds no Introduce on Employee, so it is promoted from the embedded Person and receives e.Person. Inside it, p.Greet() calls Person&#x27;s Greet, because p is a Person; Employee&#x27;s Greet is never asked, and the line printed is Hello, I am Ana.\"><defs><marker id=\"pm-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"70\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the call</text><text x=\"330\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the method that runs</text><text x=\"590\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what it printed</text><text x=\"70\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">e.Greet()</text><rect x=\"220\" y=\"44\" width=\"220\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">func (e Employee) Greet()</text><text x=\"330\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">declared on Employee: depth 0, found first</text><path d=\"M120 62 L217 62\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pm-phosphor)\"></path><text x=\"590\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Hello, I am Ana from Acme</text><text x=\"70\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">e.Introduce()</text><rect x=\"206\" y=\"118\" width=\"248\" height=\"178\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"222\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Person</text><rect x=\"220\" y=\"136\" width=\"220\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">func (p Person) Introduce()</text><path d=\"M138 152 L217 152\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pm-phosphor)\"></path><text x=\"330\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">declared on the embedded Person: promoted</text><rect x=\"220\" y=\"244\" width=\"220\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">func (p Person) Greet()</text><path d=\"M330 198 L330 241\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pm-phosphor)\"></path><text x=\"340\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">p.Greet()</text><text x=\"590\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Hello, I am Ana.</text><text x=\"590\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">receives e.Person, not e</text><text x=\"590\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">p is a Person, so this is Person&#x27;s Greet</text><text x=\"590\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Employee&#x27;s Greet is never asked</text></svg>", "caption": "The program in ~/methods-embed. A promoted method runs on the embedded value, and what it calls is decided by that value's type."}
```

When a type needs behaviour that changes with the type it is used in, embedding is not the tool for
it. Lesson 27's interfaces are.
