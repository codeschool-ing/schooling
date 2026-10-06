---
title: Pointers to structs
version: 1
---

Most of the pointers in a Go program point at structs. A function that has to change a struct
takes a pointer to it, and code that builds a struct often wants its address straight away. Go
makes both short enough that a reader from C may not notice a pointer is there at all, because
**there is no `->`: the dot works on a struct and on a pointer to one alike.**

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\ntype Player struct {\n\tName  string\n\tScore int\n}\n\nfunc win(p *Player) {\n\tp.Score++\n}\n",
      "note": "Lesson 22's `win` took a `Player` and changed a copy. This one takes a `*Player`. **`p.Score` on a pointer follows the pointer for you**: it means `(*p).Score`, and nobody writes the long form."
    },
    {
      "code": "\nfunc main() {\n\tana := Player{Name: \"Ana\", Score: 10}\n\twin(&ana)\n\tfmt.Println(ana)\n",
      "note": "`win(&ana)` hands over the address of `ana`, and the caller's player now has 11."
    },
    {
      "code": "\n\tbia := &Player{Name: \"Bia\"}\n\twin(bia)\n\tfmt.Println(bia, bia.Score, (*bia).Score)\n",
      "note": "**`&Player{...}` makes a struct and gives you its address in one expression**, so `bia` is a `*Player`. `fmt.Println` prints a pointer to a struct as the struct with `&` in front, `&{Bia 1}`, and both spellings of the field read 1."
    },
    {
      "code": "\n\tcarla := new(Player)\n\tcarla.Name = \"Carla\"\n\tfmt.Println(*carla)\n",
      "note": "`new(Player)` makes a `Player` with every field at its zero value and returns its address, the same as `&Player{}`."
    },
    {
      "code": "\n\ttwin := &Player{Name: \"Bia\", Score: 1}\n\tfmt.Println(bia == twin, *bia == *twin)\n}\n",
      "note": "**`==` on two pointers asks whether they lead to the same variable**, not whether the values behind them match. `bia == twin` is `false`; `*bia == *twin` compares the structs and is `true`."
    }
  ],
  "output": "{Ana 11}\n&{Bia 1} 1 1\n{Carla 0}\nfalse true"
}
```

```
ana@vm:~/pointers-struct$ go run .
{Ana 11}
&{Bia 1} 1 1
{Carla 0}
false true
```

Three ways to get a `*Player` appeared in that program: `&ana` for a variable that already exists,
`&Player{...}` for a struct made on the spot, and `new(Player)` for a zero one, which says the same
thing as `&Player{}`. The shorthand of the dot reaches arrays too. Lesson 13 indexed a `*[4]int` as `p[0]`,
which is `(*p)[0]` written short.

The last line is the one to keep. `bia` and `twin` hold equal players and are different pointers,
so `bia == twin` is `false`. **Comparing pointers compares addresses**; to compare what they point
at, follow both, as `*bia == *twin` did.

## A pointer to a value that has no variable

A pointer field is the usual way to say that a value may be absent: `nil` means "not given", and
anything else is the value. Filling one in used to take two lines, because `&` needs a variable
and a constant is not one:

```go
package main

import "fmt"

type Options struct {
	Limit *int
}

func describe(o Options) string {
	if o.Limit == nil {
		return "no limit"
	}
	return fmt.Sprint("limit ", *o.Limit)
}

func main() {
	fmt.Println(describe(Options{}))
	fmt.Println(describe(Options{Limit: &10}))
}
```

```
ana@vm:~/pointers-new$ go run .
# example.com/options
./main.go:18:39: invalid operation: cannot take address of 10 (untyped int constant)
```

`new` takes an expression as well as a type, and `new(10)` makes an `int` holding 10 and returns
its address:

```go
	fmt.Println(describe(Options{Limit: new(10)}))
```

```
ana@vm:~/pointers-new$ go run .
no limit
limit 10
ana@vm:~/pointers-new$ go mod edit -go=1.25 && go run .
# example.com/options
./main.go:18:38: new(10) requires go1.26 or later (-lang was set to go1.25; check go.mod)
```

**`new(expr)` is Go 1.26 and later.** The second command set the module's `go` line back to 1.25,
and the compiler answered with the version the feature needs; lesson 2 showed that line choosing
which language a module is compiled as. In a module whose `go` line is older than that, the same field is filled with
a variable first: `n := 10`, then `Limit: &n`. `go doc builtin.new` describes both forms.

## When a struct is passed by pointer

Two reasons justify the pointer, and lesson 22 named both. The function has to change the caller's
struct, like `win`; or the struct is large enough for the copy to cost something. Lesson 22 measured
that: a 16-byte struct was copied inside the cost of the call itself, and a 1,024-byte one took
15.51 ns. Everything else is passed by value, which
keeps the caller's struct out of the function's reach. The same choice comes back for methods,
where a pointer receiver is how a method changes the value it was called on: lesson 26 is about
that choice.
