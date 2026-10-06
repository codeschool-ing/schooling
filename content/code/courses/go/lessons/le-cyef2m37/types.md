---
title: Generic types, their methods, and what a method may not do
version: 1
---

A type can take type parameters as well as a function can, and this is where lesson 30's word
**container** turns into code. A stack holds values and hands back the last one pushed; what the
values are does not matter to it, so it is written once, for a `T` the user of the stack picks. In
`~/generic2-stack`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\ntype Stack[T any] struct {\n\titems []T\n}\n",
      "note": "**A type parameter list on a type declaration.** `Stack` is a struct whose field is a slice of `T`, and `T` is whatever the code using it says it is."
    },
    {
      "code": "\nfunc (s *Stack[T]) Push(v T) {\n\ts.items = append(s.items, v)\n}\n",
      "note": "**The receiver names the type parameter again, without its constraint**: `Stack[T]`, not `Stack[T any]`. The constraint belongs to the type and is not repeated. The pointer receiver is there because `Push` changes the stack, lesson 26's rule."
    },
    {
      "code": "\nfunc (s *Stack[T]) Pop() (T, bool) {\n\tvar zero T\n\tif len(s.items) == 0 {\n\t\treturn zero, false\n\t}\n",
      "note": "**`var zero T` is how generic code writes \"the zero value\"**, because there is no literal that is zero for every type: `0`, `\"\"` and `nil` each fit some types and not others. An empty stack returns it with `false`, the comma-ok shape of lesson 14."
    },
    {
      "code": "\ttop := s.items[len(s.items)-1]\n\ts.items = s.items[:len(s.items)-1]\n\treturn top, true\n}\n",
      "note": "Take the last element, then reslice to drop it (lesson 12). Nothing here depends on what `T` is."
    },
    {
      "code": "\nfunc main() {\n\tvar words Stack[string]\n\twords.Push(\"first\")\n\twords.Push(\"second\")\n\tfmt.Println(words.Pop())\n\tfmt.Println(words.Pop())\n\tlast, ok := words.Pop()\n\tfmt.Printf(\"%q %v\\n\", last, ok)\n",
      "note": "`Stack[string]` is a type, and its zero value is an empty stack ready to use, the useful zero of lesson 6. The third `Pop` finds it empty and returns `\"\"`, the zero `string`."
    },
    {
      "code": "\n\tnums := &Stack[int]{}\n\tnums.Push(42)\n\tfmt.Printf(\"%T %v\\n\", nums, nums.items)\n}\n",
      "note": "The same declaration for `int`. `%T` prints the instantiated type, `*main.Stack[int]`, with its type argument as part of the name."
    }
  ],
  "output": "second true\nfirst true\n\"\" false\n*main.Stack[int] [42]"
}
```

There is no inference for a type. A function's call has arguments to read `T` from; `var words
Stack[string]` has nothing, so the type argument is always written. And **`Stack` alone is not a
type**, only a recipe for one, so each instantiation is a type of its own. In
`~/generic2-stackbad`, three lines get that wrong:

```go
func main() {
	var s Stack
	words := Stack[string]{}
	words.Push(3)
	var nums Stack[int] = words
	fmt.Println(s, nums)
}
```

```
ana@vm:~/generic2-stackbad$ go run .
# example.com/generic2-stackbad
./main.go:14:8: cannot use generic type Stack[T any] without instantiation
./main.go:16:13: cannot use 3 (untyped int constant) as string value in argument to words.Push
./main.go:17:24: cannot use words (variable of struct type Stack[string]) as Stack[int] value in variable declaration
```

The second error is the reason to write a `Stack[T]` at all. A stack of strings refuses an `int` at
compile time, where a stack built on lesson 28's `[]any` would have taken it and handed it back to
code expecting a string. The third shows that `Stack[string]` and `Stack[int]` are as unrelated as
`Celsius` and `Fahrenheit` were in lesson 10, though one declaration produced both.

## A method cannot narrow the type's constraint

A stack that can say whether it holds a value needs `==`. Written as a method, in
`~/generic2-contains`:

```go
func (s *Stack[T]) Contains(v T) bool {
	for _, x := range s.items {
		if x == v {
			return true
		}
	}
	return false
}
```

```
ana@vm:~/generic2-contains$ go run .
# example.com/generic2-contains
./main.go:15:6: invalid operation: x == v (incomparable types in type set)
```

The message is section 03's. The `T` of a method is the type's `T`, and the type said `any`. **Every
method of `Stack` has to work for every `Stack`**, including a `Stack[[]int]`, whose elements cannot
be compared, so no method may ask for more than the declaration asked for. The receiver cannot add
the requirement either, because the constraint is not repeated there.

Two repairs, and they differ in who pays. Declaring `Stack[T comparable]` makes `Contains` legal and
forbids every stack of slices or maps. Or `Contains` becomes a function with its own, stricter
constraint, which is what `~/generic2-contains2` does:

```go
func Contains[T comparable](s *Stack[T], v T) bool {
	for _, x := range s.items {
		if x == v {
			return true
		}
	}
	return false
}

func main() {
	var s Stack[string]
	s.Push("ana")
	fmt.Println(Contains(&s, "ana"), Contains(&s, "bia"))
}
```

```
ana@vm:~/generic2-contains2$ go run .
true false
```

A `Stack[[]int]` can still exist; it just cannot be passed to `Contains`. The standard library makes
the same choice everywhere: `slices.Index` asks for `E comparable` and `slices.Clone` asks for
`E any`, because each function states only what it needs.

## A method may have type parameters of its own

The type parameters in the receiver are the type's. A method can also declare new ones, in brackets
after its name, for types that only that method uses. `Map` from section 02, as a method that turns a
stack of one type into a stack of another, in `~/generic2-method`:

```go
func (s *Stack[T]) Map[U any](f func(T) U) *Stack[U] {
	out := &Stack[U]{}
	for _, v := range s.items {
		out.Push(f(v))
	}
	return out
}

func main() {
	ages := &Stack[int]{}
	ages.Push(41)
	ages.Push(7)
	labels := ages.Map(strconv.Itoa)
	fmt.Printf("%q %T\n", labels.items, labels)
}
```

```
ana@vm:~/generic2-method$ go run .
["41" "7"] *main.Stack[string]
ana@vm:~/generic2-method$ go mod edit -go=1.26 && go run .
# example.com/generic2-method
./main.go:16:24: generic method requires go1.27 or later (-lang was set to go1.26; check go.mod)
```

`T` came from the receiver, `int`, and `U` was inferred from `strconv.Itoa`, as for the function.
The second command is the `go` line of lesson 2 at work again. A method with type parameters of its
own needs a module that says `go 1.27` or later; code written for older releases does the same job
with a function such as section 02's `Map`. You will read plenty of that code.

**What such a method cannot do is take part in an interface.** An interface may not declare a method
with type parameters, and a method that has them does not satisfy an interface method without them.
`~/generic2-iface` tries both:

```go
type Mapper interface {
	Map[U any](f func(int) U) *Stack[U]
}

type TextMapper interface {
	Map(f func(int) string) *Stack[string]
}

func main() {
	var m TextMapper = &Stack[int]{}
	fmt.Println(m.Map(strconv.Itoa))
}
```

```
ana@vm:~/generic2-iface$ go run .
# example.com/generic2-iface
./main.go:25:5: interface method must have no type parameters
./main.go:25:25: undefined: U
./main.go:33:21: cannot use &Stack[int]{} (value of type *Stack[int]) as TextMapper value in variable declaration: *Stack[int] does not implement TextMapper (wrong type for method Map)
		have Map[U any](func(int) U) *Stack[U]
		want Map(func(int) string) *Stack[string]
```

The first error is the rule, and the second follows from it: with the brackets refused, `U` was never
declared. The third is the other half. `TextMapper` asks for exactly the `Map` that `*Stack[int]`
would have with `U` set to `string`, and the compiler still refuses, printing the method the type
`have`s against the one the interface `want`s. An interface describes methods a value has now, one
signature each. A generic method is a family of methods, and none of them exists until a call picks
`U`.

So the rule of lesson 30 holds inside a type too: type parameters for code that is the same whatever
the type, interfaces for behaviour. A generic method serves the first, and keeps it apart from the
second.
