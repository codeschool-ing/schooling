---
title: The type switch
version: 1
---

Section 03 asked one question per assertion. A value that might be any of six types would need six
assertions in a row, each with its own `ok`. **A `type switch` asks all of them at once: its cases
are types, and the first one that matches the value's dynamic type runs.** Lesson 19's `switch`
compared values; this one compares types, and it is the tool for walking the `map[string]any` of
lesson 28. The same document, every value printed with what it turned out to be:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"encoding/json\"\n\t\"fmt\"\n\t\"maps\"\n\t\"slices\"\n\t\"strings\"\n)\n\nfunc walk(x any, depth int) {\n\tpad := strings.Repeat(\"  \", depth)\n",
      "note": "`walk` takes `any` because a decoded document can be anything at any depth. `depth` only sets the indent."
    },
    {
      "code": "\tswitch v := x.(type) {\n\tcase nil:\n\t\tfmt.Println(pad + \"null\")\n",
      "note": "**`switch v := x.(type)` is a switch whose cases are types.** In each case `v` is `x` converted to that case's type. `case nil` matches an interface holding nothing, which is what `Unmarshal` stores for `null`."
    },
    {
      "code": "\tcase bool:\n\t\tfmt.Println(pad+\"bool\", v)\n\tcase float64:\n\t\tfmt.Println(pad+\"number\", v)\n\tcase string:\n\t\tfmt.Printf(\"%sstring %q\\n\", pad, v)\n",
      "note": "Here `v` is a `bool`, a `float64` and a `string` in turn, so each case can use it as one: `%q` on a string, with no assertion written anywhere."
    },
    {
      "code": "\tcase []any:\n\t\tfmt.Println(pad+\"array of\", len(v))\n\t\tfor _, e := range v {\n\t\t\twalk(e, depth+1)\n\t\t}\n",
      "note": "An array arrives as `[]any`, and `v` is that slice: `len(v)` and `range v` compile here and nowhere else in the function. Each element goes back into `walk`."
    },
    {
      "code": "\tcase map[string]any:\n\t\tfmt.Println(pad+\"object of\", len(v))\n\t\tfor _, k := range slices.Sorted(maps.Keys(v)) {\n\t\t\tfmt.Println(pad + \"  \" + k + \":\")\n\t\t\twalk(v[k], depth+2)\n\t\t}\n",
      "note": "An object arrives as `map[string]any`. The keys are sorted with lesson 14's `slices.Sorted(maps.Keys(v))`, because a map's order changes between runs."
    },
    {
      "code": "\tdefault:\n\t\tfmt.Printf(\"%sunexpected %T\\n\", pad, v)\n\t}\n}\n\n",
      "note": "`default` takes every type no case named. `Unmarshal` never produces one, so this line is the program saying that something it did not expect arrived."
    },
    {
      "code": "func main() {\n\tdata := []byte(`{\"name\": \"Ana\", \"age\": 31, \"admin\": false,\n\t\t\"tags\": [\"go\", \"sql\"], \"boss\": null}`)\n\n\tvar doc any\n\tif err := json.Unmarshal(data, &doc); err != nil {\n\t\tfmt.Println(err)\n\t\treturn\n\t}\n\twalk(doc, 0)\n}\n",
      "note": "`doc` is a plain `any` this time, not a map, since a JSON document does not have to be an object."
    }
  ],
  "output": "object of 5\n  admin:\n    bool false\n  age:\n    number 31\n  boss:\n    null\n  name:\n    string \"Ana\"\n  tags:\n    array of 2\n      string \"go\"\n      string \"sql\""
}
```

Read the output against the source. `doc` was an object, so the `map[string]any` case ran and
printed five keys in sorted order. `age` came out as `number 31` from the `float64` case, which is
the type lesson 28 said every JSON number becomes. `boss` matched `case nil`, and `tags` matched
`[]any` and sent its two strings back into `walk`, one level deeper.

The variable is what makes this better than a chain of assertions. **Inside each case, `v` has the
type that case names**, so the `string` case can pass it to `%q`, and the `[]any` case can take its
length and range over it. There is one `v` per case, declared by the `switch` line, and not one
`.(T)` anywhere else in the function.

## When a case names more than one type

A case can list several types, the way a value switch lists several values. Then `v` cannot have
all of them at once:

```go
package main

import "fmt"

func kind(x any) string {
	switch v := x.(type) {
	case nil:
		return "nothing"
	case int, float64:
		return fmt.Sprintf("a number held as %T", v)
	case string:
		return fmt.Sprintf("a string of %d bytes", len(v))
	default:
		return fmt.Sprintf("something else: %T", v)
	}
}

func main() {
	var p *int
	for _, x := range []any{nil, 3, 2.5, "olá", p, []int{1}} {
		fmt.Println(kind(x))
	}
}
```

```
ana@vm:~/assert-kind$ go run .
nothing
a number held as int
a number held as float64
a string of 4 bytes
something else: *int
something else: []int
```

In `case int, float64`, `v` keeps the type of `x`, which is `any`. `%T` still prints `int` or
`float64`, because `%T` reports the dynamic type, but the compiler sees an `any` and allows nothing
more. Trying to do arithmetic in such a case shows it:

```go
package main

import "fmt"

func double(x any) any {
	switch v := x.(type) {
	case int, float64:
		return v * 2
	case string:
		fallthrough
	default:
		return nil
	}
}

func main() {
	fmt.Println(double(3))
}
```

```
ana@vm:~/assert-kind-bad$ go build
# example.com/double
./main.go:8:10: invalid operation: v * 2 (mismatched types any and untyped int)
./main.go:10:3: cannot fallthrough in type switch
```

`mismatched types any and untyped int` is the compiler saying what `v` is in that case. The fix is
one case per type, each with its own arithmetic. The second error keeps a promise of lesson 19:
`fallthrough` is refused in a type switch, because the next case would receive a `v` of a different
type.

Two lines of the `kind` output are about nil. `case nil` matched the first element, an interface
holding nothing. The fifth element was a nil `*int`, and it went to `default` as
`something else: *int`. **`case nil` matches only an interface with no type in it, the same rule as
`== nil` in lesson 28**, and a nil pointer inside an interface still has a type.

## The order of the cases is part of the meaning

Cases are tried from the top, and a value can match more than one when a case names an interface.
`fmt` relies on that order. Whenever it prints a value with `%v`, `%s` or one of three other verbs,
it runs a type switch to decide whether the value has a method that describes itself. Here is a type with both of the
methods it looks for, and the lines of `fmt` that choose between them:

```go
package main

import "fmt"

type Both struct{}

func (Both) Error() string  { return "from Error" }
func (Both) String() string { return "from String" }

func main() {
	fmt.Println(Both{})
}
```

```
ana@vm:~/assert-fmt$ sed -n 656,668p /usr/local/go/src/fmt/print.go
			switch v := arg.(type) {
			case error:
				handled = true
				defer p.catchPanic(arg, verb, "Error")
				p.fmtString(arg, value, v.Error(), verb)
				return

			case Stringer:
				handled = true
				defer p.catchPanic(arg, verb, "String")
				p.fmtString(arg, value, v.String(), verb)
				return
			}
ana@vm:~/assert-fmt$ go run .
from Error
```

`error` is checked before `Stringer`, so a type with both methods prints its `Error`. `Both` has an
`Error` and a `String`, and `fmt.Println` printed `from Error`. This switch is also why a `String`
method changes what `fmt` prints for your type: `fmt` asks every value it prints that way whether
it is a `Stringer`, and a type with a `String() string` method is one, without declaring anything.

So the three tools of this lesson fit together. An interface built by embedding says which methods
a value must have. An assertion asks whether one value has a particular type or a particular extra
method. A `type switch` asks the same question of a list of types, and gives each case a `v` of the
type it found.
