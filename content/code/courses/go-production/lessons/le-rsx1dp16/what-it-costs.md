---
title: What the heap costs
version: 1
---

The report is a prediction, made at compile time about code that has not run. **What a program
actually does is counted at run time, and the two can disagree in both directions.** Section 04's
`Sized` does not escape and still allocates for five elements; section 03's `Box` escapes and, as
this section shows, sometimes does not allocate. So the report says where to look, and two tools from
the `testing` package say what happened: `testing.AllocsPerRun`, which counts, and a benchmark run
with `-benchmem`, which counts and times.

## Counting allocations

`testing.AllocsPerRun(runs, f)` calls `f` once to warm up, then `runs` times, and returns the average
number of heap allocations per call. The arguments and results go through package-level variables,
because a constant argument would let the compiler work the answer out in advance and an unused result
would let it delete the call. `why/allocs_test.go`:

```go
package why

import "testing"

// Package-level variables, so that the compiler can neither work out the
// arguments in advance nor throw the results away.
var (
	small, large = 7, 1000
	four, five   = 4, 5
	sinkAny      any
	sinkInt      int
)

func TestAllocs(t *testing.T) {
	cases := []struct {
		name string
		f    func()
	}{
		{"Box(7)", func() { sinkAny = Box(small) }},
		{"Box(1000)", func() { sinkAny = Box(large) }},
		{"Sized(4)", func() { sinkInt = Sized(four) }},
		{"Sized(5)", func() { sinkInt = Sized(five) }},
		{"Distance(4, 5)", func() { sinkInt = Distance(four, five) }},
	}
	for _, c := range cases {
		t.Logf("%-15s %v allocs", c.name, testing.AllocsPerRun(1000, c.f))
	}
}
```

```
ana@vm:~/escape$ go test -run Allocs -v ./why
=== RUN   TestAllocs
    allocs_test.go:26: Box(7)          0 allocs
    allocs_test.go:26: Box(1000)       1 allocs
    allocs_test.go:26: Sized(4)        0 allocs
    allocs_test.go:26: Sized(5)        1 allocs
    allocs_test.go:26: Distance(4, 5)  0 allocs
--- PASS: TestAllocs (0.00s)
PASS
ok  	example.com/escape/why	(cached)
```

**`Box(7)` allocates nothing although the report said `n escapes to heap`.** The runtime keeps a
table of the values 0 to 255, `staticuint64s` in `runtime/iface.go`, and an interface holding one of
them points into the table instead of at a new copy. `Box(1000)` gets its eight bytes from the heap.
`Sized` splits exactly where section 04 put the line: four `int`s fit the 32 bytes reserved in the
frame and five do not. `Distance`, with `New` inlined, allocates nothing.

## Timing them

Three benchmarks, in `why/cost_test.go`:

```schooling-example
{
  "language": "go",
  "file": "why/cost_test.go",
  "parts": [
    {
      "code": "package why\n\nimport (\n\t\"fmt\"\n\t\"testing\"\n\n\t\"example.com/escape/point\"\n)\n\nfunc BenchmarkDistance(b *testing.B) {\n\tfor b.Loop() {\n\t\tsinkInt = Distance(four, five)\n\t}\n}\n",
      "note": "`Distance` as section 04 left it, with `New` inlined. The arguments come from the package-level variables of `allocs_test.go`, the result goes into `sinkInt`, and `b.Loop` runs the body as many times as it takes to get a stable time."
    },
    {
      "code": "// call does Distance's work behind a call that is never inlined, with the\n// Point in call's own frame.\n//\n//go:noinline\nfunc call(x, y int) int {\n\tp := point.Point{X: x, Y: y}\n\treturn point.Sum(&p)\n}\n\nfunc BenchmarkCall(b *testing.B) {\n\tfor b.Loop() {\n\t\tsinkInt = call(four, five)\n\t}\n}\n",
      "note": "**The control.** `call` does `Distance`'s work, but `//go:noinline` keeps it a real call and the `Point` is a local that never leaves its frame. So it pays for a call and for nothing else, and the difference between it and an allocating `Distance` is the allocation."
    },
    {
      "code": "func BenchmarkSized(b *testing.B) {\n\tfor _, n := range []int{4, 5, 64, 1024} {\n\t\tb.Run(fmt.Sprint(n), func(b *testing.B) {\n\t\t\tfor b.Loop() {\n\t\t\t\tsinkInt = Sized(n)\n\t\t\t}\n\t\t})\n\t}\n}",
      "note": "One sub-benchmark per length, named by `b.Run` after the number, on both sides of the 32 bytes and well past them."
    }
  ]
}
```

```
ana@vm:~/escape$ go test -run '^$' -bench . -benchmem ./why
goos: linux
goarch: amd64
pkg: example.com/escape/why
cpu: Intel(R) Xeon(R) Processor
BenchmarkDistance-4   	1000000000	         0.5395 ns/op	       0 B/op	       0 allocs/op
BenchmarkCall-4       	1000000000	         0.8222 ns/op	       0 B/op	       0 allocs/op
BenchmarkSized/4-4    	1000000000	         0.5401 ns/op	       0 B/op	       0 allocs/op
BenchmarkSized/5-4    	32446816	        38.92 ns/op	      48 B/op	       1 allocs/op
BenchmarkSized/64-4   	 5453491	       208.4 ns/op	     512 B/op	       1 allocs/op
BenchmarkSized/1024-4 	 1000000	      1901 ns/op	    8192 B/op	       1 allocs/op
PASS
ok  	example.com/escape/why	6.246s
```

**0.5395 ns is what a loop iteration costs when there is nothing left to do**: `Distance` inlined to
an addition, and `Sized/4` to nothing at all, since nobody reads the slice. `call` adds a real call
and comes to 0.8222 ns. From five elements on, every row has `1 allocs/op`, and the price rises
with the size: 48 bytes and 38.92 ns, 512 bytes and 208.4 ns, 8192 bytes and 1901 ns. Five `int`s
are 40 bytes and come back as 48, because the allocator hands out memory in a fixed set of sizes and
rounds up. The time grows with the bytes because the allocator has to find them and zero them, and
because more bytes allocated make the collector run more often.

Then the same function with and without its escape: the directive from section 04 goes back on
`New`, and the two benchmarks run again.

```
ana@vm:~/escape$ sed -i "s|^func New(|//go:noinline\nfunc New(|" point/point.go
ana@vm:~/escape$ go test -run Allocs -v ./why | grep Distance
    allocs_test.go:26: Distance(4, 5)  1 allocs
ana@vm:~/escape$ go test -run '^$' -bench 'Distance|Call' -benchmem ./why
goos: linux
goarch: amd64
pkg: example.com/escape/why
cpu: Intel(R) Xeon(R) Processor
BenchmarkDistance-4   	67297569	        17.03 ns/op	      16 B/op	       1 allocs/op
BenchmarkCall-4       	1000000000	         0.7961 ns/op	       0 B/op	       0 allocs/op
PASS
ok  	example.com/escape/why	1.954s
ana@vm:~/escape$ sed -i "/^\/\/go:noinline$/d" point/point.go
```

**One allocation of 16 bytes took `Distance` from 0.5395 ns to 17.03 ns**, while `call`, which pays for
a call and no allocation, stayed at 0.7961 ns. The call is a fraction of a nanosecond; the heap is the
other sixteen. These are one run's figures on a shared machine, so trust the order of magnitude rather than the
digits: tens of nanoseconds against less than one.

## Where the rest of the price goes

**ns/op is not the whole bill.** The benchmark times the allocation itself and whatever share of the
collector's work fell on the goroutine running it. The rest comes later and elsewhere: every object
on the heap has to be found and freed by the collector, which lesson 19 takes apart, and part of that
work runs on other processors, outside this number. A value on the stack costs neither, because a
frame is freed by returning from the function.

Seventeen nanoseconds is nothing once. **It matters at the rate a hot path runs**: once per line of a
log, per request, per element of a large slice. That is where escape analysis earns its place, and
section 06 takes it to the hot path of `hits`, where an allocation happens once per line.
