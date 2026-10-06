---
title: An array is its length
version: 1
---

Coming from Python or JavaScript, the word *array* means a list that grows when you add to it. **A
Go array has a fixed number of elements, and that number is part of its type.** `[3]int` and
`[4]int` are as different to the compiler as `int` and `string`, and everything else about arrays
follows from that. One program shows the four things that matter:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc zero(a [3]int) {\n\ta[0] = 0\n}\n",
      "note": "A function that takes an array of three `int` and sets its first element to zero. The parameter's type is written `[3]int`, length first."
    },
    {
      "code": "\nfunc main() {\n\ta := [3]int{1, 2, 3}\n\tfmt.Printf(\"%v %T %d\\n\", a, a, len(a))\n",
      "note": "**The length is part of the type.** `%T` prints `[3]int`, and `len(a)` is 3 for as long as the program runs: an array never grows or shrinks."
    },
    {
      "code": "\n\tb := a\n\tb[0] = 99\n\tfmt.Println(a, b)\n",
      "note": "**Assigning an array copies every element.** `b` is a second array, so changing it leaves `a` as it was: the output is `[1 2 3] [99 2 3]`."
    },
    {
      "code": "\n\tfmt.Println(a == [3]int{1, 2, 3}, a == b)\n",
      "note": "Two arrays of the same type compare with `==`, element by element. `a` equals a fresh `[3]int{1, 2, 3}` and no longer equals `b`."
    },
    {
      "code": "\n\tzero(a)\n\tfmt.Println(a)\n}\n",
      "note": "**A function receives its own copy of the array.** `zero` set the first element of that copy, and `a` in `main` still starts with 1."
    }
  ],
  "output": "[1 2 3] [3]int 3\n[1 2 3] [99 2 3]\ntrue false\n[1 2 3]"
}
```

So an array behaves like a single value that happens to have parts, the way an `int` does. Copying
it, comparing it and passing it all work on the whole thing at once.

## What the compiler knows about one

Because the length is in the type, the compiler knows it while compiling, and three mistakes are
caught before anything runs:

```go
package main

import "fmt"

func main() {
	a := [3]int{1, 2, 3}
	b := [4]int{1, 2, 3, 4}
	a = b

	n := len(b)
	var c [n]int

	fmt.Println(a[3], c, n)
}
```

```
ana@vm:~/arrays-type$ go run .
# example.com/arrays-type
./main.go:8:6: cannot use b (variable of type [4]int) as [3]int value in assignment
./main.go:11:9: invalid array length n
./main.go:13:16: invalid argument: index 3 out of bounds [0:3]
```

Line 8 is the type rule: a `[4]int` does not fit where a `[3]int` goes. Line 11 says the length has
to be a constant, because a type cannot depend on a value the program computes while it runs; `n`
is 4, and the compiler still refuses it. Line 13 reads the fourth element of a three-element array,
and since both the index and the length are constants, the compiler can tell it is past the end.
`[0:3]` is its way of saying the valid indices start at 0 and stop before 3.

That last one is the arrays' best feature. **An index that is a constant is checked against the
length while compiling**, so a whole class of out-of-range bug never reaches a run.

## Why you rarely see one

A fixed length is a strong promise, and most data does not keep it: a list of users, the lines of a
file and the results of a search all have a length nobody knows in advance. A function written for
`[3]int` cannot even be called with a `[4]int`. That is why ordinary Go code is full of slices,
section 03, and uses arrays where the size really is part of what the data is. A SHA-256 hash is
always 32 bytes, and lesson 13 shows `sha256.Sum256` returning one as an array of exactly that
length.
