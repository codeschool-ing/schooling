---
title: When a type parameter is the wrong tool
version: 1
---

Once a language has generics, a common reflex is to make every function generic that could be, on the
grounds that it costs nothing and might help one day. **It costs something on every line**: a generic
signature is harder to read than a plain one, and a type parameter that only ever stands for one type
is that cost paid for nothing. Lesson 14 met this signature:

```
ana@vm:~/generics-std$ go doc maps.Keys | head -3
package maps // import "maps"

func Keys[Map ~map[K]V, K comparable, V any](m Map) iter.Seq[K]
```

Three type parameters and two constraints, so that one `Keys` serves every map in every program.
For the standard library, which thousands of programs call, that is a good trade. A function in your
own program, called from two places with a `map[string]int`, is clearer as
`func keys(m map[string]int) []string`.

So the order of work is the one section 02 followed. **Write the function for the type you have.**
When a second copy appears and the `diff` between the two shows only types, as it did for `SumInts`
and `SumFloats`, that is the moment to write `Sum[T]`. The duplication is the evidence, and without it
the type parameter is a guess about the future.

## Containers and algorithms, or behaviour

The useful line runs between two kinds of code.

**Generic code does the same thing whatever the type is.** Adding up, sorting, searching a slice,
collecting a map's keys: the code moves values around and compares them, and never asks what they
are. A **container** is the second case: a stack, a queue, a cache, any structure that holds values of
one type and gives them back. Lesson 31 builds a `Stack[T]`.

**Interface code does something different for each type.** A function that writes to an
`io.Writer` does not care whether the bytes land in a file or a buffer; it calls `Write` and the type
decides what that means. That is behaviour, and lesson 27 showed interfaces are the tool for it.

The two look alike when a constraint has a method in it, because an interface can be a constraint
too. `~/generics-when` writes the same function both ways: once with a type parameter constrained
by `fmt.Stringer`, once with a plain `fmt.Stringer` parameter. It calls each with two types that
both have a `String` method, lesson 10's `Celsius`, given one of its own here, and a
`time.Duration`.

```go
package main

import (
	"fmt"
	"time"
)

type Celsius float64

func (c Celsius) String() string {
	return fmt.Sprintf("%.1fC", float64(c))
}

func ShowAll[T fmt.Stringer](items ...T) {
	for _, it := range items {
		fmt.Println(it.String())
	}
}

func ShowEach(items ...fmt.Stringer) {
	for _, it := range items {
		fmt.Println(it.String())
	}
}

func main() {
	room := Celsius(21.5)
	wait := 90 * time.Second
	ShowEach(room, wait)
	ShowAll(room, wait)
}
```

```
ana@vm:~/generics-when$ go run .
# example.com/generics-when
./main.go:30:16: in call to ShowAll, type time.Duration of wait does not match inferred type Celsius for T
```

`ShowEach` had no complaint. `ShowAll` did, and the message says why: **a type parameter stands for
one type per call**. The compiler took `T` to be `Celsius` from the first argument, and then `wait`
was a different type. For `Sum` that rule is exactly right, because adding a `Celsius` to a
`time.Duration` is the unit mistake lesson 10 made impossible. For printing, it is a restriction with
no purpose: the function only calls `String`, and both types have one.

With the last call changed to `ShowAll(room, room+1)`, two values of one type, both functions run:

```
ana@vm:~/generics-when$ go run .
21.5C
1m30s
21.5C
22.5C
```

`ShowAll` is no more capable than `ShowEach` and accepts less. **When the body only calls methods,
the plain interface says the same thing with fewer brackets and accepts more callers.**

Three signs that a type parameter is not earning its place:

- it appears once in the signature, as the type of one parameter. `func F[T fmt.Stringer](v T)` does
  the job of `func F(v fmt.Stringer)`;
- every caller in the program uses the same type for it;
- the body asks what the type is, with a type switch on the value. That is the `SumAny` of section 02
  again, and it gives back the run-time checking that type parameters exist to remove.

And the signs that it is: a container that holds values of a type the caller picks, or an algorithm
over slices, maps or values that would otherwise be copied once per type. In both, the type parameter
appears more than once, linking an argument to another argument or to the result, as `T` linked the
`[]T` going into `Sum` to the `T` coming out.
