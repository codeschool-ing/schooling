---
title: Parameters: the name, then the type
version: 1
---

Somebody arriving from C, Java or C# writes a parameter as `int width`, type first. **Go writes it
the other way round: `width int`, the name and then its type.** The same order runs through the
whole language, in `var n int` from lesson 5 and in every parameter list, and it reads left to
right the way you would say it: width, an int. Here is a small program with four functions, in
`~/funcs`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc area(width int, height int) int {\n\treturn width * height\n}\n",
      "note": "**`func`, the name, the parameters in brackets, then the result type.** `area` takes two `int` and returns one. `return` hands the value back and ends the function."
    },
    {
      "code": "\nfunc perimeter(width, height int) int {\n\treturn 2 * (width + height)\n}\n",
      "note": "Neighbouring parameters of one type can share it: `width, height int` means both are `int`. This is the form most Go code uses."
    },
    {
      "code": "\nfunc label(name string, width, height int, unit string) string {\n\treturn fmt.Sprintf(\"%s: %d%s\", name, area(width, height), unit)\n}\n",
      "note": "Grouping works anywhere in the list. A type applies to the names written just before it, back to the previous type: `name` is a `string`, `width` and `height` are `int`, `unit` is a `string`."
    },
    {
      "code": "\nfunc ruler() {\n\tfmt.Println(\"----------\")\n}\n",
      "note": "No parameters and no result: empty brackets, and nothing after them. A function that returns nothing needs no `return` at all."
    },
    {
      "code": "\nfunc main() {\n\tfmt.Println(area(3, 4), perimeter(3, 4))\n\truler()\n\tfmt.Println(label(\"kitchen\", 3, 4, \" m2\"))\n}\n",
      "note": "A call passes the arguments in the order of the parameters, and every one of them: there are no names at the call site and nothing may be left out."
    }
  ],
  "output": "12 14\n----------\nkitchen: 12 m2"
}
```

The order of declaration does not matter. `label` calls `area`, which is above it, but `main` is
at the bottom and could equally be at the top: a function is visible in the whole package, the
package scope of lesson 6.

## Typed the C way

The compiler does not say "wrong order" when a parameter is written type first. It reads what you
wrote, and what you wrote is legal syntax that means something else:

```go
package main

import "fmt"

func area(int width, int height) int {
	return width * height
}

func main() {
	fmt.Println(area(3, 4))
}
```

```
ana@vm:~/funcs-c$ go run .
# example.com/funcs-c
./main.go:5:15: undefined: width
./main.go:5:22: int redeclared in this block
	./main.go:5:11: other declaration of int
./main.go:5:26: undefined: height
./main.go:6:9: undefined: width
./main.go:6:17: undefined: height
```

Read the errors with the rule in mind and each one makes sense. `int width` declares a parameter
**called** `int`, of a type called `width`, and there is no type called `width`. The second
`int height` declares another parameter called `int`, which is the redeclaration on line 5, column
22. `int` is a predeclared name and not a keyword, the point lesson 6 made about the universe
scope, so nothing stops a parameter from taking it. **When a list of errors makes no sense, check
whether a parameter was written type first.**

## No default values, no overloading

Two features that many languages have are missing on purpose. A parameter cannot have a default
value:

```go
package main

import "fmt"

func greet(name string, greeting string = "Hello") {
	fmt.Println(greeting+",", name)
}

func main() {
	greet("Ana")
}
```

```
ana@vm:~/funcs-default$ go run .
# example.com/funcs-default
./main.go:5:41: syntax error: unexpected = in parameter list; possibly missing comma or )
```

And two functions in one package cannot share a name, even with different parameters:

```go
package main

import "fmt"

func area(side int) int {
	return side * side
}

func area(width, height int) int {
	return width * height
}

func main() {
	fmt.Println(area(3), area(3, 4))
}
```

```
ana@vm:~/funcs-overload$ go run .
# example.com/funcs-overload
./main.go:9:6: area redeclared in this block
	./main.go:5:6: other declaration of area
./main.go:14:31: too many arguments in call to area
	have (number, number)
	want (int)
```

The second error follows from the first. The compiler kept the first `area`, the one with one
parameter, so the call `area(3, 4)` on line 14 is now a call with one argument too many.

What Go does instead is visible in the standard library. Where another language would have one
function with an optional argument, or three versions of one name, Go has several functions, each
with its own name and exactly the parameters it needs:

```
ana@vm:~/funcs-overload$ go doc strings | grep -E '^func (Index|IndexByte|IndexRune|Split|SplitN)\('
func Index(s, substr string) int
func IndexByte(s string, c byte) int
func IndexRune(s string, r rune) int
func Split(s, sep string) []string
func SplitN(s, sep string, n int) []string
```

`SplitN` is `Split` with the argument a default would have hidden, and `IndexByte` and `IndexRune`
are `Index` for the two other things you might look for. **In Go a name stands for one function,
so reading a call tells you exactly which code runs**, without working out which version the types
select.

## The arguments have to match

A call must pass exactly as many arguments as there are parameters, each of a type the parameter
accepts. The compiler checks every call:

```go
package main

import "fmt"

func area(width, height int) int {
	return width * height
}

func main() {
	fmt.Println(area(3))
	fmt.Println(area(3, 4, 5))
	fmt.Println(area(3, "4"))
}
```

```
ana@vm:~/funcs-args$ go run .
# example.com/funcs-args
./main.go:10:19: not enough arguments in call to area
	have (number)
	want (int, int)
./main.go:11:25: too many arguments in call to area
	have (number, number, number)
	want (int, int)
./main.go:12:22: cannot use "4" (untyped string constant) as int value in argument to area
```

`have` is what the call passed and `want` is the function's parameter list. `number` is how the
message describes an untyped constant like `3`, which can still become an `int` (lesson 5).
`"4"` is a string, and no conversion happens by itself, the rule lesson 10 was about.

One thing is allowed that you might expect to be refused. Lesson 5 showed a local variable that is
declared and never used stopping the build. **A parameter that is never used is not an error**:

```go
package main

import "fmt"

func area(width, height int, unit string) int {
	return width * height
}

func main() {
	fmt.Println(area(3, 4, "m2"))
}
```

```
ana@vm:~/funcs-unusedparam$ go vet && go run .
12
```

Neither the compiler nor `go vet` mentions `unit`. The parameter list is a contract with the
caller, and a function sometimes has to accept a value it does not need, because its signature
must match something else. Lesson 21 passes functions as values, where that happens all the time.

Every argument arrives as a copy of the value the caller passed. Lesson 11 showed what that means
for an array and a slice, and lesson 22 makes it the rule for every type.
