---
title: Variadic functions: any number of arguments
version: 1
---

Lesson 20 said a call must pass exactly as many arguments as the function has parameters. Yet
`fmt.Println` has taken one argument, three and five in this course without complaint. Lesson 4
printed its signature, `func Println(a ...any) (n int, err error)`, and the `...` is the
explanation. **A parameter written `...T` accepts any number of arguments of type `T`, and inside
the function it is an ordinary slice, `[]T`.** A function with one is called **variadic**.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc sum(nums ...int) int {\n\ttotal := 0\n\tfor _, n := range nums {\n\t\ttotal += n\n\t}\n\treturn total\n}\n",
      "note": "`nums ...int` collects every `int` the caller passes. The body walks `nums` like any slice; the `for range` loop is lesson 17's."
    },
    {
      "code": "\nfunc show(nums ...int) {\n\tfmt.Printf(\"%T %v len=%d nil=%v\\n\", nums, nums, len(nums), nums == nil)\n}\n",
      "note": "A second function, only to look at what a variadic parameter really is: its type, its contents, its length, and whether it is `nil`."
    },
    {
      "code": "\nfunc main() {\n\tfmt.Println(sum(), sum(5), sum(1, 2, 3))\n",
      "note": "Zero arguments, one, three: all legal. `sum()` is 0 because the loop has nothing to add."
    },
    {
      "code": "\tshow()\n\tshow(1, 2)\n",
      "note": "**With no arguments the parameter is a `nil` slice**, lesson 12's distinction: length 0 and `nil=true`. With two it is a `[]int` of length 2, built for this call."
    },
    {
      "code": "\n\tscores := []int{7, 8, 9}\n\tfmt.Println(sum(scores...))\n}\n",
      "note": "**A slice you already have is passed with `...` after it.** `scores...` hands `sum` the slice itself, not its elements one by one."
    }
  ],
  "output": "0 5 6\n[]int [] len=0 nil=true\n[]int [1 2] len=2 nil=false\n24"
}
```

`append`, which lesson 11 met, is variadic too, which is why `append(s, 1, 2, 3)` adds three
elements at once and `append(a, b...)` adds the whole of slice `b` to `a`.

## Three rules the compiler holds you to

```go
package main

import "fmt"

func sum(nums ...int) int {
	total := 0
	for _, n := range nums {
		total += n
	}
	return total
}

func label(nums ...int, unit string) string {
	return unit
}

func main() {
	scores := []int{7, 8, 9}
	fmt.Println(sum(scores))

	words := []string{"go", "vet"}
	fmt.Println(words...)
}
```

```
ana@vm:~/closures-varerr$ go run .
# example.com/closures-varerr
./main.go:13:17: can only use ... with final parameter
./main.go:19:18: cannot use scores (variable of type []int) as int value in argument to sum
./main.go:22:14: cannot use words (variable of type []string) as []any value in argument to fmt.Println
```

One error for each rule:

1. **Only the last parameter can be variadic.** Otherwise there would be no way to tell where
   `nums` stops and `unit` begins, so `label` is refused at its declaration.
2. **A slice is not spread by itself.** `sum(scores)` passes one argument, a `[]int`, where `sum`
   wants `int` values. The `...` after `scores` is what says "these are the arguments".
3. **The slice must already be of the parameter's type.** `Println` takes `...any`, so `words...`
   would have to be a `[]any`. A `[]string` is a different type, and Go does not convert a slice
   element by element on your behalf, the rule lesson 10 stated for single values. Passing the
   words one by one, `fmt.Println(words[0], words[1])`, works, because each string becomes an
   `any` on its own. Lesson 28 is about `any`.

## `s...` passes your slice, not a copy of it

Rule 2 has a consequence that is easy to miss. When the arguments are written out, Go builds a
new slice to hold them. When you pass `scores...`, it builds nothing: **the parameter is your
slice, with your array behind it**, and a function that writes to its elements writes to yours.

```go
package main

import "fmt"

func double(nums ...int) {
	for i := range nums {
		nums[i] *= 2
	}
}

func main() {
	a, b, c := 1, 2, 3
	double(a, b, c)
	fmt.Println(a, b, c)

	scores := []int{1, 2, 3}
	double(scores...)
	fmt.Println(scores)
}
```

```
ana@vm:~/closures-share$ go run .
1 2 3
[2 4 6]
```

The same function, called two ways. With `a, b, c` it doubled the elements of a slice made for
the call, and `a`, `b` and `c` kept their values. With `scores...` it doubled the elements of
`scores`. This is lesson 11's rule about a slice parameter, met from another direction: the
function receives a copy of the slice's three words, and the pointer in them leads to the
caller's array. Everything lesson 12 said about two slices over one array applies here as well,
including an `append` inside the function writing into spare capacity the caller owns.

So a variadic function that only reads its arguments is safe to call either way. **One that
writes to them should say so in its documentation**, because the caller who passes a slice with
`...` sees the writes and the caller who lists values does not.
