---
title: Functions as values, with or without a name
version: 1
---

A function in Go is a value, like an `int` or a slice. **It has a type, it can sit in a variable,
it can be passed to another function and returned from one.** The type is written the way the
function's signature is, without the names: `func(int) int` is any function that takes one `int`
and returns one. And a function does not need a name to exist. Written inline, `func(n int) int {
return n + 10 }` is a **function literal**, also called an anonymous function.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"cmp\"\n\t\"fmt\"\n\t\"slices\"\n)\n\nfunc apply(nums []int, f func(int) int) []int {\n\tout := make([]int, 0, len(nums))\n\tfor _, n := range nums {\n\t\tout = append(out, f(n))\n\t}\n\treturn out\n}\n",
      "note": "**`f func(int) int` is a parameter whose type is a function.** `apply` does not know what `f` does; it calls `f(n)` for each element and collects the results."
    },
    {
      "code": "\nfunc square(n int) int {\n\treturn n * n\n}\n",
      "note": "An ordinary named function. Its type is `func(int) int`, so it fits `apply`'s parameter."
    },
    {
      "code": "\nfunc main() {\n\tnums := []int{1, 2, 3}\n\tfmt.Println(apply(nums, square))\n",
      "note": "`square` without brackets is the function itself, passed as a value. With brackets, `square(2)`, it would be a call, and `apply` would receive an `int`."
    },
    {
      "code": "\tfmt.Println(apply(nums, func(n int) int { return n + 10 }))\n",
      "note": "A function literal, written where it is used. It has no name because nothing else will ever call it."
    },
    {
      "code": "\n\ttwice := func(n int) int { return 2 * n }\n\tfmt.Printf(\"%T\\n\", twice)\n\tfmt.Println(apply(nums, twice))\n",
      "note": "A literal stored in a variable. `%T` prints its type, `func(int) int`, the same type as `square`."
    },
    {
      "code": "\n\twords := []string{\"banana\", \"fig\", \"apple\", \"kiwi\"}\n\tslices.SortFunc(words, func(a, b string) int {\n\t\treturn cmp.Compare(len(a), len(b))\n\t})\n\tfmt.Println(words)\n}\n",
      "note": "**Where function values earn their keep: the standard library asks for one.** `slices.SortFunc` sorts in any order you like, and the literal says which order: by length, shortest first."
    }
  ],
  "output": "[1 4 9]\n[11 12 13]\nfunc(int) int\n[2 4 6]\n[fig kiwi apple banana]"
}
```

The comparison function has a contract, and `go doc` states it:

```
ana@vm:~/closures-anon$ go doc slices.SortFunc | head -4
package slices // import "slices"

func SortFunc[S ~[]E, E any](x S, cmp func(a, b E) int)
    SortFunc sorts the slice x in ascending order as determined by the cmp
```

The square brackets are generics, which lessons 30 and 31 teach; for now read `E` as "the
element type", `string` here. The part this section is about is the last parameter, `cmp func(a,
b E) int`: a function that takes two elements and returns an `int`. The rest of that
documentation says what the `int` means, negative when `a` comes first, positive when `b` does,
zero when they are equal, and `cmp.Compare` returns exactly that for any two ordered values. The
documentation also says the sort is **not guaranteed to be stable**: two words of the same length
may come out in either order. The four words above have four different lengths, so the output is
the same on every run. `slices.SortStableFunc` keeps equal elements in their original order.

## A nil function

The zero value of a function type is `nil`; lesson 6 printed it as `(func())(nil)`. A `nil` function is a variable with nothing to call, and calling it stops the program:

```go
package main

import "fmt"

func main() {
	var onDone func()
	fmt.Println(onDone == nil)
	onDone()
	fmt.Println("not reached")
}
```

```
ana@vm:~/closures-nil$ go run .
true
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x0 pc=0x499e2b]

goroutine 1 [running]:
main.main()
	/home/ana/closures-nil/main.go:8 +0x4b
exit status 2
```

Line 8 is `onDone()`. The compiler cannot catch this, because whether a variable holds a function
is only known when the program runs. Lesson 36 explains what a panic is and lesson 37 reads a
trace like this one line by line. **An optional callback, a function value the caller may leave
out, is checked with `!= nil` before it is called.**

That comparison is the only one a function allows:

```go
package main

import "fmt"

func square(n int) int {
	return n * n
}

func main() {
	f := square
	g := square
	fmt.Println(f == g)
}
```

```
ana@vm:~/closures-cmp$ go run .
# example.com/closures-cmp
./main.go:12:14: invalid operation: f == g (func can only be compared to nil)
```

`f` and `g` hold the same function, and the compiler still refuses to say so. The consequence is
practical: a function cannot be a map key, since lesson 14's keys must be comparable, and there is
no way to ask whether a function value is "the one you registered earlier".
