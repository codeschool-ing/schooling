---
title: Declaring, filling and comparing a struct
version: 1
---

Programmers arriving from Java or Python tend to read a struct as a class with the methods left
out. Lesson 1 said Go has no classes, and a struct is not trying to be one. **A struct is a value
made of named fields, each with its own type, and nothing else**: no constructor runs when one is
made, and copying it copies the fields. Methods on a type are lesson 25, and they do not live in
the struct's declaration either.

Lesson 14 kept values under keys that a program chooses at run time. A struct's fields are the
opposite: their names are fixed in the source, and the compiler checks every use of one.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\ntype Point struct {\n\tX, Y int\n}\n\ntype Book struct {\n\tTitle  string\n\tAuthor string\n\tPages  int\n\tTags   []string\n}\n",
      "note": "**`type Name struct { … }` declares a new type with a field per line**, the name first and the type after it. Fields of one type can share a line, as `X, Y int` does. The extra spaces lining up `Book`'s types are `gofmt`'s doing."
    },
    {
      "code": "\nfunc main() {\n\tp := Point{X: 3, Y: 4}\n\tq := Point{3, 4}\n\tvar origin Point\n\tfmt.Println(p, q, origin, p == q)\n",
      "note": "Three ways to get a `Point`. **A literal with field names** says which value goes where. A literal without them fills the fields in declaration order. `var` gives the zero value, every field at its own zero, as lesson 6 showed. Two structs are equal when every field is."
    },
    {
      "code": "\n\tp.X = 10\n\tfmt.Println(p.X, p, p == q)\n",
      "note": "A field is read and written with a dot. Changing `p.X` changes `p` only: `q` was a separate value from the start, so the two are no longer equal."
    },
    {
      "code": "\n\tb := Book{Title: \"Dom Casmurro\", Author: \"Machado de Assis\"}\n\tfmt.Printf(\"%v\\n%+v\\n\", b, b)\n}\n",
      "note": "**Fields a literal does not name are left at their zero value**, here `Pages` and `Tags`. `%v` prints the values alone, which is hard to read once a struct has a few fields; `%+v` puts each field's name in front of its value."
    }
  ],
  "output": "{3 4} {3 4} {0 0} true\n10 {10 4} false\n{Dom Casmurro Machado de Assis 0 []}\n{Title:Dom Casmurro Author:Machado de Assis Pages:0 Tags:[]}"
}
```

`Tags` printed as `[]`, and it is a nil slice: nobody gave it a value. Lesson 12 showed that `fmt`
cannot tell a nil slice from an empty one, and section 02 shows somebody who can.

## Name the fields

`Point{3, 4}` is shorter than `Point{X: 3, Y: 4}`, and it is fine for a type of your own with two
fields that will never change. For a struct from another package it is a trap. The package may add a field,
even an unexported one, and every literal that relied on the order then stops compiling, in your
code, after an upgrade you did not write. `go vet` reports it:

```go
package main

import (
	"fmt"
	"net"
)

func main() {
	addr := net.TCPAddr{net.IPv4(127, 0, 0, 1), 8080, ""}
	fmt.Println(addr.String())
}
```

```
ana@vm:~/structs-unkeyed$ go run .
127.0.0.1:8080
ana@vm:~/structs-unkeyed$ go vet; echo $?
main.go:9:10: net.TCPAddr struct literal uses unkeyed fields
1
```

The program works today. Nobody reading it can tell what `""` is without opening the documentation
of `net.TCPAddr`, which is the other half of vet's point. **Write field names in every struct
literal of a type you did not declare**, and in most of the ones you did.

## When `==` is refused

`p == q` compared two `Point`s field by field. That works only when every field can be compared,
and the rule is the one lesson 14 gave for map keys:

```go
package main

import "fmt"

type Book struct {
	Title string
	Tags  []string
}

func main() {
	a := Book{Title: "Dom Casmurro"}
	b := Book{Title: "Dom Casmurro"}
	fmt.Println(a == b)
}
```

```
ana@vm:~/structs-eq$ go run .
# example.com/eq
./main.go:13:14: invalid operation: a == b (struct containing []string cannot be compared)
```

**A struct is comparable exactly when all its fields are.** One slice field is enough to lose
`==`, and with it the right to be a map key. Lesson 14 promised that structs with comparable fields
can be keys, and a `Point` is the natural example: a position on a grid, counted every time a path
passes through it.

```go
package main

import "fmt"

type Point struct {
	X, Y int
}

func main() {
	path := []Point{{0, 0}, {0, 1}, {1, 1}, {0, 1}, {0, 0}, {0, 1}}
	visits := map[Point]int{}
	for i := 0; i < len(path); i++ {
		visits[path[i]]++
	}
	fmt.Println(visits)
	fmt.Println(visits[Point{X: 0, Y: 1}], visits[Point{X: 5, Y: 5}])
}
```

```
ana@vm:~/structs-key$ go run .
map[{0 0}:2 {0 1}:3 {1 1}:1]
3 0
```

Inside `[]Point{…}` the elements can drop the type name and write `{0, 1}` alone, since the slice's
type already says what they are. The counting is lesson 14's `m[k]++`, with a whole struct as the
key: `{0 1}` was passed three times, and `{5 5}`, never visited, reads as the zero count.

## A struct with no name

A struct type can be written where it is used, with no `type` declaration. That is an **anonymous
struct**, and it suits a value needed in one place only:

```go
package main

import "fmt"

func main() {
	origin := struct {
		Lat, Lon float64
	}{-23.55, -46.63}
	fmt.Printf("%+v\n", origin)

	cases := []struct {
		name string
		want int
	}{
		{"ana", 3},
		{"bruno", 5},
		{"jo", 3},
	}
	for i := 0; i < len(cases); i++ {
		got := len(cases[i].name)
		fmt.Println(cases[i].name, got, got == cases[i].want)
	}
}
```

```
ana@vm:~/structs-anon$ go run .
{Lat:-23.55 Lon:-46.63}
ana 3 true
bruno 5 true
jo 2 false
```

The second one is the shape you will see most: a slice of anonymous structs used as a table, one
row per case, each with an input and the answer expected. The last row is wrong on purpose, and the
program says so. Tests for `go test` are often laid out as exactly this table, and testing is the `go-concurrency`
course's subject. When the same shape is needed in two places, give it a name with
`type`.
