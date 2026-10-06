---
title: A type every value belongs to
version: 1
---

Coming from Python or JavaScript, `any` looks like the place where Go stops checking types: a
variable that takes whatever you put in it. It does take whatever you put in it. **But `any` is a
type, as `int` is a type, and the compiler checks every use of it.** What is unusual is how little
it lets you do, and section 03 is about that.

Lesson 27 gave the rule for interfaces: a type satisfies an interface when it has every method the
interface lists, and nothing has to be declared. `any` is the interface that lists no methods.
Every type has all of zero methods, so every value in Go satisfies it, from an `int` to a struct of
your own:

```go
package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

func main() {
	var v any
	fmt.Printf("%-12T %v\n", v, v)

	v = 42
	fmt.Printf("%-12T %v\n", v, v)

	v = "Ana"
	fmt.Printf("%-12T %v\n", v, v)

	v = []int{1, 2, 3}
	fmt.Printf("%-12T %v\n", v, v)

	v = Player{Name: "Ana", Score: 10}
	fmt.Printf("%-12T %v\n", v, v)

	things := []any{42, "Ana", 2.5, true, nil}
	fmt.Println(len(things), things)
}
```

```
ana@vm:~/any$ go run .
<nil>        <nil>
int          42
string       Ana
[]int        [1 2 3]
main.Player  {Ana 10}
5 [42 Ana 2.5 true <nil>]
```

Read the left column. `v` was declared once, as `any`, and its type never changed. What changed is
the type of the value inside it, which Go calls the **dynamic type**, and `%T` prints that one.
Lesson 22 measured an `any` at 16 bytes: one word says which type is stored and the other holds the
value. The first line is a variable of type `any` before anything was put in it, with no type and
no value, printed `<nil>` twice. Section 04 comes back to that line, because an interface with no
type in it is not the same thing as an interface holding a nil.

The last line is a slice of `any`. Each of its five elements is an interface value of its own, and
each carries its own dynamic type, so one slice holds a number, a string, a float, a boolean and
nothing.

## `any` and `interface{}` are one type

Older code, and much of the standard library, writes `interface{}`: the interface type with
nothing between its braces. `any` is a second name for it:

```go
package main

import "fmt"

func main() {
	var v any = 1
	var w interface{} = "one"
	v = w
	fmt.Printf("%T %T %v\n", &v, &w, v)
}
```

```
ana@vm:~/any-alias$ go doc builtin.any
package builtin // import "builtin"

type any = interface{}
    any is an alias for interface{} and is equivalent to interface{} in all
    ways.

func recover() any
ana@vm:~/any-alias$ go run .
*interface {} *interface {} one
ana@vm:~/any-alias$ go mod edit -go=1.17 && go build
# example.com/alias
./main.go:6:8: predeclared any requires go1.18 or later (-lang was set to go1.17; check go.mod)
```

The `=` in `type any = interface{}` makes it an alias, the kind of declaration lesson 10 told apart
from a new type. So `v = w` assigns one to the other with no conversion, and `%T` prints the same
type for a pointer to each, by its long name, `*interface {}`. The name is younger than the type:
with the `go` line of `go.mod` moved back to 1.17, the compiler refuses the program it had just
run, because `any` arrived in Go 1.18. Lesson 2 showed that line choosing which version of the
language a module is written in. In anything newer, people write `any`; when you read
`interface{}` in older code, read it as the same word.

## Where you have already met it

Lesson 4 read the signature of `fmt.Println` in `go doc`,
`func Println(a ...any) (n int, err error)`: any number of arguments, each of any type. Lesson 15
called `json.Unmarshal(data []byte, v any)`, which takes its destination as `any` because it has to
accept a pointer to whatever struct you declared. **Both are the right use of `any`: the function
really does accept every type, and works out at run time what it was given.**

"Every type" does not stretch to slices of every type, though. A `[]string` is not a `[]any`, and
passing one with `...`, the way lesson 21 passed a slice to a variadic function, is refused:

```go
package main

import "fmt"

func main() {
	names := []string{"ana", "bia"}
	fmt.Println(names...)
}
```

```
ana@vm:~/any-slice$ go build
# example.com/slice
./main.go:7:14: cannot use names (variable of type []string) as []any value in argument to fmt.Println
```

The elements of a `[]string` are strings, one after another in the array. The elements of a `[]any`
are interface values, each a type and a value. No conversion turns one array into the other in
place, so getting a `[]any` means building a new slice and putting each string into an interface on
the way in. Go does not hide that loop; you write it:

```go
package main

import "fmt"

func main() {
	names := []string{"ana", "bia"}
	args := make([]any, len(names))
	for i, n := range names {
		args[i] = n
	}
	fmt.Println(args...)
}
```

```
ana@vm:~/any-slice-fix$ go run .
ana bia
```

## A JSON document of unknown shape

Lesson 15 decoded JSON into a struct, whose field types told `Unmarshal` what to build. Sometimes
there is no struct, because the document's shape is not known when the program is written: a
configuration file that varies, a reply from a service that changes. Then the destination is a
`map[string]any`, and `Unmarshal` chooses the type of every value itself:

```go
package main

import (
	"encoding/json"
	"fmt"
)

func main() {
	data := []byte(`{"name": "Ana", "age": 31, "admin": false,
		"tags": ["go", "sql"], "boss": null, "id": 9007199254740993}`)

	var doc map[string]any
	if err := json.Unmarshal(data, &doc); err != nil {
		fmt.Println(err)
		return
	}
	for _, k := range []string{"name", "age", "admin", "tags", "boss", "id"} {
		fmt.Printf("%-6s %-14T %v\n", k, doc[k], doc[k])
	}
}
```

```
ana@vm:~/any-json$ go run .
name   string         Ana
age    float64        31
admin  bool           false
tags   []interface {} [go sql]
boss   <nil>          <nil>
id     float64        9.007199254740992e+15
ana@vm:~/any-json$ go doc encoding/json.Unmarshal | grep -A8 'into an interface value'
    To unmarshal JSON into an interface value, Unmarshal stores one of these in
    the interface value:

      - bool, for JSON booleans
      - float64, for JSON numbers
      - string, for JSON strings
      - []any, for JSON arrays
      - map[string]any, for JSON objects
      - nil for JSON null
```

`age` was `31` in the JSON and came back as a `float64`. **Every JSON number becomes a `float64`**,
because JSON has one kind of number, with or without a point, and `Unmarshal` has no way to know
that you meant an `int`. `tags` came back as `[]interface {}` and not as `[]string`, since nothing
promises that the next element is a string too. `boss` was `null` and became an interface holding
nothing, with no type at all.

The `id` line is the expensive one. The JSON said `9007199254740993` and the program holds
`9.007199254740992e+15`: the last digit went from 3 to 2, and `err` was nil. A `float64` keeps 52
bits of fraction, lesson 7 showed, so above 2⁵³, which is 9,007,199,254,740,992, it can no longer
hold every whole number. The next integer is one it skips, and it was rounded to its neighbour.
Sixty-four-bit ids from a database are exactly the numbers that live up there.

Two ways keep it, and the second is the one to prefer:

```go
package main

import (
	"encoding/json"
	"fmt"
	"strings"
)

type User struct {
	ID int64 `json:"id"`
}

func main() {
	data := `{"id": 9007199254740993}`

	var doc map[string]any
	dec := json.NewDecoder(strings.NewReader(data))
	dec.UseNumber()
	if err := dec.Decode(&doc); err != nil {
		fmt.Println(err)
		return
	}
	fmt.Printf("%T %v\n", doc["id"], doc["id"])

	var u User
	if err := json.Unmarshal([]byte(data), &u); err != nil {
		fmt.Println(err)
		return
	}
	fmt.Printf("%T %v\n", u.ID, u.ID)
}
```

```
ana@vm:~/any-json-number$ go run .
json.Number 9007199254740993
int64 9007199254740993
```

`UseNumber` tells a decoder to keep each number as a `json.Number`, which is the number's text,
left for you to convert when you know what it should be. A struct does better: its `int64` field
told `Unmarshal` what to build, and the number arrived whole. **When you know the shape of a
document, decode it into a struct.** `map[string]any` is for the document you cannot describe, and
section 03 shows what it costs to read one.
