---
title: Labels, for the loop you mean
version: 1
---

The usual picture of `break` is that it gets you out. It gets you out of **one** statement: the
innermost `for`, `switch` or `select` around it. With two loops, one inside the other, that is
the inner loop, and the outer one carries on as though nothing had happened. This program, in
`~/flow-grid`, means to find the first value above 20, reading row by row:

```go
// Command grid finds the first value above 20, reading row by row.
package main

import "fmt"

func main() {
	grid := [][]int{
		{1, 4, 9},
		{16, 25, 36},
		{49, 64, 81},
	}
	for r, row := range grid {
		for c, v := range row {
			if v > 20 {
				fmt.Println("found", v, "at row", r, "column", c)
				break
			}
		}
	}
}
```

```
ana@vm:~/flow-grid$ go run .
found 25 at row 1 column 1
found 49 at row 2 column 0
```

Two answers to a question that has one. The `break` left the inner loop at 25, and the outer loop
went on to row 2 and found 49 there. **A `break` inside two loops leaves the inner one only.**

## Naming the loop

A **label** is a name followed by a colon, written on the line before a statement, and `break`
and `continue` can then name the loop they mean. The fix is to label the outer loop. Adding the
label and forgetting to use it is refused, which is the first thing most people meet:

```
ana@vm:~/flow-grid$ go run .
# example.com/grid
./main.go:12:1: label search defined and not used
```

Line 12, column 1: `gofmt` writes a label one level to the left of the statement it names, so
that it stands out, and inside `main` that is the margin itself. An unused label is refused like
the unused import of lesson 4: Go treats a name nothing uses as a mistake rather than as clutter.
Naming it on the `break` finishes the fix:

```go
search:
	for r, row := range grid {
		for c, v := range row {
			if v > 20 {
				fmt.Println("found", v, "at row", r, "column", c)
				break search
			}
		}
	}
```

```
ana@vm:~/flow-grid$ go run .
found 25 at row 1 column 1
```

`continue` takes a label the same way, and `continue rows` means "the next turn of the loop
called `rows`", abandoning the inner loop wherever it had got to. This program, in `~/flow-rows`,
adds up each row and gives up on a row as soon as it finds a negative value in it:

```go
rows:
	for r, row := range grid {
		sum := 0
		for _, v := range row {
			if v < 0 {
				fmt.Println("row", r, "skipped: it has", v)
				continue rows
			}
			sum += v
		}
		fmt.Println("row", r, "sum", sum)
	}
```

```
ana@vm:~/flow-rows$ go run .
row 0 sum 14
row 1 skipped: it has -25
row 2 sum 194
```

Row 1 printed no sum. Its `-25` sent the program to the next turn of `rows`, past the `Println`
at the end of the outer body, which a plain `continue` would not have skipped. Four statements,
four destinations:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" aria-label=\"Where four statements inside an inner loop send the program. The outer loop carries the label outer and contains the inner loop. continue goes to the next turn of the inner loop. break leaves the inner loop and goes on with the rest of the outer loop&#x27;s body. continue outer goes to the next turn of the outer loop. break outer leaves both loops.\"><defs><marker id=\"flw-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"flw-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M30 55 L24 55 L24 313 L30 313\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M54 85 L48 85 L48 253 L54 253\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"56\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">end of the outer loop</text><text x=\"80\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">end of the inner loop</text><text x=\"36\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">outer:</text><text x=\"36\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">for r := range grid {</text><text x=\"60\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">for c := range row {</text><text x=\"84\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">continue</text><text x=\"84\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">break</text><text x=\"84\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">continue outer</text><text x=\"84\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">break outer</text><text x=\"60\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">}</text><text x=\"60\" y=\"274\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">fmt.Println(r)</text><text x=\"36\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">}</text><text x=\"36\" y=\"334\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">fmt.Println(&quot;done&quot;)</text><path d=\"M145 124 L340 124 L340 94 L212 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#flw-phosphor)\"></path><text x=\"458\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">continue</text><text x=\"516\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">next turn of the inner loop</text><path d=\"M125 154 L372 154 L372 274 L212 274\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#flw-phosphor)\"></path><text x=\"458\" y=\"274\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">break</text><text x=\"498\" y=\"274\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the rest of the outer loop&#x27;s body</text><path d=\"M184 184 L404 184 L404 64 L212 64\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#flw-amber)\"></path><text x=\"458\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">continue outer</text><text x=\"554\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">next turn of the outer loop</text><path d=\"M165 214 L436 214 L436 334 L212 334\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#flw-amber)\"></path><text x=\"458\" y=\"334\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">break outer</text><text x=\"535\" y=\"334\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">past both loops</text></svg>", "caption": "Where each statement goes. Without a label, break and continue act on the innermost loop; with one, on the loop the label names."}
```

A label names a statement **that encloses the `break`**, and nothing else. A label on the inner
loop cannot be used after that loop has ended, even from inside the outer one:

```go
package main

import "fmt"

func main() {
	for r := 0; r < 3; r++ {
	inner:
		for c := 0; c < 3; c++ {
			fmt.Println(r, c)
		}
		if r == 1 {
			break inner
		}
	}
}
```

```
ana@vm:~/flow-wrong$ go build
# example.com/wrong
./main.go:12:10: invalid break label inner
```

## A break inside a switch

The `switch` of lesson 19 is the other statement `break` belongs to, and that is where this
goes wrong in real code. Each `case` ends by itself in Go, so a `break` inside one is never needed
to stop the next case from running; a programmer who writes one there almost always means the
loop around it. This program, in `~/flow-switch`, should stop at `"stop"`:

```go
// Command commands runs a list of commands and should stop at "stop".
package main

import "fmt"

func main() {
	commands := []string{"add", "list", "stop", "delete"}
	for _, c := range commands {
		switch c {
		case "stop":
			fmt.Println("stopping")
			break
		default:
			fmt.Println("running", c)
		}
	}
	fmt.Println("done")
}
```

```
ana@vm:~/flow-switch$ go run .
running add
running list
stopping
running delete
done
ana@vm:~/flow-switch$ go vet; echo $?
0
```

It said `stopping` and then ran `delete`. **The `break` left the `switch`, which was about to end
anyway, and the loop went on to the next command.** It compiles, it runs, and `go vet` exits 0,
so the only thing that reports this bug is the command that should not have run. The fix is the
same label as before, on the loop:

```go
loop:
	for _, c := range commands {
		switch c {
		case "stop":
			fmt.Println("stopping")
			break loop
		default:
			fmt.Println("running", c)
		}
	}
```

```
ana@vm:~/flow-switch$ go run .
running add
running list
stopping
done
```

When the loop is the last thing a function does, `return` inside the `case` is the other fix, and
often the clearer one. A label is for when the function has more to do after the loop, as `main`
here does with `done`.
