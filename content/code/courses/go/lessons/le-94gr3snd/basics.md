---
title: Addresses, & and *
version: 1
---

People who have met pointers in C tend to arrive with a warning attached: pointers are where
programs crash, read memory that was freed, and walk off the end of an array. **A Go pointer is an
address with a type, and the language leaves out what made C's dangerous**: there is no arithmetic
on it, and the variable it points at stays alive for as long as the pointer does. What is left is
the one thing lesson 22 needed and did not have, a way for a function to reach the caller's
variable instead of a copy of it:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc double(n *int) {\n\t*n = *n * 2\n}\n",
      "note": "**`*int` is the type \"pointer to an `int`\".** The parameter is still a copy, as lesson 22 said, and what it copies is an address. `*n` follows that address, so `*n = *n * 2` reads the `int` at the other end, doubles it and writes it back there."
    },
    {
      "code": "\nfunc main() {\n\tx := 21\n\tp := &x\n\tfmt.Printf(\"%T\\n\", p)\n\tfmt.Println(*p, p == &x)\n",
      "note": "**`&x` is the address of `x`**, and `%T` prints its type, `*int`. `*p` reads `x` through it: 21. Two pointers are equal when they lead to the same variable, so `p == &x` is `true`."
    },
    {
      "code": "\n\t*p = 30\n\tfmt.Println(x)\n",
      "note": "Writing through `p` writes `x`. Nothing assigned to `x` by name, and it prints 30."
    },
    {
      "code": "\n\tdouble(&x)\n\tfmt.Println(x)\n}\n",
      "note": "The repair of lesson 22's `double`: pass the address, and the function writes into the caller's variable. `x` is now 60."
    }
  ],
  "output": "*int\n21 true\n30\n60"
}
```

```
ana@vm:~/pointers$ go run .
*int
21 true
30
60
```

The star does two jobs, and telling them apart is most of the reading. **In a type, `*int` says
"pointer to an `int`"; in an expression, `*p` follows the pointer to the variable at the other
end.** `&` only appears in expressions, and it goes the other way: from a variable to its address.
`*p` is a variable in its own right, so it can sit on the left of `=`, as `*p = 30` did.

## nil: the pointer to nothing

A pointer declared without a value is `nil`, the zero value of every pointer type. Printing one is
harmless. Following one is not:

```go
package main

import "fmt"

func main() {
	var p *int
	fmt.Println(p == nil, p)
	fmt.Println(*p)
}
```

```
ana@vm:~/pointers-nil$ go run .
true <nil>
panic: runtime error: invalid memory address or nil pointer dereference
[signal SIGSEGV: segmentation violation code=0x1 addr=0x0 pc=0x499e46]

goroutine 1 [running]:
main.main()
	/home/ana/pointers-nil/main.go:8 +0x66
exit status 2
```

`addr=0x0` is the address the program tried to read: nil, which no variable ever has. The processor
refused, the operating system sent the `SIGSEGV` signal, and the Go runtime turned it into the
panic on the line above, naming line 8, where `*p` is. Lessons 36 and 37 read panics and their
traces in full. **A nil pointer can be printed and compared, and following it stops the
program.** Behind the panic there is a pointer that some path through the code never set, which is
why a pointer that can be nil is checked with `p != nil` before anything follows it.

## No arithmetic

In C, `p + 1` is the element after the one `p` points at, which is how a loop walks an array and
how it walks off the end. Go refuses both spellings:

```go
package main

import "fmt"

func main() {
	nums := [3]int{10, 20, 30}
	p := &nums[0]
	p++
	q := p + 1
	fmt.Println(*p, *q)
}
```

```
ana@vm:~/pointers-arith$ go run .
# example.com/arith
./main.go:8:2: invalid operation: p++ (non-numeric type *int)
./main.go:9:7: invalid operation: p + 1 (mismatched types *int and untyped int)
```

A pointer is not a number to the compiler, so it has no `++` and no `+`. To move through an array
you index it, `nums[1]`, and the bounds checks of lessons 11 and 12 come with the index. The standard
library does have a way to add to an address, `unsafe.Add`, in the package whose name is the
warning; nothing in this course needs it.

## Returning the address of a local variable

In C, a function that returns the address of one of its own local variables returns a bug: the
variable's memory is reused once the function returns. In Go it is an ordinary thing to write:

```go
package main

import "fmt"

func newCounter() *int {
	n := 0
	return &n
}

func main() {
	a := newCounter()
	b := newCounter()
	*a++
	*a++
	*b++
	fmt.Println(*a, *b, a == b)
}
```

```
ana@vm:~/pointers-local$ go run .
2 1 false
```

Each call made a new `n` and returned its address, so `a` and `b` lead to two different counters:
one incremented twice, the other once. **A variable in Go lives for as long as something can still
reach it**, whatever function it was declared in. How the compiler arranges that, and what it costs,
is lesson 24.
