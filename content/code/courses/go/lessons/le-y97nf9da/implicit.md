---
title: Satisfied without saying so
version: 1
---

In Java or C#, a class that wants to be used as a `Shape` says so in its declaration:
`class Rect implements Shape`. Somebody coming from there looks for the Go spelling of
`implements`, and there is none. It is not among the 25 keywords lesson 1 counted, and nothing
else takes its place. **In Go a type satisfies an interface by having the interface's methods,
and by nothing else.** The type does not name the interface, and it does not need to know that
the interface exists. In `~/ifaces`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"math\"\n)\n"
    },
    {
      "code": "\ntype Shape interface {\n\tArea() float64\n}\n",
      "note": "**An interface type is a list of method signatures**, and nothing else: no fields, no code. A `Shape` is anything with a method `Area` that takes nothing and returns a `float64`."
    },
    {
      "code": "\ntype Rect struct {\n\tW, H float64\n}\n\nfunc (r Rect) Area() float64 {\n\treturn r.W * r.H\n}\n",
      "note": "An ordinary struct with an ordinary method, declared the way lesson 25 declares them. Nothing here mentions `Shape`."
    },
    {
      "code": "\ntype Circle struct {\n\tR float64\n}\n\nfunc (c Circle) Area() float64 {\n\treturn math.Pi * c.R * c.R\n}\n",
      "note": "A second type, unrelated to the first, with a method of the same name and the same signature. That is all it takes."
    },
    {
      "code": "\nfunc describe(s Shape) {\n\tfmt.Printf(\"%T with area %.2f\\n\", s, s.Area())\n}\n",
      "note": "**`describe` asks for a `Shape`, so it can call `Area` and nothing else.** `%T` prints the type of the value inside the interface, which is how the output tells the two apart."
    },
    {
      "code": "\nfunc main() {\n\tdescribe(Rect{W: 3, H: 4})\n\tdescribe(Circle{R: 1})\n",
      "note": "A `Rect` and a `Circle` are passed where a `Shape` is asked for. The compiler checks, at each call, that the value's method set has `Area`."
    },
    {
      "code": "\n\tshapes := []Shape{Rect{W: 2, H: 2}, Circle{R: 2}}\n\ttotal := 0.0\n\tfor _, s := range shapes {\n\t\ttotal += s.Area()\n\t}\n\tfmt.Printf(\"total %.2f\\n\", total)\n}\n",
      "note": "A slice of `Shape` holds values of different types side by side, and the loop calls the right `Area` for each: 4 for the square `Rect`, about 12.57 for the circle of radius 2."
    }
  ],
  "output": "main.Rect with area 12.00\nmain.Circle with area 3.14\ntotal 16.57"
}
```

Neither `Rect` nor `Circle` was declared as a `Shape`, and both were accepted as one. If you
deleted the `Shape` type and `describe` with it, the two structs would compile unchanged, because
nothing in them refers to it. **The relationship exists only where a value is used as a `Shape`, and
the compiler checks it there.**

A value of an interface type holds a value of some concrete type, and lesson 22 measured what that
costs: 16 bytes, one word saying which type is inside and one pointing at a copy of the value.
`%T` printed the first word. Calling `s.Area()` runs the `Area` of whatever type that word names.

## One interface, three packages

The standard library is built on this, and one function shows it. `fmt.Fprintf` is `Printf` with
somewhere to write to, and that somewhere is an interface from the `io` package:

```
ana@vm:~/ifaces-writer$ go doc fmt.Fprintf
package fmt // import "fmt"

func Fprintf(w io.Writer, format string, a ...any) (n int, err error)
    Fprintf formats according to a format specifier and writes to w. It returns
    the number of bytes written and any write error encountered.

ana@vm:~/ifaces-writer$ go doc io.Writer | head -5
package io // import "io"

type Writer interface {
	Write(p []byte) (n int, err error)
}
```

One method. Anything with a `Write` method of that shape is an `io.Writer`, so `Fprintf` can
write to a terminal, a buffer in memory and a string being built, with the same call:

```go
package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"strings"
)

func main() {
	var buf bytes.Buffer
	var sb strings.Builder

	writers := []io.Writer{os.Stdout, &buf, &sb}
	for i, w := range writers {
		fmt.Fprintf(w, "line %d, written to a %T\n", i, w)
	}

	fmt.Print(buf.String())
	fmt.Print(sb.String())
}
```

```
ana@vm:~/ifaces-writer$ go run .
line 0, written to a *os.File
line 1, written to a *bytes.Buffer
line 2, written to a *strings.Builder
```

The first line went straight to the terminal, because `os.Stdout` is the open file behind it. The
other two went into memory, and the last two `fmt.Print` calls brought them out. The buffer and
the builder are passed as `&buf` and `&sb` because their `Write` methods have pointer receivers,
which is lesson 26's rule; section 04 shows what passing `sb` itself does.

Now read the three `Write` methods as their packages declare them:

```
ana@vm:~/ifaces-writer$ go doc os.File.Write | sed -n 3p
func (f *File) Write(b []byte) (n int, err error)
ana@vm:~/ifaces-writer$ go doc bytes.Buffer.Write | sed -n 3p
func (b *Buffer) Write(p []byte) (n int, err error)
ana@vm:~/ifaces-writer$ go doc strings.Builder.Write | sed -n 3p
func (b *Builder) Write(p []byte) (int, error)
```

The parameter is `b` in one and `p` in another, and the builder's results have no names at all.
None of that matters. **What has to match is the method's name and the types of its parameters
and results**, in order: a `[]byte` in, an `int` and an `error` out. The names are documentation.

And the file that declares `strings.Builder` does not even import `io`:

```
ana@vm:~/ifaces-writer$ sed -n "/^import/,/^)/p" /usr/local/go/src/strings/builder.go
import (
	"internal/abi"
	"internal/bytealg"
	"unicode/utf8"
	"unsafe"
)
```

So `strings.Builder` fits `io.Writer` without its source ever naming the package that declares
it. Its `Write` has the right shape, and that is the whole of the connection.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Three types from three packages, *os.File, *bytes.Buffer and *strings.Builder, each with a Write method taking a []byte and returning an int and an error, whatever their parameters are called. Dashed arrows lead from each to the interface io.Writer, which lists that one method, and io.Writer is the type of the first parameter of fmt.Fprintf. None of the three types declares that it satisfies io.Writer; the compiler compares method sets where a value is passed.\"><defs><marker id=\"iw-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"135\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">three types, three packages</text><rect x=\"20\" y=\"40\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">*os.File</text><text x=\"32\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Write(b []byte) (n int, err error)</text><path d=\"M250 65 L295 65 L295 120 L336 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#iw-phosphor)\"></path><rect x=\"20\" y=\"105\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">*bytes.Buffer</text><text x=\"32\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Write(p []byte) (n int, err error)</text><path d=\"M250 130 L295 130 L295 140 L336 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#iw-phosphor)\"></path><rect x=\"20\" y=\"170\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">*strings.Builder</text><text x=\"32\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Write(p []byte) (int, error)</text><path d=\"M250 195 L295 195 L295 160 L336 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#iw-phosphor)\"></path><text x=\"298\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">has the method</text><text x=\"450\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the interface</text><rect x=\"340\" y=\"100\" width=\"220\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"354\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">type io.Writer interface {</text><text x=\"366\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Write(p []byte) (n int, err error)</text><text x=\"354\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">}</text><text x=\"647\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the function that asks</text><rect x=\"586\" y=\"115\" width=\"124\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"648\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">fmt.Fprintf(</text><text x=\"648\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">w io.Writer, ...)</text><path d=\"M582 140 L564 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#iw-phosphor)\"></path><path d=\"M20 248 L700 248\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">None of the three declares that it satisfies io.Writer. The compiler compares the method set</text><text x=\"20\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">of each value with the interface at the call, and that comparison is the whole contract.</text></svg>", "caption": "An interface is satisfied by having its methods. The three types were written without io.Writer in mind, and all three fit it."}
```

This is the half of inheritance that lesson 16 left to interfaces: letting different types stand
in for one another. A class hierarchy decides that in advance, in the declaration of every class.
**An interface decides it at the point of use, and a type written years earlier can satisfy an
interface written today**, which section 03 shows with three types from `time`.
