---
title: Integers have a size, and the size is a limit
version: 1
---

In Python an integer grows as large as it needs to: two to the power of seventy is an ordinary
number there. **In Go every integer type has a fixed number of bits, and arithmetic that runs past
the last one does not stop or complain. It wraps around.** Most of this section is about where
those limits are and what happens at them.

## Ten types, and the one to use

Go has four sizes of signed integer, `int8`, `int16`, `int32` and `int64`, the same four unsigned,
`uint8` to `uint64`, and two whose size depends on the machine, `int` and `uint`. The `math`
package names the limits of every one of them, and `go doc` prints them with their values:

```
ana@vm:~/numbers$ go doc math.MaxInt
package math // import "math"

const (
	MaxInt    = 1<<(intSize-1) - 1  // MaxInt32 or MaxInt64 depending on intSize.
	MinInt    = -1 << (intSize - 1) // MinInt32 or MinInt64 depending on intSize.
	MaxInt8   = 1<<7 - 1            // 127
	MinInt8   = -1 << 7             // -128
	MaxInt16  = 1<<15 - 1           // 32767
	MinInt16  = -1 << 15            // -32768
	MaxInt32  = 1<<31 - 1           // 2147483647
	MinInt32  = -1 << 31            // -2147483648
	MaxInt64  = 1<<63 - 1           // 9223372036854775807
	MinInt64  = -1 << 63            // -9223372036854775808
	MaxUint   = 1<<intSize - 1      // MaxUint32 or MaxUint64 depending on intSize.
	MaxUint8  = 1<<8 - 1            // 255
	MaxUint16 = 1<<16 - 1           // 65535
	MaxUint32 = 1<<32 - 1           // 4294967295
	MaxUint64 = 1<<64 - 1           // 18446744073709551615
)
    Integer limit values.
```

A signed type of n bits holds from −2ⁿ⁻¹ to 2ⁿ⁻¹ − 1, which is why `int8` stops at 127 and not
128: one of its 256 values is spent on zero. An unsigned type gives up the negative numbers and
reaches twice as far, so `uint8` runs from 0 to 255.

`MaxInt` says "depending on intSize", and the program below asks what that is on the lab's
machine, then again with the program built for 32-bit x86:

```go
// Command intsize prints how wide int is on the machine it was built for.
package main

import (
	"fmt"
	"math"
	"strconv"
)

func main() {
	fmt.Println("int is", strconv.IntSize, "bits")
	fmt.Println("largest int:", math.MaxInt)
	fmt.Printf("%T %T %T\n", 42, 4.2, 2i)
}
```

```
ana@vm:~/numbers$ go run .
int is 64 bits
largest int: 9223372036854775807
int float64 complex128
ana@vm:~/numbers$ GOARCH=386 go run .
int is 32 bits
largest int: 2147483647
int float64 complex128
```

**`int` is 64 bits on the lab's amd64, and 32 bits when the same source is built for 32-bit
x86.** The same source gave two different largest values, which is the reason to choose a sized
type whenever the size is part of the meaning: a file format, a network protocol, a column in a
database. For everything else, counting, indexing and lengths, use `int`. `len` returns an `int`,
and so do the indexes of every slice and string, so a program that uses `int` for its own
counters never has to convert between them. The last line shows the types Go gives a number
literal when nothing else says: a whole number is an `int`, a number with a point is a `float64`
and one with an `i` is a `complex128`.

Unsigned types are for bits and bytes: hashes, flags, raw data. They are not a way to say "this
count can never be negative", and the next program shows why.

## Wrapping around

```go
package main

import "fmt"

func main() {
	var small int8 = 127
	small++
	fmt.Println(small)

	var count uint = 0
	count--
	fmt.Println(count)
}
```

```
ana@vm:~/numbers-wrap$ go run .
-128
18446744073709551615
```

`127 + 1` in an `int8` is −128, and `0 − 1` in a `uint` is 18446744073709551615, the largest
`uint` there is. **Integer overflow at run time is silent: no error, no panic, just a value that
has gone round the circle.** A `uint` counter that is decremented once too often does not become
−1. It becomes the largest number the type holds, and every line that trusted it to be small is
now wrong.

The compiler checks what it can. A constant has no run time, so a constant that does not fit is
refused before the program exists, the same check lesson 5 showed for an untyped `1 << 100`:

```go
package main

import "fmt"

const limit int8 = 127

func main() {
	var small int8 = 128
	next := limit + 1
	fmt.Println(small, next)
}
```

```
ana@vm:~/numbers-const$ go build
# example.com/const
./main.go:8:19: cannot use 128 (untyped int constant) as int8 value in variable declaration (overflows)
./main.go:9:10: limit + 1 (constant 128 of type int8) overflows int8
```

`limit + 1` was refused because `limit` is a typed constant, so the sum is a constant of type
`int8` too, and 128 is not one. Change `limit` into a variable and the same line compiles, and
wraps.

## Division and remainder

Integer division has two rules people get wrong, and one program shows both:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n"
    },
    {
      "code": "\tfmt.Println(7 / 2)\n",
      "note": "**Dividing two integers gives an integer**, and the part after the point is dropped: 3, not 3.5."
    },
    {
      "code": "\tfmt.Println(-7 / 2)\n",
      "note": "**Dropped means truncated toward zero, not rounded down.** −3.5 becomes −3. A language that floors would print −4 here, and Python does."
    },
    {
      "code": "\tfmt.Println(7 % 3)\n",
      "note": "`%` is the remainder of that division: 7 is 2 × 3 plus 1."
    },
    {
      "code": "\tfmt.Println(-7 % 3)\n",
      "note": "The remainder takes the sign of the number being divided, so it is −1. The two operators agree with each other: `(a / b) * b + a % b` is `a` for any `b` that is not zero."
    },
    {
      "code": "\tfmt.Println(7.0 / 2)\n}\n",
      "note": "`7.0` is a floating-point constant, so this division is between floats and keeps its fraction."
    }
  ],
  "output": "3\n-3\n1\n-1\n3.5\n"
}
```

Dividing by zero is where integers and the compiler part ways again. With constants, it is
refused:

```go
package main

import "fmt"

func main() {
	fmt.Println(10 / 0)
}
```

```
ana@vm:~/numbers-zero$ go build
# example.com/zero
./main.go:6:19: invalid operation: division by zero
```

With a variable the compiler cannot know, so the program builds and stops when the division runs:

```go
package main

import "fmt"

func main() {
	d := 0
	fmt.Println(10 / d)
	fmt.Println("never printed")
}
```

```
ana@vm:~/numbers-zero$ go build && ./zero; echo $?
panic: runtime error: integer divide by zero

goroutine 1 [running]:
main.main()
	/home/ana/numbers-zero/main.go:7 +0x9
2
```

That is a **panic**: the program stops, prints what went wrong and where (`main.go:7`, the
division), and exits with status 2. `never printed` was not. Lesson 36 is about panics and lesson
37 reads the rest of that output line by line. Floating-point division by zero does not panic, as
section 03 shows, which makes this one of the few places where the two kinds of number behave
completely differently.
