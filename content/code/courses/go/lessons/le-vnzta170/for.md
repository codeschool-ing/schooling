---
title: One loop, three shapes
version: 1
---

Most languages arrive with a family of loops: `for`, `while`, `do … while`, `foreach`. **Go has one
keyword for repeating code, `for`, and every loop in the language is written with it.** What
changes is how much you write between `for` and the opening brace, and this program shows the
three amounts:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfor i := 0; i < 3; i++ {\n\t\tfmt.Println(\"pass\", i)\n\t}\n",
      "note": "**Three clauses, separated by semicolons**: a statement that runs once at the start, a condition, and a statement that runs after each pass. There are no parentheses around them, and the braces are required even for a body of one line."
    },
    {
      "code": "\n\tn := 100\n\tfor n > 1 {\n\t\tn /= 3\n\t}\n\tfmt.Println(\"n is\", n)\n",
      "note": "**A condition alone is Go's `while`.** The body runs for as long as `n > 1` holds: 100, 33, 11, 3 and then 1, where integer division stops it."
    },
    {
      "code": "\n\ttries := 0\n\tfor {\n\t\ttries++\n\t\tif tries == 4 {\n\t\t\tbreak\n\t\t}\n\t}\n\tfmt.Println(\"tries:\", tries)\n}\n",
      "note": "**Nothing at all is a loop that runs until something inside it stops it.** Here that is `break`, which lesson 18 is about; `if` is lesson 19's. A `return` ends it too, and so does the program exiting."
    }
  ],
  "output": "pass 0\npass 1\npass 2\nn is 1\ntries: 4"
}
```

The first shape is the one with moving parts, and the order they run in is the whole of what there
is to learn about it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"The loop for i := 0; i &lt; 3; i++ drawn as four steps. i := 0 runs once, before anything else. Then the condition i &lt; 3 is tested. If it is true, the body, fmt.Println(&quot;pass&quot;, i), runs, then i++ runs, and the arrow goes back to the test. If the test is false, the loop ends. The test is checked before every pass, so a condition that is false at the start runs the body zero times.\"><defs><marker id=\"fl-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"fl-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"86\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">i := 0</text><text x=\"75\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">runs once</text><path d=\"M130 108.0 L178 108.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-phosphor)\"></path><rect x=\"180\" y=\"86\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"235\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">i &lt; 3</text><text x=\"235\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tested before every pass</text><path d=\"M290 108.0 L348 108.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-phosphor)\"></path><text x=\"319\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">true</text><rect x=\"350\" y=\"86\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fmt.Println(&quot;pass&quot;, i)</text><text x=\"435\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the body</text><path d=\"M520 108.0 L568 108.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-phosphor)\"></path><rect x=\"570\" y=\"86\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">i++</text><text x=\"625\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">runs after every pass</text><path d=\"M625 160 L625 200 L235 200 L235 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-phosphor)\"></path><path d=\"M235 86 L235 30 L330 30\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-amber)\"></path><text x=\"244\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">false</text><text x=\"338\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the loop ends</text></svg>", "caption": "The three-clause for loop. The first clause runs once, the condition is tested before every pass, and the last clause runs after every pass."}
```

**The condition is tested before every pass, the first one included**, so a loop whose condition is
false from the start runs its body zero times. The last clause runs after the body and before the
next test, which is why the final value of `i` that the condition sees is 3, while the last one the
body printed was 2. Any of the three clauses may be left empty; with only the condition left, the
semicolons go too, and that is the second shape.

## The loop's variable belongs to the loop

`i` was declared in the first clause, and its scope is the `for` statement and nothing after it:

```go
func main() {
	for i := 0; i < 3; i++ {
		fmt.Println("pass", i)
	}
	fmt.Println("done after", i)
}
```

```
ana@vm:~/loops-scope$ go run .
# example.com/loops-scope
./main.go:9:28: undefined: i
```

It is the block scope of lesson 6, applied to a loop. If you need the counter afterwards, declare
it before the `for` with `i := 0` and leave the first clause empty: `for ; i < 3; i++`.

## There is no `while`

Lesson 1 counted Go's 25 keywords, and `while` is not one of them. Typing it out of habit gives an
error that does not mention loops at all:

```go
package main

import "fmt"

func main() {
	n := 100
	while n > 1 {
		n /= 3
	}
	fmt.Println("n is", n)
}
```

```
ana@vm:~/loops-while$ go run .
# example.com/loops-while
./main.go:7:8: syntax error: unexpected name n at end of statement
./main.go:10:2: syntax error: non-declaration statement outside function body
```

To the compiler `while` is an ordinary name, like `n`, and two names in a row are not a statement,
so it complains about the second one, at column 8. The error on line 10 is a consequence of the
first: the parser has lost track of which braces belong to what, and decides that `fmt.Println` is
outside the function. **When the first error of a list makes no sense, fix that one and run
again**, because the ones after it are often the parser stumbling over the same mistake.

## Counting with `range`

Writing `i := 0; i < n; i++` to do something `n` times is common enough that Go 1.22 gave it a
shorter form. Lessons 7 and 9 already used it as `for range 10`:

```go
package main

import "fmt"

func main() {
	for i := range 3 {
		fmt.Println("pass", i)
	}
	for range 2 {
		fmt.Println("again")
	}
}
```

```
ana@vm:~/loops-int$ go run .
pass 0
pass 1
pass 2
again
again
ana@vm:~/loops-int$ go mod edit -go=1.21 && go run .
# example.com/loops-int
./main.go:6:17: cannot range over 3 (untyped int constant): requires go1.22 or later (-lang was set to go1.21; check go.mod)
./main.go:9:12: cannot range over 2 (untyped int constant): requires go1.22 or later (-lang was set to go1.21; check go.mod)
```

`for i := range 3` gives `i` the values 0, 1 and 2, exactly like the three-clause loop at the top
of this section, and `for range 2` repeats its body without naming a counter at all. The second
run shows the version again deciding what compiles: a module whose `go` line says 1.21 is written
in a Go that had no such form, as lesson 2 explained. `range` does much more than count, and the
next section is about the rest of it.
