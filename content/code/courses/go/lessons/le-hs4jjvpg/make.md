---
title: "`make`, empty slices and nil slices"
version: 1
---

Section 03 counted what growing costs: twelve arrays allocated and filled for 2,000 numbers. When
you know the size in advance, you can pay for one array instead, and `make` is how you say so. Its
documentation for slices is four sentences:

```
ana@vm:~/slices-make-doc$ go doc builtin.make | head -15
package builtin // import "builtin"

func make(t Type, size ...IntegerType) Type
    The make built-in function allocates and initializes an object of type
    slice, map, or chan (only). Like new, the first argument is a type,
    not a value. Unlike new, make's return type is the same as the type of its
    argument, not a pointer to it. The specification of the result depends on
    the type:

      - Slice: The size specifies the length. The capacity of the slice is equal
        to its length. A second integer argument may be provided to specify a
        different capacity; it must be no smaller than the length. For example,
        make([]int, 0, 10) allocates an underlying array of size 10 and returns
        a slice of length 0 and capacity 10 that is backed by this underlying
        array.
```

So `make([]int, 0, 2000)` is an empty slice over an array with room for 2,000. The same loop as
section 03, once without `make` and once with it, counting the arrays and the copying:

```go
package main

import "fmt"

func main() {
	var grown []int
	arrays, copied := 0, 0
	for i := 0; i < 2000; i++ {
		if len(grown) == cap(grown) {
			arrays++
			copied += len(grown)
		}
		grown = append(grown, i)
	}
	fmt.Println("append alone:", arrays, "new arrays,", copied, "elements copied")

	sized := make([]int, 0, 2000)
	arrays, copied = 0, 0
	for i := 0; i < 2000; i++ {
		if len(sized) == cap(sized) {
			arrays++
			copied += len(sized)
		}
		sized = append(sized, i)
	}
	fmt.Println("make first:  ", arrays, "new arrays,", copied, "elements copied")
}
```

```
ana@vm:~/slices-make$ go run .
append alone: 12 new arrays, 4940 elements copied
make first:   0 new arrays, 0 elements copied
```

`len(grown) == cap(grown)` is the moment before `append` has to find a new array, and at that
moment it copies every element the slice holds. Without `make`, 2,000 appends moved 4,940
elements, two and a half times the data, through twelve arrays. With it, `append` never left the
first one. **When the final size is known, or a fair upper bound is, give it to `make` as the
capacity.** When it is not known, appending to a slice that starts empty is the normal thing to do,
and section 03 showed why it is cheap enough.

## Length or capacity: the one-argument trap

The commonest mistake with `make` is passing the size as the only argument and then appending:

```go
package main

import (
	"fmt"
	"strings"
)

func main() {
	names := []string{"ana", "bia", "caio"}
	upper := make([]string, len(names))
	for i := 0; i < len(names); i++ {
		upper = append(upper, strings.ToUpper(names[i]))
	}
	fmt.Println(len(upper), upper)
	fmt.Printf("%q\n", upper)
}
```

```
ana@vm:~/slices-zeros$ go run .
6 [   ANA BIA CAIO]
["" "" "" "ANA" "BIA" "CAIO"]
```

Six names where there should be three. **`make([]string, 3)` is a slice of three strings already,
each one the empty string; it is not room for three.** `append` adds after the length, so the real
names land in positions 3, 4 and 5. `Println` shows the three empty strings as gaps that are easy
to miss, and `%q` puts quotes round each one so you can count them. There are two correct versions,
and they do not mix: `make([]string, 0, len(names))` with `append`, or `make([]string, len(names))`
with `upper[i] = …` writing into each position.

The order of the two numbers is length, then capacity. With constants the compiler checks it:

```go
package main

import "fmt"

func main() {
	fmt.Println(make([]int, 10, 3))
}
```

```
ana@vm:~/slices-swap$ go run .
# example.com/swap
./main.go:6:26: invalid argument: length and capacity swapped
```

## A nil slice and an empty one

A slice with no elements comes in two kinds, and most of Go cannot tell them apart:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"encoding/json\"\n\t\"fmt\"\n)\n\nfunc main() {\n\tvar none []string\n\tempty := []string{}\n",
      "note": "**`var` gives a slice its zero value, which is `nil`: no array at all**, length 0, capacity 0. The literal `[]string{}` gives a slice of length 0 that is not `nil`."
    },
    {
      "code": "\tfmt.Println(none, empty)\n\tfmt.Println(len(none), len(empty))\n",
      "note": "Both print as `[]` and both have length 0. Neither `fmt` nor `len` sees a difference."
    },
    {
      "code": "\tfmt.Println(none == nil, empty == nil)\n",
      "note": "`== nil` does. It is the one comparison a slice allows; lesson 11 showed the compiler refusing `==` between two slices."
    },
    {
      "code": "\n\ta, _ := json.Marshal(none)\n\tb, _ := json.Marshal(empty)\n\tfmt.Println(string(a), string(b))\n",
      "note": "**`encoding/json` writes a nil slice as `null` and an empty one as `[]`.** A reader that expects a list gets `null` from the first. The `_` discards the error `Marshal` also returns, which lesson 20 explains, and lesson 15 is about JSON."
    },
    {
      "code": "\n\tnone = append(none, \"ana\")\n\tfmt.Println(none, len(none))\n}\n",
      "note": "`append` to a nil slice works, and allocates the first array itself. You never need `make` just to have something to append to."
    }
  ],
  "output": "[] []\n0 0\ntrue false\nnull []\n[ana] 1"
}
```

The working rule follows from that output. Declare with `var s []T` when you mean "nothing yet",
because the nil slice behaves as empty everywhere that matters inside the program. **Test for
emptiness with `len(s) == 0`, never with `s == nil`**, because the second is false for `[]string{}`
and true only for one of the two. And where the slice leaves the program as JSON, decide which
of `null` and `[]` the reader expects, and start from `[]string{}` or `make` if it is the second.
