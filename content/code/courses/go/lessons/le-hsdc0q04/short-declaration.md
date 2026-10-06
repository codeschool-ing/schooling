---
title: The short form, and what it refuses
version: 1
---

`:=` looks like the assignment operator of Pascal, and people who know `=` from other languages
read it as "assign". **In Go, `:=` declares, and `=` only assigns.** `name := "Ana"` creates a
variable called `name`, gives it the type of `"Ana"`, and stores the value, all in one step. It is
the same as `var name = "Ana"`, and it is the form most Go code uses inside functions:

```go
package main

import "fmt"

func main() {
	name := "Ana"
	count := 3
	ratio := 1
	exact := 1.0
	x, y := 1, 2
	y, z := 3, 4

	fmt.Println(name, count, x, y, z)
	fmt.Printf("%T %T %T\n", count, ratio, exact)
}
```

```
ana@vm:~/vars-short$ go run .
Ana 3 1 3 4
int int float64
```

The types come from the values, as with `var` and no type: `1` gives an `int` and `1.0` a
`float64`. That is why section 02 needed `var` with a type to get a `float64` holding 1.

The second-last declaration is the one to read twice. `y, z := 3, 4` has `y` on its left, and `y`
already exists. **`:=` with several names needs at least one of them to be new, and the others are
simply assigned.** So `z` was created, `y` was set to 3, and `fmt.Println` printed `1 3 4` for `x`,
`y` and `z`. The rule earns its keep from lesson 32 on, where nearly every call returns a result
and an error, and a function makes several such calls in a row with the same `err`.

## Three refusals

`:=` is a statement, and statements live inside functions. At package level only declarations
are allowed, the lines that begin with `var`, `const`, `type`, `func` or `import`, so the short form
fails there before the compiler gets past parsing:

```go
package main

import "fmt"

port := 8080

func main() {
	fmt.Println(port)
}
```

```
ana@vm:~/vars-outside$ go run .; echo $?
# example.com/vars-outside
./main.go:5:1: syntax error: non-declaration statement outside function body
1
```

Line 5, column 1: the start of `port`. The fix is `var port = 8080`, which is a declaration.

The second refusal is `:=` with nothing new on its left. `n` already exists here, so there is
nothing to declare:

```go
package main

import "fmt"

func main() {
	n := 1
	n := 2
	fmt.Println(n)
}
```

```
ana@vm:~/vars-again$ go run .; echo $?
# example.com/vars-again
./main.go:7:4: no new variables on left side of :=
1
```

Column 4 is where `:=` sits on line 7. **What was meant was almost always `n = 2`**, an assignment
to the variable that is already there, and the message points at the two characters to change.

The third is the one lesson 4 promised. A variable declared inside a function and never read is a
compile error, whichever form declared it:

```go
package main

import "fmt"

var spare = "never read"

func main() {
	total := 10
	count := 3
	fmt.Println(total)
}
```

```
ana@vm:~/vars-unused$ go run .; echo $?
# example.com/vars-unused
./main.go:9:2: declared and not used: count
1
```

`count` was refused and `spare` was not. **The rule covers variables inside functions only**; one
at package level may sit unread without complaint. Inside a function an unused variable is almost
always a mistake, such as a result you meant to print or a typo for a name you did use, and the
compiler treats it like one.

## A new variable where you meant an old one

`:=` declares a new variable in the block it is written in, even when a variable of the same name
exists outside that block. That is called **shadowing**, and it is the source of a classic Go bug,
where an `err` set inside a loop's body never reaches the `err` outside it. Lesson 6 is about
blocks and scope and shows that bug captured. For now, the habit that avoids it is the one above: when a name
already exists and you mean to change it, write `=`.

So inside a function, `:=` is the default and `var` is for the three cases of section 02. Outside
a function, `var` is all there is.
