---
title: What the type was doing for you
version: 1
---

Putting a value into an `any` costs nothing to write. The cost arrives when you want the value
back: **the moment a value goes into an `any`, the compiler stops knowing its type**, and every
check it used to make for you becomes your job, done while the program runs.

## Getting the value back

The `age` of section 02's document is inside a `map[string]any`. To add one to it, you have to say
what type you expect to find, with a **type assertion**: `x.(T)` asserts that the interface `x`
holds a `T`, and gives you that `T`. If it holds something else, the program stops:

```go
package main

import (
	"encoding/json"
	"fmt"
)

func main() {
	var doc map[string]any
	if err := json.Unmarshal([]byte(`{"name": "Ana", "age": 31}`), &doc); err != nil {
		fmt.Println(err)
		return
	}

	age := doc["age"].(float64)
	fmt.Println("next year:", age+1)

	years := doc["age"].(int)
	fmt.Println("next year:", years+1)
}
```

```
ana@vm:~/any-age$ go run .
next year: 32
panic: interface conversion: interface {} is float64, not int

goroutine 1 [running]:
main.main()
	/home/ana/any-age/main.go:18 +0x257
exit status 2
```

`doc["age"].(float64)` gave back a `float64`, and `age+1` compiled because `age` has a type again.
`doc["age"].(int)` compiled too, since the compiler cannot know what a map of `any` will hold when
the program runs. At run time it held a `float64`, and the program **panicked** on line 18 with a
message naming both types, `interface {} is float64, not int`. Somebody who reads `31` in the JSON
and thinks of an `int` writes exactly this line, and it passes every check before it runs.

A panic stops the program with exit status 2, which lesson 36 is about. Lesson 29 shows the two
forms that ask instead of insisting: the assertion that answers `false` when the type is wrong, and
the `type switch`.

## What the compiler refuses

Without an assertion, an `any` cannot be used as the value it holds, even where it obviously holds
a number:

```go
package main

import "fmt"

func main() {
	var a, b any = 2, 3
	fmt.Println(a + b)

	var s any = "Ana"
	fmt.Println(len(s))

	var n int = a
	fmt.Println(n)
}
```

```
ana@vm:~/any-ops$ go build
# example.com/ops
./main.go:7:14: invalid operation: operator + not defined on a (variable of interface type any)
./main.go:10:18: invalid argument: s (variable of interface type any) for built-in len
./main.go:12:14: cannot use a (variable of interface type any) as int value in variable declaration: need type assertion
```

`+` is defined for numbers and strings, and an `any` might be either or neither, so the compiler
allows it on none. `len` works on strings, slices, maps and a few other kinds of value, and the
same reasoning refuses it. The
third message names the way out itself: `need type assertion`. **An `any` supports what every Go
value supports and nothing more**: being assigned, passed, printed by `fmt`, and compared with
`==`, and the last one has a catch of its own below.

## The mistake moves from compile time to run time

Here is a function that adds up numbers, written to take `any` so that it accepts anything:

```go
package main

import "fmt"

func sum(xs []any) float64 {
	total := 0.0
	for _, x := range xs {
		total += x.(float64)
	}
	return total
}

func main() {
	fmt.Println(sum([]any{1.5, 2.5}))
	fmt.Println(sum([]any{1.5, 2}))
}
```

```
ana@vm:~/any-sum$ go vet && go run .
4
panic: interface conversion: interface {} is int, not float64

goroutine 1 [running]:
main.sum(...)
	/home/ana/any-sum/main.go:8
main.main()
	/home/ana/any-sum/main.go:15 +0x16b
exit status 2
```

`go vet` passed and the first call worked. The second crashed on a `2`. That `2` is an untyped
constant, and lesson 5 showed that an untyped constant takes its **default type** when nothing asks
for another: a whole number becomes an `int`. An `any` asks for nothing, so an `int` is what went
in, and the assertion to `float64` failed. The trace has two frames, `sum` where it panicked and
`main` where `sum` was called; lesson 37 reads traces like this one line by line.

The same function with the type written down:

```go
package main

import "fmt"

func sum(xs []float64) float64 {
	total := 0.0
	for _, x := range xs {
		total += x
	}
	return total
}

func main() {
	fmt.Println(sum([]float64{1.5, 2.5}))
	fmt.Println(sum([]float64{1.5, 2}))
	fmt.Println(sum([]float64{1.5, "2"}))
}
```

```
ana@vm:~/any-sum-typed$ go build
# example.com/sum
./main.go:16:33: cannot use "2" (untyped string constant) as float64 value in array or slice literal
```

Line 15 is now fine: the slice asks for `float64`, so the untyped `2` becomes `2.0` on the way in.
And a string in the list, which the `any` version would have accepted and crashed on, is refused
before the program exists, with its line and column. **The typed version finds the mistake on your
machine; the `any` version finds it wherever the program happens to be running when that input
arrives.**

## `==` compiles and can still panic

Two interface values are equal when they hold the same dynamic type and equal values. Both halves
matter:

```go
package main

import "fmt"

func main() {
	var a, b any = 1, 1
	fmt.Println(a == b)

	var c, d any = 1, 1.0
	fmt.Println(c == d)

	var e, f any = []int{1}, []int{1}
	fmt.Println(e == f)
}
```

```
ana@vm:~/any-compare$ go run .
true
false
panic: runtime error: comparing uncomparable type []int

goroutine 1 [running]:
main.main()
	/home/ana/any-compare/main.go:13 +0x115
exit status 2
```

`1` and `1.0` are the same number and not the same value here: one went in as an `int` and the
other as a `float64`, so the comparison is false. The third comparison is the cost again. Lesson 11
showed the compiler refusing `==` between two slices. Inside an `any` it cannot see the slices, so
the program compiled, and the refusal came at run time as a panic.

## When to reach for `any`

The standard library takes `any` where a function really does accept every type and decides what
to do with each at run time: `fmt` prints anything, `json.Unmarshal` fills anything. Two other
tools cover most of the cases that look like `any` at first:

| what you want | the tool | where |
|---|---|---|
| one function that does the same thing for several types, like `sum` over `int` or `float64` | generics: `Sum[T]`, checked at every call | lesson 30 |
| several types that share a behaviour, like everything that can be written to | an interface with methods, like `io.Writer` | lesson 27 |
| a value of a type nobody knew when the program was written | `any`, and an assertion or a `type switch` to read it | lesson 29 |

**Start with the concrete type**, and give it up only when you can say what you get in exchange.
