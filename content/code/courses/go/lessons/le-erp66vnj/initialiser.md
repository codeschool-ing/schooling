---
title: An if with an initialiser, and the early return
version: 1
---

An `if` can begin with a short statement of its own, separated from the condition by a semicolon:
`if n, err := strconv.Atoi(s); err != nil`. The statement runs first, then the condition is
tested. **The names it declares belong to the `if`**, which is the block row of the scope table in
lesson 6: they exist in the condition and in the blocks of the chain, and not after it. This
program, in `~/cond-init`, reads three strings as numbers:

```go
// Command size says how large each number in a list is.
package main

import (
	"fmt"
	"strconv"
)

func main() {
	for _, s := range []string{"42", "7", "forty-two"} {
		if n, err := strconv.Atoi(s); err != nil {
			fmt.Println("not a number:", err)
		} else if n > 10 {
			fmt.Println(n, "is more than ten")
		} else {
			fmt.Println(n, "is ten or less")
		}
	}
}
```

```
ana@vm:~/cond-init$ go run .
42 is more than ten
7 is ten or less
not a number: strconv.Atoi: parsing "forty-two": invalid syntax
```

The picture people bring is that `n` belongs to the first block, the one the initialiser sits on,
and that is half of it. **The `else if` and the `else` see `n` and `err` too**: the `else if`
tests `n > 10` and the `else` prints `n`, and both are past the block where the initialiser was
written. What they cannot be seen from is anywhere after the last closing brace. Adding one line
after the chain, still inside the loop, is refused:

```go
		fmt.Println("done with", n)
```

```
ana@vm:~/cond-init$ go build
# example.com/size
./main.go:18:28: undefined: n
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The scope of the variables an if statement declares in its initialiser. In the loop of ~/cond-init, if n, err := strconv.Atoi(s) declares n and err. They are visible in the condition and in every branch of the chain: the if, the else if and the else. The line after the chain, fmt.Println(&quot;done with&quot;, n), is outside it, and the compiler says undefined: n.\"><defs><marker id=\"cis-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"38\" y=\"41\" width=\"326\" height=\"194\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"24\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">for _, s := range []string{&quot;42&quot;, &quot;7&quot;, &quot;forty-two&quot;} {</text><text x=\"48\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">if n, err := strconv.Atoi(s); err != nil {</text><text x=\"72\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fmt.Println(&quot;not a number:&quot;, err)</text><text x=\"48\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">} else if n &gt; 10 {</text><text x=\"72\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fmt.Println(n, &quot;is more than ten&quot;)</text><text x=\"48\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">} else {</text><text x=\"72\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fmt.Println(n, &quot;is ten or less&quot;)</text><text x=\"48\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">}</text><text x=\"48\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">fmt.Println(&quot;done with&quot;, n)</text><text x=\"24\" y=\"278\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">}</text><path d=\"M370 44 L378 44 L378 232 L370 232\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M378 138 L392 138\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"400\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the scope of n and err:</text><text x=\"400\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the condition, and every branch</text><text x=\"400\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">of the chain, else included</text><path d=\"M392 250 L252 250\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cis-amber)\"></path><text x=\"400\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">undefined: n</text><text x=\"400\" y=\"274\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">outside the chain, n is gone</text></svg>", "caption": "Where the names of an if's initialiser exist: from the initialiser to the closing brace of the last else, and nowhere after."}
```

That is the point of the form. `n` and `err` are needed for exactly as long as the decision takes,
and the initialiser keeps them there: the rest of the function cannot use a stale `err` by
mistake, and the next `if` can declare its own `err` without colliding with this one. The `:=` of
an initialiser declares new names like any other `:=` in a block, so lesson 6's shadowed `err`
applies here too: if an `err` already exists outside, the one in the initialiser is a different
variable.

When the value is needed after the decision, the initialiser is the wrong form. Write the
statement on a line of its own and test it on the next, as this function in `~/cond-after` does:

```go
func double(s string) (int, error) {
	n, err := strconv.Atoi(s)
	if err != nil {
		return 0, err
	}
	return n * 2, nil
}
```

```
ana@vm:~/cond-after$ go run .
42 <nil>
0 strconv.Atoi: parsing "twenty-one": invalid syntax
```

`n` outlives the `if`, because it was declared before it, and the last line uses it. That shape,
a call and then `if err != nil` with a `return` inside, is the most common sight in Go code.
Lesson 20 is about functions returning two values, and lesson 32 about the `err` half.

## Return early, and keep the rest flat

An `else` after a block that ends in `return` has nothing to do: the program only reaches the
line after the `if` when the `if` did not return. Written with every `else` anyway, a function
nests one level deeper for each decision. Here is the same price rule twice, in `~/cond-early`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command price works out a ticket's price twice, in two shapes.\npackage main\n\nimport \"fmt\"\n\nfunc priceNested(age int, member bool) int {\n\tif age >= 0 {\n\t\tif age < 12 {\n\t\t\treturn 0\n\t\t} else {\n\t\t\tif member {\n\t\t\t\treturn 15\n\t\t\t} else {\n\t\t\t\treturn 20\n\t\t\t}\n\t\t}\n\t} else {\n\t\treturn -1\n\t}\n}\n",
      "note": "**Every decision opens a block, and the answers end up at the bottom of a staircase.** The case of a bad age, which is the first thing checked, is answered last, eleven lines below its test."
    },
    {
      "code": "\nfunc priceFlat(age int, member bool) int {\n\tif age < 0 {\n\t\treturn -1\n\t}\n\tif age < 12 {\n\t\treturn 0\n\t}\n\tif member {\n\t\treturn 15\n\t}\n\treturn 20\n}\n",
      "note": "**Each special case is handled and left at once, and what remains is the ordinary case.** The bad age is answered on the line after its test, and the last line, at the left margin, is the price most people pay. Each `if` reads alone, without remembering which blocks it is inside."
    },
    {
      "code": "\nfunc main() {\n\tfmt.Println(priceNested(8, false), priceNested(30, true), priceNested(30, false), priceNested(-1, false))\n\tfmt.Println(priceFlat(8, false), priceFlat(30, true), priceFlat(30, false), priceFlat(-1, false))\n}\n",
      "note": "The same four tickets through both: a child, a member, an adult who is not one, and an age that cannot be right."
    }
  ],
  "output": "0 15 20 -1\n0 15 20 -1\n"
}
```

```
ana@vm:~/cond-early$ go run .
0 15 20 -1
0 15 20 -1
```

The two functions agree on every ticket; they differ in what a reader has to hold in mind.
**Handle the failure or the special case first, return, and let the main path run down the left
margin.** Go code is written this way almost everywhere, and it is why an `if` whose block ends in
`return` is so seldom followed by `else`. The `-1` for a bad age is a stand-in here; lesson 32
replaces numbers like that with an error.
