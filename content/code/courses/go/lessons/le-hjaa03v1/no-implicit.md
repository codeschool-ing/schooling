---
title: Two numbers that will not add
version: 1
---

Most languages you may have met convert numbers quietly when two of different types meet. C turns
an `int` into a `long` before adding them, Java widens an `int` to a `double`, JavaScript has only
one kind of number to begin with. The habit that leaves behind is to expect any two numbers to
add. **Go does not convert a value from one type to another unless you write the conversion**,
and the first time you meet that rule it looks like the compiler being difficult.

Here are three variables of three numeric types, and two lines that combine them:

```go
package main

import "fmt"

func main() {
	var count int = 3
	var total int64 = 10
	var price float64 = 2.5

	fmt.Println(total + count)
	fmt.Println(price * count)
}
```

```
ana@vm:~/convert$ go run .; echo $?
# example.com/convert
./main.go:10:14: invalid operation: total + count (mismatched types int64 and int)
./main.go:11:14: invalid operation: price * count (mismatched types float64 and int)
1
```

Both lines are refused, and the first one deserves a second look. Lesson 7 showed that `int` is
64 bits wide on this machine, exactly as wide as `int64`, so no value could be lost by adding them.
**The compiler is not checking sizes, it is checking types**, and `int` and `int64` are two
different types whatever their width. The same program has to build on a machine where `int` is
32 bits, and a rule that depended on the machine would make it build on one and fail on the other.

The fix is to say which type the arithmetic happens in, by converting one side:

```go
	fmt.Println(total + int64(count))
	fmt.Println(price * float64(count))
```

```
ana@vm:~/convert-fixed$ go run .
13
7.5
```

`int64(count)` is a conversion: the value of `count`, as an `int64`. Section 03 is about what that
does to a value; what matters here is that it is written in the line, where somebody reading
`total + int64(count)` can see that two types met and which one won.

## Why the compiler insists

An implicit conversion is a decision the language makes for you, in a line that does not show it.
In C, comparing a signed `-1` with an unsigned `1` converts the `-1` into a huge positive number
first, so `-1 < 1u` is false. Go rules that kind of surprise out by refusing to choose. The cost is
a few more words in mixed arithmetic. In return, **every place two types meet is visible in the
source**, and it is usually also the place where a bug about units or precision would hide.

## Constants are the exception

If every number had to be converted, `price * 3` would need `price * float64(3)`, and nobody would
put up with that. Lesson 5 showed that a constant written without a type is **untyped**, and an
untyped constant takes the type of whatever it meets, as long as its value fits. A constant
declared with a type has given that up:

```go
package main

import "fmt"

func main() {
	var price float64 = 2.5
	count := 3
	const n = 3
	const m int = 3

	fmt.Println(price * 3)
	fmt.Println(price * n)
	fmt.Println(price * m)
	fmt.Println(count * 2.5)
}
```

```
ana@vm:~/convert-const$ go run .
# example.com/convert-const
./main.go:13:14: invalid operation: price * m (mismatched types float64 and int)
./main.go:14:22: 2.5 (untyped float constant) truncated to int
```

The compiler named lines 13 and 14 and nothing else, so lines 11 and 12 were accepted: the literal
`3` and the constant `n` both became `float64` to meet `price`. Line 13 is refused for the same
reason as `price * count` above, because `m` is an `int` now, constant or not.

Line 14 is the other half of the rule. `2.5` is untyped, so it tries to become an `int` to meet
`count`, and it cannot do that without losing the `.5`. **An untyped constant converts only when
its value survives the trip**, and the compiler says `truncated` rather than quietly
multiplying by 2. If you wanted 7.5, the conversion goes on `count`: `float64(count) * 2.5`.
