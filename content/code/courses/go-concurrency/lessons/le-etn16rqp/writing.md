---
title: A benchmark is a test that measures
version: 1
---

A test answers whether the code is right. **A benchmark answers how long it takes and how much
memory it asks for**, and it lives in the same `_test.go` files, run by the same `go test`. The
difference is the name and the parameter: `BenchmarkXxx(b *testing.B)` instead of
`TestXxx(t *testing.T)`.

## Two benchmarks for the package

The input is built once, at package level, so every benchmark measures the same text. Saved as
`bench_test.go`:

```go
package wordcount

import (
	"strings"
	"testing"
)

// sample is about 9 KB of text, built once for every benchmark in the file.
var sample = strings.Repeat("The quick brown fox jumps over the lazy dog. Go is fun, and go is fast! ", 128)

func BenchmarkCount(b *testing.B) {
	b.SetBytes(int64(len(sample)))
	for b.Loop() {
		if _, err := Count(strings.NewReader(sample)); err != nil {
			b.Fatal(err)
		}
	}
}

func BenchmarkTop(b *testing.B) {
	counts, err := Count(strings.NewReader(sample))
	if err != nil {
		b.Fatal(err)
	}
	for b.Loop() {
		Top(counts, 3)
	}
}
```

**`for b.Loop()` is the loop that is timed.** The testing package runs the body again and again,
increasing the number of rounds until the total takes about a second, then divides. Everything
before the loop is setup and is not timed: `BenchmarkTop` counts the sample once, outside, so what
it measures is `Top` alone. `b.SetBytes` declares how many bytes one round processes, which adds a
throughput column to the report.

`b.Loop` arrived in Go 1.24. Older code writes the same thing as `for i := 0; i < b.N; i++`, and
section 04 shows the trap that form leaves open.

## Running them

`go test` runs no benchmark unless asked. `-bench` takes a regular expression of benchmark names,
as `-run` does for tests, and `-run '^$'` matches no test, so the tests do not run first.
`-benchmem` adds the memory columns:

```
ana@vm:~/wordcount$ go test -run '^$' -bench . -benchmem
goos: linux
goarch: amd64
pkg: example.com/wordcount
cpu: Intel(R) Xeon(R) Processor
BenchmarkCount-4   	   10363	    113733 ns/op	  81.03 MB/s	   16104 B/op	    2311 allocs/op
BenchmarkTop-4     	 2368893	       483.9 ns/op	     320 B/op	       1 allocs/op
PASS
ok  	example.com/wordcount	2.332s
```

The header names the machine, which matters: a number from a benchmark is a fact about this code
on this processor, and the same run on a laptop gives a different one. Then one line per
benchmark, and the total time the whole run took. Section 03 reads the columns.
