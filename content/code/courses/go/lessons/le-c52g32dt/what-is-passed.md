---
title: What a function receives
version: 1
---

A function in Go receives a copy of every argument; lesson 22 makes that the rule for every type.
What changes from type to type is what gets copied. Section 02 showed that for an array it is every
element, so `zero(a)` changed a copy and `a` kept its 1. For a slice the copy is the three words of
section 03, and the sizes say so:

```go
package main

import (
	"fmt"
	"unsafe"
)

func main() {
	var big [1000]int
	s := big[:]
	fmt.Println(unsafe.Sizeof(big), unsafe.Sizeof(s))
	fmt.Println(len(s), cap(s))
}
```

```
ana@vm:~/arrays-size$ go run .
8000 24
1000 1000
```

`unsafe.Sizeof` reports how many bytes a value occupies itself, and it is used here only to measure.
An array of a thousand `int` is 8000 bytes, eight for each element. A slice over all of it is 24:
three words of eight bytes, a pointer, a length and a capacity, whatever the array holds behind
them. `big[:]` is the slice of the whole array, from index 0 to its end.

**Passing a slice copies 24 bytes and shares the array; passing an array copies the array.** Both
halves of that sentence have a consequence, and the program below shows each.

## Elements yes, length no

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc setFirst(s []int) {\n\ts[0] = 100\n}\n",
      "note": "**Changing an element through the parameter changes the caller's element.** `s` is a copy of the caller's slice, and its pointer leads to the same array."
    },
    {
      "code": "\nfunc addFour(s []int) {\n\ts = append(s, 4)\n\tfmt.Println(\"inside: \", s, len(s))\n}\n",
      "note": "`append` returns a slice one longer, and this function stores it in `s`, **its own copy**. Inside, `s` has four elements."
    },
    {
      "code": "\nfunc main() {\n\tnums := []int{1, 2, 3}\n\n\tsetFirst(nums)\n\tfmt.Println(\"after setFirst:\", nums)\n",
      "note": "After `setFirst` the caller's slice starts with `100`."
    },
    {
      "code": "\n\taddFour(nums)\n\tfmt.Println(\"after addFour: \", nums, len(nums))\n}\n",
      "note": "**After `addFour` the caller's slice still has three elements.** The 4 went into a slice that existed only inside `addFour`."
    }
  ],
  "output": "after setFirst: [100 2 3]\ninside:  [100 2 3 4] 4\nafter addFour:  [100 2 3] 3"
}
```

The two functions look alike and behave in opposite ways. `setFirst` wrote through the pointer in
its copy, and that pointer leads to the same array `nums` uses, so the caller sees `100`.
`addFour` changed its own `s`: it assigned a new length, and possibly a new pointer, to a variable
that exists only inside `addFour`. The caller's slice was never touched, and **it still says length
3, whatever `append` did underneath.**

That last clause is deliberately vague. Whether `append` wrote the 4 into the same array or into a
new one depends on the capacity, and lesson 12 shows both cases and what each does to the caller.
For this lesson it does not matter: in neither case does the caller's length change.

## Return the slice

The fix is the one the standard library uses everywhere: a function that may lengthen a slice
returns the new one, and the caller stores it.

```go
package main

import "fmt"

func withFour(s []int) []int {
	return append(s, 4)
}

func main() {
	nums := []int{1, 2, 3}
	nums = withFour(nums)
	fmt.Println(nums, len(nums))
}
```

```
ana@vm:~/arrays-return$ go run .
[1 2 3 4] 4
```

`append` itself has exactly this shape. It takes a slice and returns one, and **the result is the
only slice guaranteed to hold what was appended**. The compiler goes as far as refusing a call that
throws it away:

```go
package main

import "fmt"

func main() {
	nums := []int{1, 2, 3}
	append(nums, 4)
	fmt.Println(nums)
}
```

```
ana@vm:~/arrays-forgot$ go run .
# example.com/arrays-forgot
./main.go:7:2: append(nums, 4) (value of type []int) is not used
```

That is why `s = append(s, x)` is written with the same name on both sides, and why `addFour`
above compiled: it did assign the result, to a copy nobody else could see.

So the answer to the lesson's question:

| you pass | the function receives | it can change your elements | it can change your length |
|---|---|---|---|
| an array `[3]int` | a copy of every element | no | no, it is fixed |
| a slice `[]int` | a copy of the three words | yes, through the shared array | no, return the slice |
