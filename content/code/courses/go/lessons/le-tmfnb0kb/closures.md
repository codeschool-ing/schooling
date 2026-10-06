---
title: Closures: a function that keeps a variable
version: 1
---

A function literal can use the variables around it, and that is the whole idea of a **closure**.
The common picture is that the function takes a snapshot of those values when it is created.
**It does not: a closure holds on to the variables themselves**, and it keeps them alive for as
long as the function value exists, even after the function that declared them has returned.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc counter() func() int {\n\tn := 0\n\treturn func() int {\n\t\tn++\n\t\treturn n\n\t}\n}\n",
      "note": "**`counter` returns a function, and that function uses `n`, a local variable of `counter`.** `counter` has returned by the time anybody calls the result, and `n` is still there, because the closure refers to it."
    },
    {
      "code": "\nfunc main() {\n\tnext := counter()\n\tfmt.Println(next(), next(), next())\n",
      "note": "Each call to `next` adds one to the same `n` and returns it: 1, 2, 3. The count lives between calls, with no global variable."
    },
    {
      "code": "\n\tother := counter()\n\tfmt.Println(other(), next())\n",
      "note": "A second call to `counter` runs `n := 0` again and makes a second `n`. `other` starts at 1 while `next` carries on to 4: **each call of the outer function makes new variables for its closures to keep.**"
    },
    {
      "code": "\n\tx := 1\n\tshow := func() { fmt.Println(\"x is\", x) }\n\tx = 2\n\tshow()\n}\n",
      "note": "The snapshot picture, tested. `show` was created while `x` was 1 and called after it became 2, and it prints 2, because what it holds is `x`, not the 1."
    }
  ],
  "output": "1 2 3\n1 4\nx is 2"
}
```

Where those variables live, when a function has returned and its closure has not, is a question
about memory. Lesson 24 answers it: the compiler sees that `n` outlives `counter` and keeps it on
the heap.

## Two closures, one variable

Because a closure holds the variable and not a copy, two closures made in the same call share
what they refer to. This function returns two, using the named results of lesson 20:

```go
package main

import "fmt"

func account() (deposit func(int), balance func() int) {
	total := 0
	deposit = func(amount int) {
		total += amount
	}
	balance = func() int {
		return total
	}
	return
}

func main() {
	deposit, balance := account()
	deposit(50)
	deposit(25)
	fmt.Println(balance())
}
```

```
ana@vm:~/closures-account$ go run .
75
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two closures returned by one call to account. The deposit closure, func(amount int) { total += amount }, writes to the variable total. The balance closure, func() int { return total }, reads the same variable. There is one total, holding 75 after deposits of 50 and 25, and both functions point at it.\"><defs><marker id=\"cla-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"cla-phosphor-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"270\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"165\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">deposit</text><text x=\"165\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">func(amount int) {</text><text x=\"165\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">total += amount }</text><rect x=\"420\" y=\"30\" width=\"270\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"555\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">balance</text><text x=\"555\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">func() int {</text><text x=\"555\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">return total }</text><rect x=\"285\" y=\"150\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"360\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">total</text><text x=\"360\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">75</text><path d=\"M165 100 L290 165\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cla-phosphor)\"></path><path d=\"M555 100 L430 165\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cla-phosphor-dim)\"></path><text x=\"195\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">writes it</text><text x=\"525\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reads it</text><text x=\"360\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one variable, made by one call to account</text></svg>", "caption": "deposit and balance close over the same variable. A deposit is visible to balance because there is only one total."}
```

`deposit` changes `total` and `balance` reads it, and nothing else in the program can reach it.
**The variable is private to the two functions that close over it**, which is what makes closures
useful: state with a narrow door, without declaring a type for it. Lesson 25 does the same job with
a struct and methods, which is the usual choice once there are more than two operations.

## The loop variable, and why `x := x` disappeared

A closure created inside a loop captures the loop's variable, and what that variable is changed
in Go 1.22. Lesson 2 ran a program like this one under two `go` lines to show that the `go` line
selects behaviour. This is why the answers differ:

```go
package main

import "fmt"

func main() {
	var prints []func()
	for _, name := range []string{"ana", "bia", "caio"} {
		prints = append(prints, func() { fmt.Println("hello,", name) })
	}
	for _, p := range prints {
		p()
	}
}
```

```
ana@vm:~/closures-loop$ go mod edit -go=1.21 && go vet && go run .
hello, caio
hello, caio
hello, caio
ana@vm:~/closures-loop$ go mod edit -go=1.22 && go run .
hello, ana
hello, bia
hello, caio
```

Under `go 1.21` the loop declares **one** `name` and assigns it a new value on every turn. The
three closures all hold that one variable, and by the time they are called it holds `"caio"`. It
is the two-closures-one-variable picture above with three closures, and `go vet` says nothing
about it. Under `go 1.22` and later, **each turn of the loop declares a new `name`**, so each
closure holds a variable of its own:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The loop of closures-loop under two go lines. With go 1.21, the three closures all point at one variable name, which holds caio when they are called, so each prints hello, caio. With go 1.22, each closure points at its own variable name, holding ana, bia and caio.\"><defs><marker id=\"cll-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"cll-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"175\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">go 1.21</text><text x=\"545\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">go 1.22</text><path d=\"M360 10 L360 240\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"20\" y=\"40\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">func()</text><rect x=\"130\" y=\"40\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">func()</text><rect x=\"240\" y=\"40\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">func()</text><rect x=\"115\" y=\"160\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"175\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">name</text><text x=\"175\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;caio&quot;</text><path d=\"M65 74 L131.0 158\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cll-amber)\"></path><path d=\"M175 74 L175.0 158\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cll-amber)\"></path><path d=\"M285 74 L219.0 158\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cll-amber)\"></path><text x=\"175\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">one variable for the whole loop</text><rect x=\"390\" y=\"40\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">func()</text><rect x=\"390\" y=\"160\" width=\"90\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"435\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">name</text><text x=\"435\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;ana&quot;</text><path d=\"M435 74 L435 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cll-phosphor)\"></path><rect x=\"500\" y=\"40\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">func()</text><rect x=\"500\" y=\"160\" width=\"90\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"545\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">name</text><text x=\"545\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;bia&quot;</text><path d=\"M545 74 L545 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cll-phosphor)\"></path><rect x=\"610\" y=\"40\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">func()</text><rect x=\"610\" y=\"160\" width=\"90\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"655\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">name</text><text x=\"655\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;caio&quot;</text><path d=\"M655 74 L655 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cll-phosphor)\"></path><text x=\"545\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a new variable for each turn</text></svg>", "caption": "What each closure captured. Under go 1.21 the loop has one name and the closures share it; under go 1.22 each turn declares its own."}
```

Before 1.22 the fix was a line that looks like it does nothing, `name := name`, the `x := x` of
lesson 6. It declares a new variable inside the loop's body, once per turn, and starts it as a
copy of the loop's variable, so each closure captures a different one:

```go
package main

import "fmt"

func main() {
	var prints []func()
	for _, name := range []string{"ana", "bia", "caio"} {
		name := name
		prints = append(prints, func() { fmt.Println("hello,", name) })
	}
	for _, p := range prints {
		p()
	}
}
```

```
ana@vm:~/closures-loopcopy$ go mod edit -go=1.21 && go run .
hello, ana
hello, bia
hello, caio
ana@vm:~/closures-loopcopy$ grep -n 'is122 :=' /usr/local/go/src/cmd/compile/internal/noder/writer.go
1643:	is122 := fileVersion == "" || version.Compare(fileVersion, "go1.22") >= 0
```

**From Go 1.22 the loop does what `name := name` did, so the copy is no longer needed.** The line
from the compiler's own source is where the decision is made: a file whose version is `go1.22` or
newer gets a variable per turn. Here the version comes from the `go` line of the module, which is why
the same compiler gave two answers above. You will still meet `name := name` in code written
before 2024 and in modules that never moved their `go` line, and now you know what it was for.
In a module at 1.22 or later it is harmless and can go.
