---
title: Every variable starts at zero
version: 1
---

A beginner who has met C expects a variable nobody assigned to hold whatever the memory held
before, and a beginner who has met JavaScript expects `undefined`. Go has neither. **Every variable
is set to its type's zero value at the moment it is declared.** There is no such thing in Go as a
variable that has not been initialised, and no value that means "not set yet" unless you design
one.

The zero value depends only on the type. This program declares one variable of each kind you will
meet in this course and prints each one's type and value without assigning anything:

```go
// Command zero prints the zero value of one variable of each kind.
package main

import "fmt"

type point struct {
	X, Y  int
	Label string
}

func show(v any) {
	fmt.Printf("%-16T %#v\n", v, v)
}

func main() {
	var i int
	var f float64
	var ok bool
	var s string
	var p *int
	var sl []int
	var m map[string]int
	var fn func()
	var err error
	var arr [3]int
	var pt point

	show(i)
	show(f)
	show(ok)
	show(s)
	show(p)
	show(sl)
	show(m)
	show(fn)
	show(err)
	show(arr)
	show(pt)
	show(point{X: 2})

	fmt.Println(len(sl), len(m), m["missing"], sl == nil)
}
```

`show` takes a value of any type (`any` is lesson 28's subject) and prints it with two verbs of
`fmt`: `%T` is the value's type and `%#v` is the value written the way Go source would write it,
which is why the string comes out as `""` rather than as nothing at all.

```
ana@vm:~/zero$ go run .
int              0
float64          0
bool             false
string           ""
*int             (*int)(nil)
[]int            []int(nil)
map[string]int   map[string]int(nil)
func()           (func())(nil)
<nil>            <nil>
[3]int           [3]int{0, 0, 0}
main.point       main.point{X:0, Y:0, Label:""}
main.point       main.point{X:2, Y:0, Label:""}
0 0 0 true
```

Read it in three groups.

**Numbers are `0`, booleans are `false` and strings are `""`.** The `float64` prints as `0` and not
`0.0` because that is how `%#v` writes a float with nothing after the point; the value is the same.

**Pointers, slices, maps, functions and interfaces are `nil`.** `nil` is not one value shared by
all of them. It is the zero value of each of those kinds separately, which is why `%#v` writes it
with the type attached: `[]int(nil)` and `map[string]int(nil)` are different things. The `error`
line is the odd one, with `<nil>` in both columns: an interface holding nothing has no type to
report. Lessons 28 and 32 come back to it, because an interface that holds a nil pointer is not
this empty interface and does not compare equal to `nil`.

**An array or a struct is zero all the way down.** Each element of the array is an `int` zero, and
each field of the struct is the zero of its own type. A struct literal that names only some fields,
like `point{X: 2}`, leaves the others at zero, which is why you will see Go code that sets only the
fields that matter.

The last line shows that `nil` is a value you can use. The length of a nil slice is 0, the length
of a nil map is 0, and reading a key from a nil map gives that map's zero value, here `0`. Writing
to a nil map is the one operation of these that fails, with a panic, and lesson 14 shows it.

## A zero value that is ready to use

Because every variable starts at zero, the authors of a Go type decide what zero should mean, and
the good ones make it mean "empty and ready". Two types of the standard library you will use often
need no setting up at all:

```go
package main

import (
	"bytes"
	"fmt"
	"strings"
)

func main() {
	var sb strings.Builder
	sb.WriteString("built ")
	sb.WriteString("from nothing")
	fmt.Println(sb.String(), sb.Len())

	var buf bytes.Buffer
	buf.WriteString("no constructor needed")
	fmt.Println(buf.String())
}
```

```
ana@vm:~/zero-useful$ go run .
built from nothing 18
no constructor needed
ana@vm:~/zero-useful$ go doc strings.Builder | head -8
package strings // import "strings"

type Builder struct {
	// Has unexported fields.
}
    A Builder is used to efficiently build a string using Builder.Write methods.
    It minimizes memory copying. The zero value is ready to use. Do not copy a
    non-zero Builder.
```

**"The zero value is ready to use" is a sentence the standard library writes on purpose**, and
`go doc` is where you find it. `bytes.Buffer` says the same, and so does `sync.Mutex`, the lock of
the `go-concurrency` course, whose zero value is an unlocked mutex. A map is the counter-example
from the program above: its zero value can be read and not written, so a map you mean to fill is
made with `make` first, which lesson 14 covers.

The habit worth taking from this is a question to ask of every type you write: if somebody
declares one with `var` and never assigns it, does it still work? When the answer is yes, your
type needs no constructor, and a field you forgot to set does no harm.
