---
title: Types of your own, and why they refuse to mix
version: 1
---

A newcomer reading `type Celsius float64` usually takes it as a nickname: Celsius *is* a
`float64`, under a name that reads better. **It is a new type, with a `float64` underneath it**,
and the rule of section 01 applies to it in full. Two temperature types make the point:

```go
package main

import "fmt"

type Celsius float64
type Fahrenheit float64

func main() {
	var boil Celsius = 100
	var body Fahrenheit = 98.6
	var reading float64 = 21.5

	fmt.Println(boil + body)
	var room Celsius = reading
	fmt.Println(room)
}
```

```
ana@vm:~/convert-temp$ go run .
# example.com/convert-temp
./main.go:13:14: invalid operation: boil + body (mismatched types Celsius and Fahrenheit)
./main.go:14:21: cannot use reading (variable of type float64) as Celsius value in variable declaration
```

Adding a Celsius to a Fahrenheit is a unit error, and the compiler caught it with nothing more than
two lines of declarations. The second refusal is the same rule from the other side: a plain
`float64` is not a `Celsius` either, even though one is stored exactly like the other. The
untyped constants `100` and `98.6` were accepted, for the reason section 01 gave.

**A type you define is a promise about what the number means, and the compiler holds every line of
the program to it.** That is cheap to write and it catches a whole class of bug before the program
runs.

## Converting changes the type, never the number

The two types share an underlying type, `float64`, so a conversion between them is allowed. What it
does is easy to get wrong:

```go
package main

import "fmt"

type Celsius float64
type Fahrenheit float64

func CToF(c Celsius) Fahrenheit {
	return Fahrenheit(c*9/5 + 32)
}

func main() {
	var boil Celsius = 100
	fmt.Println(Fahrenheit(boil))
	fmt.Println(CToF(boil))

	var reading float64 = 21.5
	room := Celsius(reading)
	fmt.Printf("%v %T\n", room, room)
}
```

```
ana@vm:~/convert-temp2$ go run .
100
212
21.5 main.Celsius
```

`Fahrenheit(boil)` printed `100`. The conversion relabelled the value and did no arithmetic, so it
now claims that water boils at 100 °F. Nothing in the language knows how Celsius relates to
Fahrenheit; `CToF` is where that knowledge lives, and it is the only place a conversion between the
two belongs. Inside it, `9`, `5` and `32` are untyped constants, so `c*9/5 + 32` is arithmetic in
`Celsius`, converted once at the end.

`%T` prints a value's type, and it says `main.Celsius`: the package that defined the type, then
its name. Lesson 25 gives a type like this methods of its own, which is the other reason to define
one.

## The standard library does the same

`time.Duration` is the defined type you will meet most, and it trips everybody once:

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	n := 2
	fmt.Println(n * time.Second)
}
```

```
ana@vm:~/convert-dur$ go run .
# example.com/convert-dur
./main.go:10:14: invalid operation: n * time.Second (mismatched types int and time.Duration)
ana@vm:~/convert-dur$ go doc time.Duration | head -6
package time // import "time"

type Duration int64
    A Duration represents the elapsed time between two instants as an int64
    nanosecond count. The representation limits the largest representable
    duration to approximately 290 years.
```

A `Duration` is an `int64` counting nanoseconds, defined as its own type so that a count of
seconds and a count of nanoseconds cannot be mixed up. The conversion goes on `n`, and where it
goes matters:

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	n := 2
	fmt.Println(time.Duration(n) * time.Second)
	fmt.Println(time.Duration(n))
}
```

```
ana@vm:~/convert-dur2$ go run .
2s
2ns
```

`time.Duration(n)` on its own is 2 nanoseconds, because that is what the number inside a
`Duration` counts. Multiplying it by `time.Second` makes it two seconds. **The conversion says what
type a number is; only arithmetic says what unit it is in.**

## An alias is another name for the same type

Put an `=` in the declaration and you get something different: an **alias**, a second name for an
existing type rather than a new one.

```go
package main

import "fmt"

type Celsius float64
type Reading = float64

func main() {
	var x float64 = 21.5
	var r Reading = x
	c := Celsius(x)
	fmt.Printf("%T %T\n", r, c)
	fmt.Println(r + x)
}
```

```
ana@vm:~/convert-alias$ go run .
float64 main.Celsius
43
ana@vm:~/convert-alias$ go doc builtin.byte
package builtin // import "builtin"

type byte = uint8
    byte is an alias for uint8 and is equivalent to uint8 in all ways. It is
    used, by convention, to distinguish byte values from 8-bit unsigned integer
    values.
```

`Reading` took a `float64` with no conversion and added to one, and `%T` does not even mention it:
the type of `r` is `float64`, and `Reading` is only how the source spells it. You have used two
aliases already. `byte` is `uint8` and `rune` is `int32`, which is why lesson 8 could say a byte is
a `uint8` and mean it literally.

| declaration | what it makes | mixes with `float64`? |
|---|---|---|
| `type Celsius float64` | a new type, a **definition** | no, it needs a conversion |
| `type Reading = float64` | a second name, an **alias** | yes, it is the same type |

The definition is the one that buys you something. An alias gives a type a different name and
keeps every line that mixes it with the original legal, so it catches nothing.
