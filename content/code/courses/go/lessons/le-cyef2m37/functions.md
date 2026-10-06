---
title: Type parameter lists, and what inference can see
version: 1
---

Lesson 30 wrote one generic function with one type parameter. Most generic functions you will write
or read have more than one. A type parameter list works like an ordinary parameter list with types in
place of values: names, then what each may be, in square brackets between the function's name and
its ordinary parameters. `Map` below applies a function to every element of a slice, and it needs two
type parameters, because the elements going in and the elements coming out may differ. In
`~/generic2`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"strconv\"\n)\n\nfunc Map[T, U any](xs []T, f func(T) U) []U {\n",
      "note": "**Two type parameters, `T` and `U`, sharing one constraint.** `T, U any` is the same shorthand as `a, b int` in an ordinary list. The signature then ties them together: a `[]T` in, a function from `T` to `U`, a `[]U` out."
    },
    {
      "code": "\tout := make([]U, 0, len(xs))\n\tfor _, x := range xs {\n\t\tout = append(out, f(x))\n\t}\n\treturn out\n}\n",
      "note": "Inside the body `T` and `U` are types like any other: `make([]U, …)` builds a slice of whatever `U` is, the preallocation of lesson 12."
    },
    {
      "code": "\nfunc Make[T any](n int) []T {\n\treturn make([]T, n)\n}\n",
      "note": "A type parameter that appears **only in the result**. Remember that, because the next block of output depends on it."
    },
    {
      "code": "\nfunc main() {\n\tages := []int{41, 7, 23}\n\tlabels := Map(ages, strconv.Itoa)\n\tfmt.Printf(\"%q %T\\n\", labels, labels)\n",
      "note": "**Inference: the compiler reads the types off the arguments.** `ages` is a `[]int`, so `T` is `int`; `strconv.Itoa` is a `func(int) string`, so `U` is `string`. The result is a `[]string`."
    },
    {
      "code": "\n\thalves := Map(ages, func(n int) float64 { return float64(n) / 2 })\n\tfmt.Println(halves)\n",
      "note": "The same `Map`, the same `T`, a different `U`: the function literal (lesson 21) returns `float64`, so this call gives a `[]float64`."
    },
    {
      "code": "\n\tnames := Make[string](2)\n\tfmt.Printf(\"%q %T\\n\", names, names)\n",
      "note": "**Explicit instantiation: the type written in brackets at the call.** `Make` has no argument to read `T` from, so the caller says it."
    },
    {
      "code": "\n\ttoText := Map[int, string]\n\tfmt.Printf(\"%T\\n\", toText)\n}\n",
      "note": "Instantiating without calling. `Map[int, string]` is an ordinary function value with every type filled in, and `%T` prints its signature."
    }
  ],
  "output": "[\"41\" \"7\" \"23\"] []string\n[20.5 3.5 11.5]\n[\"\" \"\"] []string\nfunc([]int, func(int) string) []string"
}
```

Writing `Map[int, string]` gives the function with `T` set to `int` and `U` to `string`, and the
compiler does exactly that, invisibly, at every call in `main` that names no types. Filling in a
type parameter is called **instantiation**; inference is the compiler working out what to fill in.

## What inference cannot see

A common belief is that the compiler works the type out from wherever the result goes, so that
`var labels []string = Make(2)` tells it `T` is `string`. It does not. **Inference reads the arguments
of the call, and nothing outside the call.** The same two functions, in `~/generic2-infer`, with the
brackets left off:

```go
func main() {
	names := Make(2)
	var labels []string = Make(2)
	toText := Map
	fmt.Println(names, labels, toText)
}
```

```
ana@vm:~/generic2-infer$ go run .
# example.com/generic2-infer
./main.go:18:15: in call to Make, cannot infer T (declared at ./main.go:13:11)
./main.go:19:28: in call to Make, cannot infer T (declared at ./main.go:13:11)
./main.go:20:12: cannot use generic function Map without instantiation
```

`Make(2)` has one argument, an `int`, and `T` appears nowhere in the parameter list, so there is
nothing to infer it from, and the declared type of `labels` on line 19 does not help. The message
names the type parameter and points at line 13, column 11, where `T` was declared. The third error
is the same gap from another side. `Map` on its own is not a function you can hold, only a recipe
for one; storing it needs every type filled in, as `toText := Map[int, string]` did.

When `cannot infer` appears, the repair is the one `main` above used: write the types in brackets.
They go in the order the function declared them, and you may stop early. Calling `Map[int]` with `ages` and
`f` would fix `T` and still leave `U` to be read off `f`.

## Every use of `T` has to agree

Lesson 30's `ShowAll` was refused because a type parameter is one type per call. The rule holds for
numbers too, and there it catches people out. This is the `Biggest` of lesson 2, in
`~/generic2-mix`:

```go
package main

import "fmt"

func Biggest[T int | float64](a, b T) T {
	if a > b {
		return a
	}
	return b
}

func main() {
	top := Biggest(3, 2.5)
	fmt.Printf("%v %T\n", top, top)

	var count int = 3
	var price float64 = 2.5
	fmt.Println(Biggest(count, price))
}
```

```
ana@vm:~/generic2-mix$ go run .
# example.com/generic2-mix
./main.go:18:29: in call to Biggest, type float64 of price does not match inferred type int for T
```

Line 18 was refused and line 13 was not, and the difference is lesson 5's untyped constants. `3` and
`2.5` have no type of their own yet, so the compiler is free to pick one that fits both, and it picks
`float64`. `count` and `price` are typed variables. The first fixed `T` as `int`, the second disagreed,
and **Go converts nothing on your behalf, generic or not**, which is lesson 10's rule. With the call
changed to `Biggest(float64(count), price)`, the conversion written where it can be seen, both lines
run:

```
ana@vm:~/generic2-mix$ go run .
3 float64
3
```

`%T` confirms what the compiler chose for the constants: `T` was `float64`, and a whole `float64`
prints without a decimal point. The second line is the same comparison, made between two values that
were declared with different types and had to be brought to one by hand.
