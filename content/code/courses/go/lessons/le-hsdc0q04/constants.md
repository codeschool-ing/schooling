---
title: Constants, typed and untyped
version: 1
---

In JavaScript, `const` means a variable that cannot be reassigned, and it can hold anything a
program computes while it runs. Go's `const` is a different thing. **A Go constant is a value the
compiler knows, and it exists only while the program is being compiled.** It cannot be
reassigned, and it cannot be the result of anything that happens at run time either:

```go
package main

import (
	"fmt"
	"os"
)

const limit = 10
const args = len(os.Args)

func main() {
	limit = 20
	fmt.Println(limit, args)
}
```

```
ana@vm:~/vars-fixed$ go run .; echo $?
# example.com/vars-fixed
./main.go:9:14: len(os.Args) (value of type int) is not constant
./main.go:12:2: cannot assign to limit (neither addressable nor a map index expression)
1
```

Two errors from one run, each with its own line. `os.Args` holds the program's command-line
arguments, which nobody knows until the program starts, so their count cannot be a constant. And
`limit` cannot be assigned to at all: a constant is not a place in memory with a value in it, which
is what the message's "not addressable" means. Numbers, strings and booleans the compiler can
work out are what constants are for: a limit, a name, a ratio, a size.

## Untyped: a number that has not chosen a type yet

`const answer = 42` has no type written, and that is not the same as the type being worked out from
the value, which is what `var` did in section 01. **An untyped constant stays just a number until
it is used, and then it takes the type of wherever it lands**, as long as it fits:

```go
package main

import "fmt"

const Pi = 3.14159

const (
	answer = 42
	name   = "Ana"
)

func main() {
	var radius float64 = 2
	var small int8 = answer
	var exact float64 = answer

	fmt.Println(Pi*radius*radius, name)
	fmt.Println(small, exact)
	fmt.Printf("%T %T\n", small, exact)
}
```

```
ana@vm:~/vars-const$ go run .
12.56636 Ana
42 42
int8 float64
```

The same `answer` became an `int8` in one variable and a `float64` in the next, and `Pi` multiplied
a `float64` without anybody saying what type `Pi` was. When an untyped constant lands where no type
is asked for, as in `x := answer`, it takes its **default type**: `int` for a whole number,
`float64` for one with a decimal point and `string` for text. Those are the types `%T` reported in
sections 01 and 02.

Write the type, and the constant has it from then on:

```go
package main

import "fmt"

const answer int = 42

func main() {
	var small int8 = answer
	fmt.Println(small)
}
```

```
ana@vm:~/vars-typed$ go run .; echo $?
# example.com/vars-typed
./main.go:8:19: cannot use answer (constant 42 of type int) as int8 value in variable declaration
1
```

42 fits in an `int8` perfectly well. The refusal is about the type: `answer` is now an `int`, and Go
does not turn one integer type into another by itself. Lesson 10 is about that rule and the
conversions that get round it. **Leaving a constant untyped is what lets it fit wherever it is
needed**, so give it a type only when the type is part of what the constant means.

## Bigger than any variable

An untyped integer constant is not limited to the size of any integer type. The compiler does
constant arithmetic exactly, and the compiler of Go 1.27.1 allows up to 512 bits before it gives
up, a limit written as `const prec = 512` in its source, in
`/usr/local/go/src/cmd/compile/internal/types2/const.go`. So a
constant can hold a value no variable could:

```go
package main

import "fmt"

const big = 1 << 100

func main() {
	fmt.Println(big >> 98)
	fmt.Println(big / (1 << 90))
}
```

```
ana@vm:~/vars-big$ go run .
4
1024
```

`1 << 100` is 1 shifted left a hundred places, 2 to the power 100. Shifted back 98 places it is 4,
and divided by 2 to the 90 it is 1024. Both results are small, so both fit in an `int` when
`Println` receives them, and the giant in between never had to.

**It fails at the moment it has to fit in a variable**:

```go
package main

import "fmt"

const big = 1 << 100

func main() {
	var n int = big
	fmt.Println(n)
}
```

```
ana@vm:~/vars-overflow$ go run .; echo $?
# example.com/vars-overflow
./main.go:8:14: cannot use big (untyped int constant 1267650600228229401496703205376) as int value in variable declaration (overflows)
1
```

The message prints the constant in full, all 31 digits, and says what it was being made into: an
`int`, which is far too small. Lesson 7 is about the sizes of the integer types. The
difference to keep from this lesson is when the check happens. **A constant that does not fit is a
compile error, so it never reaches a running program.** An ordinary variable that grows past its
size at run time is another story, also lesson 7's.
