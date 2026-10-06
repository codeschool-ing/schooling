---
title: Scope, and the variable that hides another
version: 1
---

A name in Go is visible from the point it is declared to the end of the block that holds it, and
nowhere else. **A block is, almost always, a pair of braces**, and blocks nest. A name declared in
an inner block may reuse a name from an outer one, and inside the inner block the new one hides the
old. That is called shadowing, and it is legal, quiet and the source of one well-known bug, shown
at the end of this section.

## Five levels, from outside in

| scope | what is declared there | visible in |
|---|---|---|
| universe | the predeclared names: `int`, `string`, `len`, `true`, `nil`, `iota`, … | every file of every package |
| package | everything declared outside a function, in any file of the package | every file of that package |
| file | the imports | that one file |
| function | parameters, results and the variables of the body | that function |
| block | anything declared inside braces, and in the first clause of an `if`, `for` or `switch` | that block |

`go doc builtin` lists the universe: it documents `len`, `nil`, `iota` and the rest as if they
were a package, though nothing ever imports one. The middle row is the one people do not expect,
so here is a package of two files, `~/zero-scope`:

```go
package main

import "fmt"

var limit = 3

func main() {
	x := 1
	if x < limit {
		x := x
		x += 10
		fmt.Println("inside: ", x)
	}
	fmt.Println("outside:", x)
	report()
}
```

```go
package main

func report() {
	fmt.Println("report sees limit =", limit)
}
```

```
ana@vm:~/zero-scope$ go run .
# example.com/scope
./report.go:4:2: undefined: fmt
```

`report.go` uses `limit`, declared in the other file, and the compiler has no complaint about it.
It uses `fmt` too, and that is refused. **A package-level name is shared by every file of the
package; an import belongs to the one file that wrote it.** Add `import "fmt"` to `report.go` and
the program runs:

```go
package main

import "fmt"

func report() {
	fmt.Println("report sees limit =", limit)
}
```

```
ana@vm:~/zero-scope$ go run .
inside:  11
outside: 1
report sees limit = 3
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Five nested scopes in the two files of ~/zero-scope. The universe holds the predeclared names such as int, len, true, nil and iota. Inside it, package main holds limit, main and report, visible from both files. Each file has its own import of fmt. Function main declares x, and the if block inside it declares a second x that hides the first. Function report sees limit but not x.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"310\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"22\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">universe</text><text x=\"90\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">int  len  true  nil  iota  …</text><rect x=\"28\" y=\"46\" width=\"664\" height=\"262\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">package</text><text x=\"101\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main:  var limit   func main   func report</text><rect x=\"46\" y=\"84\" width=\"390\" height=\"212\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"58\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">file</text><text x=\"98\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main.go:  import &quot;fmt&quot;</text><rect x=\"452\" y=\"84\" width=\"222\" height=\"212\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"464\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">file</text><text x=\"504\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">report.go:  import &quot;fmt&quot;</text><rect x=\"64\" y=\"122\" width=\"354\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"76\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">function</text><text x=\"144\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main:  x := 1</text><rect x=\"470\" y=\"122\" width=\"186\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"482\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">function</text><text x=\"550\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">report</text><text x=\"563\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sees limit; cannot see x</text><rect x=\"82\" y=\"162\" width=\"318\" height=\"104\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"94\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">block</text><text x=\"141\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">if x &lt; limit { … }</text><text x=\"100\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">x := x</text><text x=\"160\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a second x, which hides the first</text><text x=\"100\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">x += 10</text></svg>", "caption": "The scopes of ~/zero-scope, outermost first. A name is visible in the box that declares it and in every box inside that one; a box that declares the same name again hides the outer one."}
```

## x := x

Inside the `if`, `x := x` declares a second `x` and starts it as a copy of the first. It reads
like a statement that does nothing, and it does something precise: the new `x` only comes into
scope once its declaration is finished, so the `x` on the right is still the outer one. Adding 10
to the inner `x` changed nothing outside, which is why the program printed `11` inside and `1`
outside. You will see `x := x` in older Go code that hands a loop variable to a function; lesson 21
explains why Go 1.22 made most of those unnecessary.

The universe can be shadowed too, because `len`, `int` and `true` are predeclared names and not
keywords. Nothing stops you calling a variable `len`, until you need the function:

```go
package main

import "fmt"

func main() {
	len := 3
	fmt.Println(len("abc"))
}
```

```
ana@vm:~/zero-universe$ go build
# example.com/universe
./main.go:7:14: invalid operation: cannot call len (variable of type int): int is not a function
```

## The shadowed err

This function is meant to add up a list of numbers written as text and to stop, with an error, at
the first one that is not a number. `strconv.Atoi` turns a string into an `int` and returns an
error when it cannot; lesson 10 meets it properly.

```go
// Command total adds up its arguments and should stop at the first bad one.
package main

import (
	"fmt"
	"strconv"
)

func total(args []string) (int, error) {
	sum := 0
	var err error
	for _, a := range args {
		n, err := strconv.Atoi(a)
		if err != nil {
			break
		}
		sum += n
	}
	return sum, err
}

func main() {
	fmt.Println(total([]string{"1", "2", "x", "4"}))
}
```

```
ana@vm:~/zero-shadow$ go run .
3 <nil>
ana@vm:~/zero-shadow$ go vet; echo $?
0
```

It stopped at `"x"`, as it should, and then reported no error. **The `:=` inside the loop declared
a new `n` and a new `err`**, because the loop body is a block of its own and both names were new to
it. The `err` that received the failure was the inner one, and it went out of scope at the end of
the iteration. The `err` that `total` returned was the outer one, which nothing ever assigned, so
it was still its zero value, `nil`.

Nothing caught it. The inner `err` is used by the `if`, so the compiler's "declared and not used"
from lesson 5 had nothing to say, and `go vet` exited 0. The fix is to stop needing the outer
variable at all and return from where the error is known:

```go
func total(args []string) (int, error) {
	sum := 0
	for _, a := range args {
		n, err := strconv.Atoi(a)
		if err != nil {
			return sum, err
		}
		sum += n
	}
	return sum, nil
}
```

```
ana@vm:~/zero-shadow$ go run .
3 strconv.Atoi: parsing "x": invalid syntax
```

**When `:=` appears inside a block, ask of every name on its left whether you meant a new
variable.** Where you meant the outer one, write `=` and declare whatever is new before it with
`var`. Where, as here, the outer variable only existed to carry a value out of the block, the
cleaner fix is usually to return from inside.
