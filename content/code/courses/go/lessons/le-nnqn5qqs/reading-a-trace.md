---
title: Reading a stack trace, frame by frame
version: 1
---

Most people read the first line of a panic and scroll past the rest, as if the lines below it were
the runtime clearing its throat. **The rest is the useful part.** The first line says what went
wrong; the stack trace says where, and how the program got there, down to a file and a line for
every function that was running. Several earlier lessons printed one and left the reading of it
to this lesson.

`~/stacks` totals an order. Each line of the order has an item and a quantity, and a quantity of
two or three earns a discount:

```go
// Command stacks totals an order, and has a bug three calls deep.
package main

import "fmt"

type line struct {
	item string
	qty  int
}

var prices = map[string]int{"coffee": 450, "cake": 700}

// discount is a percentage, by quantity bought.
var discount = []int{0, 0, 5, 10}

func unitPrice(item string, qty int) int {
	return prices[item] * (100 - discount[qty]) / 100
}

func lineTotal(l line) int {
	return unitPrice(l.item, l.qty) * l.qty
}

func orderTotal(lines []line) int {
	total := 0
	for _, l := range lines {
		total += lineTotal(l)
	}
	return total
}

func main() {
	order := []line{{"coffee", 2}, {"cake", 4}}
	fmt.Println(orderTotal(order))
}
```

Somebody ordered four cakes:

```
ana@vm:~/stacks$ go build && ./stacks; echo $?
panic: runtime error: index out of range [4] with length 4

goroutine 1 [running]:
main.unitPrice(...)
	/home/ana/stacks/main.go:17
main.lineTotal(...)
	/home/ana/stacks/main.go:21
main.orderTotal(...)
	/home/ana/stacks/main.go:27
main.main()
	/home/ana/stacks/main.go:34 +0x15b
2
```

## Line by line

**`panic: runtime error: index out of range [4] with length 4`** is what went wrong, and both numbers
in it are evidence. Something asked for element 4 of a slice with four elements, 0 to 3.

**`goroutine 1 [running]:`** says whose stack follows: goroutine number 1, the one that runs `main`,
which was running when it panicked. A program with more goroutines prints the one that panicked;
lesson 36 showed one started by `main`, whose trace ended with a `created by main.main` line.

Then come the **frames**, two lines each: the function, with its package, and on the next line,
indented, the file and the line. **They are printed deepest first.** The top frame is the function
that was running when the panic happened, and each frame below it is the function that called the
one above:

| frame | line | what is on that line |
|---|---|---|
| `main.unitPrice` | `main.go:17` | `discount[qty]`, where the panic happened |
| `main.lineTotal` | `main.go:21` | the call to `unitPrice` |
| `main.orderTotal` | `main.go:27` | the call to `lineTotal`, inside the loop |
| `main.main` | `main.go:34` | the call to `orderTotal` |

**The top frame's line is where the program broke; every other frame's line is where that function
made the call above it.** So the trace reads as a sentence from the top: line 17 failed, inside a call
made at line 21, inside a call made at line 27, inside `main` at line 34. The calls happened in the
opposite order, and the figure puts the two orders side by side:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The four calls in ~/stacks and the trace that reports them, side by side. On the left, the calls in the order the program made them: main.main at line 34 called orderTotal, which at line 27 called lineTotal, which at line 21 called unitPrice, which panicked at line 17. On the right, the trace in the order the runtime prints it: unitPrice and line 17 first, then lineTotal, orderTotal, and main.main last. Each call is joined to its place in the trace, and the lines cross, because the trace is printed deepest first.\"><defs><marker id=\"tr-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the calls, in the order the program made them</text><text x=\"550\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the trace, in the order the runtime prints it</text><rect x=\"40\" y=\"44\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main.main()</text><text x=\"56\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">main.go:34</text><path d=\"M70 84 L70 102\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tr-wire)\"></path><text x=\"80\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">calls</text><rect x=\"420\" y=\"224\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"436\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main.main()</text><text x=\"436\" y=\"253\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">main.go:34</text><path d=\"M300 64 L420 244\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"40\" y=\"104\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main.orderTotal(...)</text><text x=\"56\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">main.go:27</text><path d=\"M70 144 L70 162\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tr-wire)\"></path><text x=\"80\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">calls</text><rect x=\"420\" y=\"164\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"436\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main.orderTotal(...)</text><text x=\"436\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">main.go:27</text><path d=\"M300 124 L420 184\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"40\" y=\"164\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main.lineTotal(...)</text><text x=\"56\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">main.go:21</text><path d=\"M70 204 L70 222\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tr-wire)\"></path><text x=\"80\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">calls</text><rect x=\"420\" y=\"104\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"436\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main.lineTotal(...)</text><text x=\"436\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">main.go:21</text><path d=\"M300 184 L420 124\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"40\" y=\"224\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main.unitPrice(...)</text><text x=\"56\" y=\"253\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">main.go:17</text><rect x=\"420\" y=\"44\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"436\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">main.unitPrice(...)</text><text x=\"436\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">main.go:17</text><path d=\"M300 244 L420 64\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"170\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">panics here</text><text x=\"550\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read from the top: where it broke, then who asked</text></svg>", "caption": "The same four calls, made top to bottom on the left and printed bottom first on the right. A trace starts where the program broke and walks back to main."}
```

Put back together with the message, the trace has found the bug without a debugger. Line 17 indexed
`discount` with `qty`, the quantity was 4, and `discount` only covers quantities 0 to 3. A quantity
of four or more needs a rule of its own, and the program never had one. The exit status, 2, is the
panic's, as lesson 36 showed.

## `(...)` and `+0x15b`

Three of the four frames end in `(...)` and have no `+0x` after their line, and that is the
compiler at work. **A `(...)` frame was inlined**: the compiler copied the function's body into its
caller instead of calling it, so at run time there was no separate call, and the runtime rebuilds
the frame from a table that records where the copied code came from. The `-m` flag that lesson 24
used for escape analysis also reports these decisions:

```
ana@vm:~/stacks$ go build -gcflags=-m 2>&1 | grep 'inlining call'
./main.go:21:18: inlining call to unitPrice
./main.go:27:21: inlining call to lineTotal
./main.go:27:21: inlining call to unitPrice
./main.go:34:24: inlining call to orderTotal
./main.go:34:13: inlining call to fmt.Println
./main.go:34:24: inlining call to lineTotal
./main.go:34:24: inlining call to unitPrice
```

All three small functions went into `main`, which is why only `main.main` is a real frame. The code
that prints a frame says the same, in the runtime's own source:

```
ana@vm:~/stacks$ grep -n -A12 'printFuncName(name)' $(go env GOROOT)/src/runtime/traceback.go | head -13
1050:			printFuncName(name)
1051-			print("(")
1052-			if iu.isInlined(uf) {
1053-				print("...")
1054-			} else {
1055-				argp := unsafe.Pointer(u.frame.argp)
1056-				printArgs(f, argp, u.symPC())
1057-			}
1058-			print(")\n")
1059-			print("\t", file, ":", line)
1060-			if !iu.isInlined(uf) {
1061-				if u.frame.pc > f.entry() {
1062-					print(" +", hex(u.frame.pc-f.entry()))
```

An inlined frame gets `...` where the arguments would go and no offset. A real frame gets its
arguments and **`+0x15b`, the distance in bytes from the start of the function's machine code to the
instruction that was running**: `pc` minus the function's entry. It identifies the exact
instruction, but only in this exact binary. Rebuild after any change and the number moves, while the
line number keeps meaning the same thing. Read the line.

### The arguments, and the question marks

With inlining turned off, `-l` in lesson 24, `unitPrice` gets a frame of its own, and the runtime
prints what it can find of its arguments:

```
ana@vm:~/stacks$ go build -gcflags=-l -o noinline . && ./noinline 2>&1 | grep -A1 '^main.unitPrice'
main.unitPrice({0x49b0c7?, 0x41b4f9?}, 0x4)
	/home/ana/stacks/main.go:17 +0x8f
```

The arguments are printed as machine words, in hexadecimal. `item` is a string, which lesson 9
showed is a pointer and a length, so it takes two words inside braces. `qty` is one word, `0x4`, the
same 4 as in the message. **A `?` after a word means the runtime cannot vouch for it**: the source
above prints one when the slot that held the value was no longer in use at that instruction, so the
number may be left over from something else. `0x41b4f9` cannot be the length of `"cake"`, and the `?`
said so. Treat the arguments as hints, and trust the ones with no question mark.
