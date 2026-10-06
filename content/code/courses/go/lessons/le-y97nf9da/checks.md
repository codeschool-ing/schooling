---
title: When a type does not fit
version: 1
---

Implicit does not mean unchecked. Every place a value is used as an interface — passed to a
parameter, assigned to a variable, put in a slice of that interface — the compiler compares the
value's method set with the interface's methods. If one is missing, it refuses the program. **The
check happens at compile time, at the point of use, and the message names the method.** Three
ways to fail it are worth recognising on sight.

## A method missing, or of the wrong type

`Square` has its method under another name. `Grid` has `Area`, returning the wrong type:

```go
package main

import "fmt"

type Shape interface {
	Area() float64
}

type Square struct {
	Side float64
}

func (s Square) Size() float64 {
	return s.Side * s.Side
}

type Grid struct {
	Rows, Cols int
}

func (g Grid) Area() int {
	return g.Rows * g.Cols
}

func main() {
	sq := Square{Side: 2}
	g := Grid{Rows: 3, Cols: 4}
	shapes := []Shape{sq, g}
	fmt.Println(len(shapes))
}
```

```
ana@vm:~/ifaces-missing$ go build
# example.com/missing
./main.go:28:20: cannot use sq (variable of struct type Square) as Shape value in array or slice literal: Square does not implement Shape (missing method Area)
./main.go:28:24: cannot use g (variable of struct type Grid) as Shape value in array or slice literal: Grid does not implement Shape (wrong type for method Area)
		have Area() int
		want Area() float64
```

Both errors point at line 28, the slice literal, and not at the types: the types are fine on
their own, and only the use asks anything of them. **Read each message from the end.** `missing method
Area` means no method of that name. `wrong type for method Area` means the name is there and the
signature is not, and the two indented lines put them side by side: `have` is what the type
declares, `want` is what the interface asks for. An `int` is not a `float64` here any more than
anywhere else in Go (lesson 10).

## A method on the pointer

The third failure is lesson 26's, met from the interface side. `strings.Builder`'s `Write` has a
pointer receiver, so a `strings.Builder` value does not have it in its method set:

```go
package main

import (
	"fmt"
	"strings"
)

func main() {
	var sb strings.Builder
	fmt.Fprintf(sb, "hello")
	fmt.Println(sb.String())
}
```

```
ana@vm:~/ifaces-value$ go build
# example.com/value
./main.go:10:14: cannot use sb (variable of struct type strings.Builder) as io.Writer value in argument to fmt.Fprintf: strings.Builder does not implement io.Writer (method Write has pointer receiver)
```

`fmt.Fprintf(&sb, "hello")` is the fix, as section 02 wrote it. **When the message ends in
`(method Write has pointer receiver)`, or the same words about any method, pass the address.**

## Making the compiler check early

All three errors appeared because something used the type as an interface. When nothing does yet,
nothing is checked. A `Rect` meant to be a `Shape`, whose method somebody renamed to `Size`, builds
and runs without a word:

```go
package main

type Shape interface {
	Area() float64
}

type Rect struct {
	W, H float64
}

func (r Rect) Size() float64 {
	return r.W * r.H
}
```

```go
package main

import "fmt"

func main() {
	r := Rect{W: 3, H: 4}
	fmt.Println(r.Size())
}
```

```
ana@vm:~/ifaces-assert$ go build && ./assert
12
```

In a real project the code that uses `Rect` as a `Shape` is often in another package, so the
error would surface there, for somebody else, after the rename was merged. One line in the type's
own package moves it back:

```
ana@vm:~/ifaces-assert$ cat check.go
package main

var _ Shape = Rect{}
ana@vm:~/ifaces-assert$ go build
# example.com/assert
./check.go:3:15: cannot use Rect{} (value of struct type Rect) as Shape value in variable declaration: Rect does not implement Shape (missing method Area)
```

`var _ Shape = Rect{}` declares a variable of type `Shape`, gives it a `Rect`, and names it `_`,
the blank identifier lesson 20 used to throw a result away. No code can ever read it. Its only
effect is the assignment, and an assignment to an interface is exactly what makes the compiler
compare method sets. **It is a check that costs one line, and the compiler makes it, so a
rename fails the build of the type's own package.**

For a type whose methods have pointer receivers, the value on the right is a pointer, and the
cheapest pointer to write is a nil one converted to the type. The standard library does this:

```
ana@vm:~/ifaces-assert$ grep -n "^var _ " /usr/local/go/src/net/http/transport.go /usr/local/go/src/encoding/json/stream.go
/usr/local/go/src/net/http/transport.go:2153:var _ io.ReaderFrom = (*persistConnWriter)(nil)
/usr/local/go/src/encoding/json/stream.go:292:var _ Marshaler = (*RawMessage)(nil)
/usr/local/go/src/encoding/json/stream.go:293:var _ Unmarshaler = (*RawMessage)(nil)
```

`(*RawMessage)(nil)` is the conversion of lesson 10 applied to `nil`: a `*RawMessage` that points
at nothing, which is enough, because only its type is being checked. Write one of these lines
when a type exists to satisfy an interface that is used somewhere else. When the interface is
used right next to the type, as in section 02, the use is already the check.
