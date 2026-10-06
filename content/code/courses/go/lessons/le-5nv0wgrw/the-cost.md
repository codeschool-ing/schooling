---
title: What a copy costs
version: 1
---

Two opposite beliefs about copies travel together. One says copying is slow, so every struct should
be passed through a pointer. The other says copying is free, so it never matters. **A copy costs in
proportion to the bytes copied**, and both beliefs are right about some size and wrong about the
rest. The way to find out which side of the line a value sits on is to time it, and a Go program
can time itself with the standard library's `testing` package, called from `main`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"testing\"\n\t\"unsafe\"\n)\n\ntype Point struct{ X, Y int }\n\ntype Record struct {\n\tID     int\n\tValues [127]int\n}\n\nvar big [1_000_000]int\n",
      "note": "Four values of four sizes. `Point` is two `int`, 16 bytes. `Record` is one `int` and an array of 127 more, 1,024 bytes. `big` is a million `int`, the array lesson 13 said this lesson would measure."
    },
    {
      "code": "\n//go:noinline\nfunc viaPoint(p Point) int { return p.X }\n\n//go:noinline\nfunc viaRecord(r Record) int { return r.ID }\n\n//go:noinline\nfunc viaArray(a [1_000_000]int) int { return a[0] }\n\n//go:noinline\nfunc viaSlice(s []int) int { return s[0] }\n",
      "note": "Each function takes one of them by value and reads one field, so the work inside is the same and only the copy differs. **`//go:noinline`, with no space after the slashes, tells the compiler not to paste the function into its caller**; without it a one-line function is inlined, and the copy being timed can be optimised away."
    },
    {
      "code": "\nfunc main() {\n\tvar p Point\n\tvar r Record\n\ts := big[:]\n\tfmt.Println(unsafe.Sizeof(p), unsafe.Sizeof(r), unsafe.Sizeof(big), unsafe.Sizeof(s))\n",
      "note": "`s` is a slice over the whole of `big`, so `viaSlice` reads the same element `viaArray` does. The first line prints the four sizes."
    },
    {
      "code": "\tfmt.Println(\"Point \", testing.Benchmark(func(b *testing.B) {\n\t\tfor b.Loop() {\n\t\t\tviaPoint(p)\n\t\t}\n\t}))\n\tfmt.Println(\"Record\", testing.Benchmark(func(b *testing.B) {\n\t\tfor b.Loop() {\n\t\t\tviaRecord(r)\n\t\t}\n\t}))\n\tfmt.Println(\"array \", testing.Benchmark(func(b *testing.B) {\n\t\tfor b.Loop() {\n\t\t\tviaArray(big)\n\t\t}\n\t}))\n\tfmt.Println(\"slice \", testing.Benchmark(func(b *testing.B) {\n\t\tfor b.Loop() {\n\t\t\tviaSlice(s)\n\t\t}\n\t}))\n}\n",
      "note": "**`testing.Benchmark` runs the function it is given and returns how long one turn of the loop took.** `b.Loop()` keeps the loop turning until it has run for about a second, the default, and the printed result is the number of turns and the time per turn."
    }
  ]
}
```

```
ana@vm:~/byvalue-cost$ go run .
16 1024 8000000 24
Point  617491884	         1.954 ns/op
Record 81182157	        15.51 ns/op
array      3415	    350746 ns/op
slice  560946219	         2.026 ns/op
```

The numbers belong to this run on the lab's machine, a 4-core Xeon at 2.10GHz; run it again and
every one of them moves a little. Read each line as the number of turns that fitted in about a
second, then the time one turn took.

| passed by value | bytes copied | time per call |
|---|---|---|
| `Point` | 16 | 1.954 ns |
| `Record` | 1,024 | 15.51 ns |
| `[1_000_000]int` | 8,000,000 | 350,746 ns |
| `[]int` over that array | 24 | 2.026 ns |

`Point` and the slice took about two nanoseconds each, which is the price of a call; the copy of 16
or 24 bytes is lost inside it. `Record` copied sixty-four times the bytes of `Point` and took about
eight times as long, still nothing a program would notice unless the call sits in a loop that runs
millions of times. **The array took about a third of a millisecond per call**, spent copying a
million `int` so that the function could read one of them, and a thousand such calls is about a
third of a second. The slice read the same element at the cost of a call, because the array was not
copied at all.

So the large array is the case lesson 13 warned about, and **the usual fix for a large array is a
slice over it**, which lesson 11 showed is 24 bytes whatever it views. The function then shares the
caller's elements instead of receiving its own, which is the trade section 03 described: cheaper,
and no longer a private copy.

## What to do with this

Most structs in real programs are a handful of fields: a name, a few numbers, a time. They sit at
the `Point` end of this measurement, and **passing them by value is the normal choice**, not a
habit to grow out of. The copy is what makes a function safe to call. Nothing it does to its
parameter can reach the caller, as section 02 showed, and that guarantee is worth more than a
few nanoseconds.

The other way to avoid a large copy is a pointer, lesson 23. It is not free either: a value whose
address is taken may have to live somewhere other than the function's own memory, and lesson 24
shows the compiler deciding where. A pointer chosen to save a copy that was never expensive buys
that cost for nothing, so measure first, the way this section did.

`testing.Benchmark` called from `main` is enough for a one-off measurement like this one. The
everyday way to write benchmarks is in test files run by `go test -bench`, which belongs to the
`go-concurrency` course with the rest of `go test`.
