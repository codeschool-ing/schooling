---
title: Method sets, and the String that fmt never calls
version: 1
---

Section 02's bug at least showed up in the output, as a count stuck at 0. This one changes what a program prints and
produces no error, no warning and no complaint from `go vet`. The type is an amount of money in
integer cents, and its `String` method is declared on the pointer:

```go
package main

import "fmt"

type Money struct {
	Cents int64
}

func (m *Money) String() string {
	return fmt.Sprintf("R$ %d,%02d", m.Cents/100, m.Cents%100)
}

func main() {
	price := Money{Cents: 1990}
	fmt.Println(price)
	fmt.Println(&price)
	fmt.Println(price.String())
}
```

```
ana@vm:~/receivers-print$ go run .
{1990}
R$ 19,90
R$ 19,90
ana@vm:~/receivers-print$ go vet; echo $?
0
```

Three lines that look as if they should agree, and the first one ignored the method. The last line
is the easy one: `price.String()` is a call on a variable, so the compiler takes `&price` for you,
as section 02 showed. The first two need a sentence about how `fmt` finds a `String` method at all.

## What fmt is looking for

`fmt` does not know your type. It asks one question of each value it prints, and `go doc` shows the
question:

```
ana@vm:~/receivers-print$ go doc fmt.Stringer
package fmt // import "fmt"

type Stringer interface {
	String() string
}
    Stringer is implemented by any value that has a String method, which defines
    the “native” format for that value. The String method is used to print
    values passed as an operand to any format that accepts a string or to an
    unformatted printer such as Print.

```

`fmt.Stringer` is an **interface**: a type described only by the methods a value must have.
Lesson 27 is about interfaces; for this section one sentence is enough. `fmt.Println` takes its
arguments as `...any`, so each argument arrives as a copy, and `handleMethods` in
`/usr/local/go/src/fmt/print.go` asks whether that value satisfies `Stringer`. A `*Money` does.
**A `Money` does not, because a `Money` has no `String` method: the method belongs to `*Money`.**
So `fmt` falls back to printing the struct's fields, `{1990}`, which is a perfectly good output and
the reason nothing complained.

## The method set

Which methods a value "has" is a definite list, and the language calls it the **method set** of
its type:

| a value of type | has these methods in its method set |
|---|---|
| `Money` | the methods declared with receiver `Money` |
| `*Money` | the methods declared with receiver `Money` **and** with receiver `*Money` |

The pointer gets both because from an address the compiler can always reach the value, and copy it
for a value method. The value gets only its own because the other direction needs an address.
The copy `fmt` holds has none anybody could use. It is not the variable `price`, and a pointer
method that changed it would change something nobody will ever look at. That is section 02's bug
again, and **Go does not let it happen silently through an interface: it leaves pointer methods
out of the value's method set instead.**

The automatic `&` of section 02 is no exception to this. It applies to a call written on a
variable, where there is an address. A value stored in an interface is not a variable you wrote.

## When the compiler does say it

`fmt.Println` accepts anything, so it had no reason to refuse. Ask for a `fmt.Stringer`
explicitly, by declaring a variable of that type, and the method set is checked where you can see
it:

```go
package main

import "fmt"

type Money struct {
	Cents int64
}

func (m *Money) String() string {
	return fmt.Sprintf("R$ %d,%02d", m.Cents/100, m.Cents%100)
}

func main() {
	price := Money{Cents: 1990}
	var s fmt.Stringer = price
	fmt.Println(s)
}
```

```
ana@vm:~/receivers-iface$ go build
# example.com/iface
./main.go:15:23: cannot use price (variable of struct type Money) as fmt.Stringer value in variable declaration: Money does not implement fmt.Stringer (method String has pointer receiver)
```

The parenthesis at the end is the whole diagnosis. `Money` has a `String` method in the sense that
`price.String()` compiles, and it does not have one in its method set. `var s fmt.Stringer =
&price` would compile. So would the change that makes all three lines of the first program agree,
a value receiver:

```go
package main

import "fmt"

type Money struct {
	Cents int64
}

func (m Money) String() string {
	return fmt.Sprintf("R$ %d,%02d", m.Cents/100, m.Cents%100)
}

func main() {
	price := Money{Cents: 1990}
	var s fmt.Stringer = price
	fmt.Println(price)
	fmt.Println(&price)
	fmt.Println(s)
}
```

```
ana@vm:~/receivers-value$ go run .
R$ 19,90
R$ 19,90
R$ 19,90
```

`String` only reads the amount, so it never needed a pointer. With a value receiver it is in the
method set of `Money` and, by the table above, of `*Money` too, and every way of printing the
price finds it. **A method that does not change its receiver and is declared on the pointer costs
you exactly this: values of the type stop satisfying interfaces they look as if they satisfy.**
Section 04 turns that into a rule for choosing.
