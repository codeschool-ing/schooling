---
title: Method or function
version: 1
---

A programmer trained on objects reaches for a method by habit, and reads a package full of plain
functions as a design nobody finished. Go's standard library says otherwise. **A method is the right
choice when the behaviour belongs to one value of a type you own, or when something has to find it
on the type by name; otherwise a function is the plain and normal choice.** Section 02 met both
reasons without naming them.

## The type's own data

`r.Area()` reads `r`'s fields and nothing else. `d.String()` turns `d` into its name. Behaviour like
that is about one value, and putting it on the type keeps it next to the data it depends on and gives
it a name that reads as a question to the value.

It also gives the name a scope. **A method's name belongs to its type, so two types can each have
an `Area`.** Two package-level functions cannot share a name, and lesson 20 showed Go has no
overloading to tell them apart by parameter type. Written as functions, in `~/methods-funcs`:

```go
func Area(r Rect) float64 {
	return r.W * r.H
}

func Area(c Circle) float64 {
	return math.Pi * c.R * c.R
}
```

```
ana@vm:~/methods-funcs$ go build
# example.com/funcs
./main.go:20:6: Area redeclared in this block
	./main.go:16:6: other declaration of Area
```

As functions they would have to be `RectArea` and `CircleArea`. As methods, in `~/methods-shapes`,
each type has its own and the call says which by the value in front of it:

```go
func (r Rect) Area() float64 {
	return r.W * r.H
}

func (c Circle) Area() float64 {
	return math.Pi * c.R * c.R
}

func main() {
	fmt.Println(Rect{W: 3, H: 4}.Area())
	fmt.Printf("%.2f\n", Circle{R: 1}.Area())
}
```

```
ana@vm:~/methods-shapes$ go run .
12
3.14
```

## Something has to find it by name

`Weekday`'s `String` in section 02 could not have been a function. A `func WeekdayName(d Weekday)
string` would work when you call it, and `fmt.Println(Saturday)` would still print `6`, because
`fmt` looks for a method called `String` on the value's type and never for a function somewhere in
your package. **Code that does not know your type in advance can only reach it through its
methods.** That is the second reason, and it is the one that grows: lesson 27 shows `fmt`'s rule
generalised as an interface, which is a list of methods, and a type satisfies one only with methods.

## When a function is right

Everything else. The `strings` package is the standing example. `string` is a predeclared type, so
by section 02's rule no package may add methods to it. The package is a collection of functions that
take a string as their first argument instead:

```
ana@vm:~/methods-shapes$ go doc strings | grep -c "^func"
56
ana@vm:~/methods-shapes$ go doc strings | grep "^type"
type Builder struct{ ... }
type Reader struct{ ... }
type Replacer struct{ ... }
```

56 functions, and three types that do have methods. Those three are worth noticing: a `Builder`
holds the text it has built so far, which lesson 9 used, so its operations are about that one
value's data, and `b.WriteString(s)` is a method. The rule that put the functions in the package put
the methods on the types.

A function is also right when no single value is in charge. Comparing two rectangles treats both
alike, and `Overlap(a, b)` says so where `a.Overlap(b)` suggests `a` matters more. And the standard
library sometimes offers both, which shows the choice is about the call that reads best:

```
ana@vm:~/methods-shapes$ go doc time.Since
package time // import "time"

func Since(t Time) Duration
    Since returns the time elapsed since t. It is shorthand for
    time.Now().Sub(t).

```

`t.Sub(u)` is a method on `time.Time`, and `time.Since(t)` is a function because "how long ago" is a
question about now as much as about `t`. Neither is more correct. Underneath, a method call is a function
call with the receiver passed as a parameter, which section 04 shows directly.
