---
title: Several results, and the one you discard
version: 1
---

In most languages a function returns one value, and a function that needs to hand back two packs
them into an object, an array or a tuple first. **A Go function can return several values
directly**, and the results are listed in brackets after the parameters. Nothing is packed:
the caller receives them as separate values and gives each one a name.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"strconv\"\n\t\"unicode/utf8\"\n)\n\nfunc divmod(a, b int) (int, int) {\n\treturn a / b, a % b\n}\n",
      "note": "**Two result types in brackets, and a `return` with two values separated by a comma.** `divmod` gives back the quotient and the remainder of an integer division, both from one call."
    },
    {
      "code": "\nfunc main() {\n\tq, r := divmod(17, 5)\n\tfmt.Println(q, r)\n",
      "note": "The caller names both results on the left of `:=`, in the same order: `q` is 3 and `r` is 2."
    },
    {
      "code": "\tfmt.Println(divmod(17, 5))\n",
      "note": "A call with several results can be passed straight to another function when it fills that function's parameters exactly. `fmt.Println` accepts any number of values, so it prints both."
    },
    {
      "code": "\n\tn, err := strconv.Atoi(\"42\")\n\tfmt.Println(n, err)\n\tn, err = strconv.Atoi(\"42x\")\n\tfmt.Println(n, err)\n",
      "note": "**The shape you will meet most: a value and an `error`.** `strconv.Atoi` turns text into an `int`. When it works, `err` is `nil`; when it cannot, `n` is 0 and `err` says why."
    },
    {
      "code": "\n\tch, size := utf8.DecodeRuneInString(\"épée\")\n\tfmt.Printf(\"%c %d\\n\", ch, size)\n}\n",
      "note": "The call lesson 9 used: the first rune of the string and how many bytes it took, `é` and 2."
    }
  ],
  "output": "3 2\n3 2\n42 <nil>\n0 strconv.Atoi: parsing \"42x\": invalid syntax\né 2"
}
```

`(T, error)` is how Go reports failure. There are no exceptions to throw and catch: a function
that can fail returns an `error` as its last result, and `nil` means it did not fail. The two
lines for `"42"` and `"42x"` show both sides of that contract. **Read the error before you trust
the value**, because a failed `Atoi` still hands back a number, and 0 looks like a perfectly good
one. Lessons 32 to 35 are about errors: what the type is, how to check it and how to add context.
This section only needs the shape.

## Two results do not fit in one place

A multi-result call is not one value holding two. It is two values, and the compiler refuses
every place that has room for only one:

```go
package main

import (
	"fmt"
	"strconv"
)

func divmod(a, b int) (int, int) {
	return a / b, a % b
}

func main() {
	q := divmod(17, 5)
	fmt.Println("17 / 5 is", divmod(17, 5))
	n := strconv.Atoi("42")
	fmt.Println(q, n)
}
```

```
ana@vm:~/funcs-mismatch$ go run .
# example.com/funcs-mismatch
./main.go:13:7: assignment mismatch: 1 variable but divmod returns 2 values
./main.go:14:27: multiple-value divmod(17, 5) (value of type (int, int)) in single-value context
./main.go:15:7: assignment mismatch: 1 variable but strconv.Atoi returns 2 values
```

The first and third errors are the same mistake: one name on the left, two values on the right.
The second is the one that surprises. `fmt.Println(divmod(17, 5))` worked in the program above,
and adding a string in front of it broke it. **A multi-result call can be spread over a function's
arguments only when it is the whole argument list.** Mixed with anything else, it has to be put in
variables first. The type the message prints, `(int, int)`, is a list of results and not a type
you can declare a variable of. Go has no tuples.

The third error is the one that protects you. Writing `n := strconv.Atoi("42")` is what somebody
does when they forget that the conversion can fail, and Go makes forgetting impossible to compile.

## The blank identifier: discarding on purpose

Sometimes you do want only one result. Every name on the left of `:=` has to be used, as lesson 5
showed for variables, so naming a result you then ignore stops the build:

```go
package main

import "fmt"

func divmod(a, b int) (int, int) {
	return a / b, a % b
}

func main() {
	q, r := divmod(17, 5)
	fmt.Println(q)
}
```

```
ana@vm:~/funcs-unread$ go run .
# example.com/funcs-unread
./main.go:10:5: declared and not used: r
```

The answer is `_`, the **blank identifier**. It holds a place on the left of an assignment and
throws the value away. It is not a variable, and you can write it as many times as you need:

```go
package main

import (
	"fmt"
	"strconv"
)

func divmod(a, b int) (int, int) {
	return a / b, a % b
}

func main() {
	_, r := divmod(17, 5)
	fmt.Println(r)

	n, _ := strconv.Atoi("42x")
	fmt.Println(n + 1)
}
```

```
ana@vm:~/funcs-blank$ go run .
2
1
```

The first `_` is harmless: the remainder was all that was wanted. The second is the reason `_`
deserves care. `"42x"` is not a number, `Atoi` said so in its error, the `_` threw the error away,
and the program carried on with 0 and printed 1 as if nothing had happened. **Discarding an
`error` with `_` is a decision that the failure cannot happen or does not matter, and it should
be written only when you can say which.** Lesson 12 did it for `json.Marshal` on a slice of
strings: the failures its documentation lists are channels, functions, complex numbers, NaN and
cycles, and a slice of strings holds none of them.

## Every path must return

A function with results has to end every path through it with a `return`. The compiler checks
the paths, and it does not reason about values to do it:

```go
package main

import "fmt"

func sign(n int) string {
	if n < 0 {
		return "negative"
	}
	if n > 0 {
		return "positive"
	}
}

func main() {
	fmt.Println(sign(-3))
}
```

```
ana@vm:~/funcs-missing$ go run .
# example.com/funcs-missing
./main.go:12:1: missing return
```

When `n` is 0, neither `if` returns, and the function reaches its closing brace, line 12, with
nothing to hand back. Go does not return a zero value by default there; it refuses to compile
until the zero case says what it returns.
