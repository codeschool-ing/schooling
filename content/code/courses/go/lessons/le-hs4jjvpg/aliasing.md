---
title: When two slices share an array
version: 1
---

Lesson 11 showed that slicing never copies: `nums[:2]` is a second view of the array `nums` already
uses. Reading through two views is harmless. The trouble starts when one of them appends, because
the wrong idea most people hold at this point is that `append` only ever adds to the slice you gave
it. **It writes after that slice's length, and if the array has room there, the room may be holding
somebody else's elements.**

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"slices\"\n)\n\nfunc main() {\n\tnums := []int{1, 2, 3, 4, 5}\n\thead := nums[:2]\n\thead = append(head, 99)\n\tfmt.Println(nums, head)\n",
      "note": "`head` is the first two elements, with a capacity of 5, because the array goes on for three more. **`append` finds room at index 2 and writes 99 there, into the array `nums` reads.** The first line of output: `nums` lost its 3 and nobody assigned to `nums`."
    },
    {
      "code": "\n\tnums = []int{1, 2, 3, 4, 5}\n\thead = nums[:2:2]\n\tfmt.Println(len(head), cap(head))\n\thead = append(head, 99)\n\tfmt.Println(nums, head)\n",
      "note": "**The third number of a full slice expression is where the capacity ends.** `nums[:2:2]` has length 2 and capacity 2, so `append` has no room, allocates a new array and copies first. `nums` keeps its 3."
    },
    {
      "code": "\n\tnums = []int{1, 2, 3, 4, 5}\n\thead = slices.Clone(nums[:2])\n\thead = append(head, 99)\n\tfmt.Println(nums, head)\n}\n",
      "note": "`slices.Clone` copies the elements into a new array straight away, so `head` shares nothing with `nums` from the first line on, whatever it does next."
    }
  ],
  "output": "[1 2 99 4 5] [1 2 99]\n2 2\n[1 2 3 4 5] [1 2 99]\n[1 2 3 4 5] [1 2 99]"
}
```

```
ana@vm:~/slices-alias$ go run .
[1 2 99 4 5] [1 2 99]
2 2
[1 2 3 4 5] [1 2 99]
[1 2 3 4 5] [1 2 99]
```

The first two cases side by side, as arrays:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Two cases of appending 99 to head, a slice of the first two elements of nums, which holds 1 2 3 4 5. With head := nums[:2], head has capacity 5, so append writes 99 into the third cell of the same array and nums becomes 1 2 99 4 5. With head := nums[:2:2], head has capacity 2, so append copies 1 and 2 into a new array, adds 99 there, and nums stays 1 2 3 4 5.\"><defs><marker id=\"sla-phosphor-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">head := nums[:2]</text><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">head = append(head, 99)</text><path d=\"M132 70 L132 64\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M132 64 L368 64\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M368 64 L368 70\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"250\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">nums   len 5  cap 5</text><rect x=\"130\" y=\"72\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"154.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"178\" y=\"72\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"202.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"226\" y=\"72\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></rect><text x=\"250.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">99</text><rect x=\"274\" y=\"72\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"298.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><rect x=\"322\" y=\"72\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"346.0\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><text x=\"70\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the array</text><path d=\"M132 104 L132 110\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M132 110 L272 110\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M272 110 L272 104\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"202\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">head   len 3  cap 5</text><text x=\"410\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">head had room up to cap 5, so</text><text x=\"410\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">append wrote 99 into the array</text><text x=\"410\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">that nums still reads</text><path d=\"M20 150 L700 150\" stroke=\"var(--scan)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">head := nums[:2:2]</text><text x=\"20\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">head = append(head, 99)</text><path d=\"M132 224 L132 218\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M132 218 L368 218\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M368 218 L368 224\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"250\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">nums   len 5  cap 5</text><rect x=\"130\" y=\"226\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"154.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"178\" y=\"226\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"202.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"226\" y=\"226\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text><rect x=\"274\" y=\"226\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"298.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text><rect x=\"322\" y=\"226\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"346.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><text x=\"70\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the array</text><path d=\"M154 258 L154 278\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sla-phosphor-dim)\"></path><path d=\"M202 258 L202 278\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sla-phosphor-dim)\"></path><text x=\"120\" y=\"268\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">copied</text><rect x=\"130\" y=\"282\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"154.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><rect x=\"178\" y=\"282\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"202.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><rect x=\"226\" y=\"282\" width=\"48\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2.2\"></rect><text x=\"250.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">99</text><text x=\"70\" y=\"297\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a new array</text><text x=\"312\" y=\"297\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">head   len 3</text><text x=\"410\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cap 2 left no room, so append</text><text x=\"410\" y=\"249\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copied 1 and 2 to a new array</text><text x=\"410\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">and nums is untouched</text></svg>", "caption": "Appending to a sub-slice. With room left in the array, append writes into it; with the capacity cut to the length, it copies first."}
```

The full slice expression `s[a:b:c]` is `s[a:b]` with the capacity cut to `c - a`. `c` may not go
past the capacity `s` already has, which is checked like the bounds in section 02. Without the
third number a sub-slice inherits all the room to the end of the array; with it, the sub-slice
owns nothing past its own length, and the next `append` has to copy.

## Where it bites

Nobody writes the program above on purpose. What people write is two slices built from a common
prefix:

```go
package main

import "fmt"

func main() {
	path := make([]string, 0, 4)
	path = append(path, "home", "ana")

	docs := append(path, "docs")
	music := append(path, "music")
	fmt.Println(docs, music)
}
```

```
ana@vm:~/slices-path$ go run .
[home ana music] [home ana music]
```

`docs` was never assigned `music`, and it prints `music` anyway. `path` has length 2 and capacity
4, so both appends found room at index 2 of the same array. The first wrote `docs` there and the
second wrote `music` over it, and `docs` and `music` are two views of that one array. **Nothing
crashed and nothing warned; the bug appears only when the capacity happens to have room**, which
is why it survives testing with one slice and turns up with another. Cutting the capacity of the
prefix fixes it:

```go
package main

import "fmt"

func main() {
	path := make([]string, 0, 4)
	path = append(path, "home", "ana")
	path = path[:len(path):len(path)]

	docs := append(path, "docs")
	music := append(path, "music")
	fmt.Println(docs, music)
}
```

```
ana@vm:~/slices-path$ go run .
[home ana docs] [home ana music]
```

Now every `append` to `path` has to copy, so `docs` and `music` each get an array of their own.

The habit worth keeping is a question to ask whenever you append to a slice you did not make
yourself: **who else can see this array?** If the answer is "possibly somebody", cut the capacity
with `s[:len(s):len(s)]` before appending, or take a `slices.Clone` and append to that.

## The caller's side

Lesson 11's `addFour` appended to its copy of a slice, and the caller's length stayed at 3. It left
open where the 4 went. When the caller's slice has spare capacity, the answer is: into the caller's
array.

```go
package main

import "fmt"

func addFour(s []int) {
	s = append(s, 4)
}

func main() {
	nums := make([]int, 3, 10)
	addFour(nums)
	fmt.Println(nums, len(nums))
	fmt.Println(nums[:4])
}
```

```
ana@vm:~/slices-caller$ go run .
[0 0 0] 3
[0 0 0 4]
```

`nums` still says length 3, as lesson 11 promised. But `nums[:4]`, stretching into the capacity as
section 02 allowed, finds the 4 that `addFour` wrote. **The function changed memory the caller owns,
past the caller's length, where nothing prints it**, and the next `append` the caller makes will
write over it. With no spare capacity, `append` inside `addFour` would have copied to a new array
instead, and the caller's array would be untouched. Lesson 21 meets the same mechanism again when a
function takes `...` arguments.
