---
title: Fewer allocations: preallocate, reuse, pool
version: 1
---
Three techniques remove most of the allocations worth removing, and they are worth learning in
order, because each one is riskier than the last. **Preallocating changes one line. Reusing a buffer
changes who owns the memory. A `sync.Pool` hands memory between goroutines, and it can make a
program slower or wrong if it is used where it does not fit.** All three are measured here, before
and after, and none of them is worth doing before a measurement like section 05's has said that
allocation is where the time goes.

## Preallocate when the size is known

Section 05 measured the first technique in a benchmark: a hint of the exact line count took `Load`
from 53.8 MB and 53 ms an iteration to 20.5 MB and 24 ms. The same flag in the whole program,
against the two million lines of `big.log`, the second run given the line count from `wc -l`:

```
ana@vm:~/mem-hits$ ./slowest big.log && ./slowest -hint $(wc -l < big.log) big.log
2000000 requests, p99 396ms, slowest 400ms
1.74s, 21 collections, peak 501884 kB
2000000 requests, p99 396ms, slowest 400ms
898ms, 2 collections, peak 330968 kB
```

**Two collections instead of twenty-one, a peak of 330,968 kB instead of 501,884, and half the
time.** The collections fell for a reason section 04's arithmetic explains: the first large thing
the program allocated was one array big enough for every entry, the heap was large from the start,
and the goal, twice the live heap, was large with it. The peak fell because no array ever had to
exist beside a bigger copy of itself.

The size does not have to be exact to help. `make([]T, 0, n)` with a guess too small still saves the
early growth, and one too large wastes only the difference. A file's size divided by a typical line
length is a fair guess for a log; a length known from a header, or from `len` of the input slice, is
better.

## Reuse a buffer you own

The second technique is for a loop that builds something temporary on every pass. Writing entries
back out in the log's format is one: a slowest-requests report, say, printed as log lines. A second
file in `keep` does it three ways:

```schooling-example
{
  "language": "go",
  "file": "internal/keep/write.go",
  "parts": [
    {
      "code": "package keep\n\nimport (\n\t\"fmt\"\n\t\"io\"\n\t\"strconv\"\n\t\"sync\"\n\t\"time\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "A second file in `keep`. It writes entries back out in the log's own format, three ways."
    },
    {
      "code": "// WriteFmt writes entries in the log's own format, one Fprintf a line.\nfunc WriteFmt(w io.Writer, entries []tally.Entry) error {\n\tfor _, e := range entries {\n\t\t_, err := fmt.Fprintf(w, \"%s %s %s %d %dms\\n\", e.Time.Format(time.RFC3339),\n\t\t\te.Method, e.Path, e.Status, e.Duration.Milliseconds())\n\t\tif err != nil {\n\t\t\treturn err\n\t\t}\n\t}\n\treturn nil\n}\n",
      "note": "**The obvious version.** `Format` returns a new string for the time, and every argument handed to `Fprintf` is converted to an interface value on the way in, which can allocate as well."
    },
    {
      "code": "// AppendLine appends e to dst in the log's format and returns the extended\n// slice, the way strconv.AppendInt does.\nfunc AppendLine(dst []byte, e tally.Entry) []byte {\n\tdst = e.Time.AppendFormat(dst, time.RFC3339)\n\tdst = append(dst, ' ')\n\tdst = append(dst, e.Method...)\n\tdst = append(dst, ' ')\n\tdst = append(dst, e.Path...)\n\tdst = append(dst, ' ')\n\tdst = strconv.AppendInt(dst, int64(e.Status), 10)\n\tdst = append(dst, ' ')\n\tdst = strconv.AppendInt(dst, e.Duration.Milliseconds(), 10)\n\treturn append(dst, \"ms\\n\"...)\n}\n",
      "note": "**The append style of the standard library**: `time.Time.AppendFormat` and `strconv.AppendInt` write into the slice they are given and return it, growing it only if it is too small. Nothing here allocates once `dst` has room."
    },
    {
      "code": "// Write writes the same lines as WriteFmt through one buffer that every\n// line reuses.\nfunc Write(w io.Writer, entries []tally.Entry) error {\n\tbuf := make([]byte, 0, 64)\n\tfor _, e := range entries {\n\t\tbuf = AppendLine(buf[:0], e)\n\t\tif _, err := w.Write(buf); err != nil {\n\t\t\treturn err\n\t\t}\n\t}\n\treturn nil\n}\n",
      "note": "One buffer for the whole call. `buf[:0]` empties it without giving back its array, so every line after the first is written into memory that is already there."
    },
    {
      "code": "// lines holds buffers for WriteEntry. It stores pointers, so that Put has\n// nothing to allocate.\nvar lines = sync.Pool{New: func() any { b := make([]byte, 0, 64); return &b }}\n",
      "note": "**A `sync.Pool` of buffers.** `New` makes one when the pool is empty. The pool holds `*[]byte` and not `[]byte`, for a reason the end of this section measures."
    },
    {
      "code": "// WriteEntry writes one entry in a single Write, so lines stay whole when\n// several goroutines share w. It may be called from any goroutine.\nfunc WriteEntry(w io.Writer, e tally.Entry) error {\n\tbp := lines.Get().(*[]byte)\n\t*bp = AppendLine((*bp)[:0], e)\n\t_, err := w.Write(*bp)\n\tlines.Put(bp)\n\treturn err\n}",
      "note": "A function anybody may call from any goroutine, so there is no single owner to keep one buffer. It borrows one from the pool, writes, and puts it back."
    }
  ]
}
```

A faster version is only worth having if it writes the same bytes, so the tests come first. Save
them as `internal/keep/write_test.go`:

```go
package keep_test

import (
	"bytes"
	"io"
	"os"
	"testing"

	"example.com/hits/internal/keep"
	"example.com/hits/internal/tally"
)

func entries(b *testing.B) []tally.Entry {
	data, err := os.ReadFile("testdata/access.log")
	if err != nil {
		b.Fatal(err)
	}
	e, err := keep.Load(bytes.NewReader(data), 0)
	if err != nil {
		b.Fatal(err)
	}
	return e
}

func BenchmarkWrite(b *testing.B) {
	all := entries(b)
	b.Run("fmt", func(b *testing.B) {
		for b.Loop() {
			keep.WriteFmt(io.Discard, all)
		}
	})
	b.Run("append", func(b *testing.B) {
		for b.Loop() {
			keep.Write(io.Discard, all)
		}
	})
}

func BenchmarkWriteEntry(b *testing.B) {
	e := entries(b)[0]
	b.Run("new-buffer", func(b *testing.B) {
		b.RunParallel(func(pb *testing.PB) {
			for pb.Next() {
				io.Discard.Write(keep.AppendLine(make([]byte, 0, 64), e))
			}
		})
	})
	b.Run("pool", func(b *testing.B) {
		b.RunParallel(func(pb *testing.PB) {
			for pb.Next() {
				keep.WriteEntry(io.Discard, e)
			}
		})
	})
}

func TestWriteMatchesWriteFmt(t *testing.T) {
	data, err := os.ReadFile("testdata/access.log")
	if err != nil {
		t.Fatal(err)
	}
	all, err := keep.Load(bytes.NewReader(data), 0)
	if err != nil {
		t.Fatal(err)
	}
	var a, b bytes.Buffer
	keep.WriteFmt(&a, all)
	keep.Write(&b, all)
	if !bytes.Equal(a.Bytes(), data) || !bytes.Equal(b.Bytes(), data) {
		t.Error("the lines written differ from the lines read")
	}
}
```

`TestWriteMatchesWriteFmt` loads the test log, writes it back both ways and compares each result
with the original file, byte for byte. `BenchmarkWrite` times the two loops over all 100,000
entries; `BenchmarkWriteEntry` calls `WriteEntry` from several goroutines at once with
`b.RunParallel`, against a baseline that makes a fresh buffer every time.

```
ana@vm:~/mem-hits$ go test -count=1 ./internal/keep
ok  	example.com/hits/internal/keep	0.132s
ana@vm:~/mem-hits$ go test -run "^$" -bench Write -benchmem ./internal/keep
goos: linux
goarch: amd64
pkg: example.com/hits/internal/keep
cpu: Intel(R) Xeon(R) Processor
BenchmarkWrite/fmt-4    	      51	  23219544 ns/op	 7888408 B/op	  485979 allocs/op
BenchmarkWrite/append-4 	     231	   5193665 ns/op	      64 B/op	       1 allocs/op
BenchmarkWriteEntry/new-buffer-4         	13051022	        85.56 ns/op	      64 B/op	       1 allocs/op
BenchmarkWriteEntry/pool-4               	50229170	        27.15 ns/op	       0 B/op	       0 allocs/op
PASS
ok  	example.com/hits/internal/keep	5.174s
```

The two write loops first:

| | `fmt` | `append` |
|---|---|---|
| ns/op | 23,219,544 | 5,193,665 |
| B/op | 7,888,408 | 64 |
| allocs/op | 485,979 | 1 |

**485,979 allocations for 100,000 lines, almost five a line, against one for the whole file.** The
one is the 64-byte buffer, which escapes because it is passed to `w.Write`, an interface method the
compiler cannot see into. Everything after the first line is written into memory that is already
there. The loop is more than four times faster as well, and most of that is the allocations gone: no
new string for each timestamp, no interface values for each argument, and less for the collector to
find later.

**The cost is ownership.** `buf` belongs to `Write` for the length of one call, and every line
overwrites the last. That is safe only because `w.Write` may not keep the slice it was given, and
the `io.Writer` documentation says so in as many words: "Implementations must not retain p." Code
that hands out a reused buffer to anything that may hold on to it has a bug that no test of a single
line will find.

## A pool, when there is no owner

`Write` could keep one buffer because one call does all the writing. `WriteEntry` is called once per
line, from any goroutine, so there is no call to own a buffer and nowhere to keep one. That is the
case `sync.Pool` is for. Its documentation's own example is the `fmt` package, which keeps its
printers in a pool for the same reason.

From the benchmark: **27.15 ns and no allocation with the pool, against 85.56 ns and one 64-byte
allocation with a fresh buffer every time.** Four goroutines took buffers out and put them back
50,229,170 times between them in the last round, and allocated nothing per operation doing it.

What a pool keeps, and for how long, is the part people get wrong. A program in `~/mem-pool`, with
`main.go`:

```go
// Command pool shows what a sync.Pool keeps, and what it costs to use one
// wrongly.
package main

import (
	"fmt"
	"runtime"
	"sync"
	"testing"
)

func main() {
	made := 0
	p := sync.Pool{New: func() any { made++; return new([4096]byte) }}

	b := p.Get()
	p.Put(b)
	fmt.Printf("put back, got again:        same %t, made %d\n", p.Get() == b, made)

	p.Put(b)
	runtime.GC()
	fmt.Printf("after one collection:       same %t, made %d\n", p.Get() == b, made)

	p.Put(b)
	runtime.GC()
	runtime.GC()
	fmt.Printf("after two collections:      same %t, made %d\n", p.Get() == b, made)

	byValue := sync.Pool{New: func() any { return make([]byte, 0, 64) }}
	byPointer := sync.Pool{New: func() any { b := make([]byte, 0, 64); return &b }}
	fmt.Println("allocations per Get and Put of a []byte: ", testing.AllocsPerRun(1000, func() {
		b := byValue.Get().([]byte)
		byValue.Put(b[:0])
	}))
	fmt.Println("allocations per Get and Put of a *[]byte:", testing.AllocsPerRun(1000, func() {
		bp := byPointer.Get().(*[]byte)
		byPointer.Put(bp)
	}))
}
```

Run first on one processor, then on the lab's four:

```
ana@vm:~/mem-pool$ GOMAXPROCS=1 go run .
put back, got again:        same true, made 1
after one collection:       same true, made 1
after two collections:      same false, made 2
allocations per Get and Put of a []byte:  1
allocations per Get and Put of a *[]byte: 0
ana@vm:~/mem-pool$ go run .
put back, got again:        same true, made 1
after one collection:       same false, made 2
after two collections:      same false, made 3
allocations per Get and Put of a []byte:  1
allocations per Get and Put of a *[]byte: 0
```

On one processor the buffer survived one collection and was gone after the second. **A pool is
emptied by the collector**: at each cycle what it holds moves to a second tier, and what is still in
that tier at the next cycle is dropped. On four processors even one collection lost it: each
processor keeps its own items, and after `runtime.GC` the goroutine can resume on a different
processor from the one that put the buffer there. A pool is a cache that forgets on its own
schedule, never a place to keep anything that must be there later.

The last two lines are the caveat the comment on `lines` mentions. `Put` takes an `any`, and a
`[]byte` turned into an `any` needs its three words copied to the heap, **one allocation per `Put`,
the very thing the pool was meant to remove**. A pointer fits in an `any` as it is, so a pool of
`*[]byte` costs nothing. The rule is to pool pointers.

One more caveat is written in `fmt` itself:

```
ana@vm:~/mem-pool$ sed -n 163,167p /usr/local/go/src/fmt/print.go
	if cap(p.buf) > 64*1024 {
		p.buf = nil
	} else {
		p.buf = p.buf[:0]
	}
```

**A buffer over 64 KiB is not put back.** One enormous line would otherwise leave an enormous buffer
in the pool, handed to every later caller that wanted a few bytes, and a pool in constant use would
go on holding the largest thing it had ever seen. A pool of buffers whose size depends on the input
needs the same check.

## Which one, and when

| technique | it fits when | its risk |
|---|---|---|
| preallocate | the size is known or can be guessed | almost none: a guess too large wastes the difference |
| reuse a buffer | one function owns the work from start to end | something keeps the buffer after it is reused |
| `sync.Pool` | many goroutines need short-lived buffers and none owns them | forgetting to reset, pooling values instead of pointers, pooling huge buffers |

All three are answers to a measurement, and the measurement comes first. `hits count` spends about
1% of its run collecting, by section 03's trace, so none of them would make it noticeably faster.
`slowest` ran in half the time once one argument to `make` removed the copies of its growing slice.
