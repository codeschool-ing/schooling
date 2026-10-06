---
title: A function with a receiver
version: 1
---

In Java or Python a method is written inside a class, and the class is the only place one can live.
Go has no classes, as lesson 1 said, and lesson 15 noted that a struct's declaration lists fields
and nothing else. **A method in Go is a function declared at package level with one extra
parameter, the receiver, written in front of its name.** It can belong to any type your package
defines, and a struct is only one kind of type. Lesson 10's temperatures, in `~/methods`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\ntype Celsius float64\ntype Fahrenheit float64\n",
      "note": "The two defined types of lesson 10, each built on a `float64`."
    },
    {
      "code": "\nfunc CToF(c Celsius) Fahrenheit {\n\treturn Fahrenheit(c*9/5 + 32)\n}\n",
      "note": "Lesson 10's conversion as a plain function. The temperature arrives as the parameter `c`."
    },
    {
      "code": "\nfunc (c Celsius) ToFahrenheit() Fahrenheit {\n\treturn Fahrenheit(c*9/5 + 32)\n}\n",
      "note": "**The same body as a method.** `(c Celsius)` before the name is the receiver: a parameter with a name and a type, written in a place of its own. The method belongs to `Celsius`, which is a number, with no struct anywhere."
    },
    {
      "code": "\ntype Rect struct {\n\tW, H float64\n}\n\nfunc (r Rect) Area() float64 {\n\treturn r.W * r.H\n}\n",
      "note": "A struct gets a method the same way. `Rect`'s declaration names only its fields, and the method sits beside it; it could just as well sit in another file of the same package."
    },
    {
      "code": "\nfunc main() {\n\tboil := Celsius(100)\n\tfmt.Println(CToF(boil), boil.ToFahrenheit())\n\n\tr := Rect{W: 3, H: 4}\n\tfmt.Println(r.Area())\n}\n",
      "note": "A method is called on a value, with a dot. `boil.ToFahrenheit()` hands `boil` to the method as `c`, so the function and the method compute the same 212."
    }
  ]
}
```

```
ana@vm:~/methods$ go run .
212 212
12
```

The receiver is usually one or two letters, the first of the type's name, and the same letter in
every method of that type. It is not called `this` or `self`. Inside the method it is an ordinary
variable that holds the value the method was called on.

## Only on a type your package defines

Methods can be declared on a type defined in the same package, and on nothing else. Three attempts
that break the rule, in `~/methods-nonlocal`:

```go
type Number = int

func (n int) Double() int {
	return n * 2
}

func (d time.Duration) Days() float64 {
	return d.Hours() / 24
}

func (n Number) Triple() int {
	return n * 3
}
```

```
ana@vm:~/methods-nonlocal$ go build
# example.com/nonlocal
./main.go:10:9: cannot define new methods on non-local type int
./main.go:14:9: cannot define new methods on non-local type time.Duration
./main.go:18:9: cannot define new methods on non-local type Number
```

`int` is predeclared and belongs to no package of yours; `time.Duration` belongs to `time`. The
third is the one that surprises people: `type Number = int`, with the `=`, is lesson 10's alias, a
second name for `int` and not a new type, so the compiler refuses it for the same reason
as `int`. **The consequence is
worth more than the rule: every method a type has is declared in the package that defines it**, so
reading that package tells you all of them, and importing another package can never add one.

The way round is the one lesson 10 used for temperatures. Define a type of your own on top, and give
that type the methods:

```go
type Number int

func (n Number) Double() Number {
	return n * 2
}

type Span time.Duration

func (s Span) Days() float64 {
	return time.Duration(s).Hours() / 24
}
```

```
ana@vm:~/methods-local$ go run .
42
1.5
```

`Days` converts `s` back to a `time.Duration` before asking for `Hours`, and the conversion is not
decoration. A defined type takes the underlying type's values and operators, and none of its
methods:

```
ana@vm:~/methods-span$ go build
# example.com/span
./main.go:12:16: s.Hours undefined (type Span has no field or method Hours)
```

## String, and what fmt prints

Lesson 6 section 03 declared a `Weekday` with `iota`, printed `Sunday, Monday, Saturday` and got
`0 1 6`, while the standard library's `time.Saturday` printed `Saturday`. The difference was one
method. Here is the same `Weekday` with it, in `~/methods-days`:

```go
var names = [...]string{"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}

func (d Weekday) String() string {
	return names[d]
}

func main() {
	fmt.Println(Sunday, Monday, Saturday)
	fmt.Printf("%v %s %d\n", Saturday, Saturday, Saturday)
	fmt.Println(Saturday.String() + "!")
	fmt.Println(time.Saturday)
}
```

```
ana@vm:~/methods-days$ go run .
Sunday Monday Saturday
Saturday Saturday 6
Saturday!
Saturday
ana@vm:~/methods-days$ go doc time.Weekday.String
package time // import "time"

func (d Weekday) String() string
    String returns the English name of the day ("Sunday", "Monday", ...).

```

**When a value's type has a method `String() string`, `fmt` prints what that method returns**, for
`Println`, `%v` and `%s`. `%d` still asks for the number and gets 6, because the constant is
still the number; the method only changes how it is shown. `time.Weekday` does exactly this, and
`go doc` shows its method in the same form as yours. `fmt` does not know your type in advance. It
checks each value it prints for that one method, by name and signature, and that check has a name of
its own, `fmt.Stringer`, which lesson 26 reads and lesson 27 explains.
