---
title: What one call costs
version: 1
---

A call into C looks like any other call in the source, `C.add1(x)`, and the instinct is to price it
like one. **It costs more than thirty times as much as a Go call, for a reason that no compiler flag
removes.** Go and C disagree about stacks and about who is in charge of a thread, so every call
has to cross from one arrangement to the other and back. For a function that does real work the
crossing disappears into it. For a small function called in a loop, the crossing is the loop.

## The crossing, measured

The package below holds a trivial function written twice, once in Go and once in C, and three ways
to compute the CRC-32 checksum of the 20,000-line log with zlib. `cost/cost.go`:

```schooling-example
{
  "language": "go",
  "file": "cost/cost.go",
  "parts": [
    {
      "code": "// Package cost measures what it costs to call C from Go.\npackage cost\n",
      "note": "A package rather than a command, because the measuring is done by benchmarks. They live in `cost_test.go` and the cgo lives here: the go command refuses a test file that imports `\"C\"`, so C reaches a test through ordinary functions like these."
    },
    {
      "code": "/*\n#cgo LDFLAGS: -lz\n#include <zlib.h>\n\nstatic int add1(int x) { return x + 1; }\n\n// crc_lines makes the same crc32 calls as CRCLines, one per line, with the\n// loop on this side: lens holds the length of each of the n lines in buf.\nstatic uLong crc_lines(const Bytef *buf, const uInt *lens, size_t n) {\n\tuLong c = 0;\n\tfor (size_t i = 0; i < n; i++) {\n\t\tc = crc32(c, buf, lens[i]);\n\t\tbuf += lens[i];\n\t}\n\treturn c;\n}\n*/\nimport \"C\"\n\nimport \"unsafe\"\n",
      "note": "Two C functions. `add1` does almost nothing, so that timing it times the crossing. `crc_lines` makes exactly the `crc32` calls `CRCLines` below makes, one per line, with the loop written in C."
    },
    {
      "code": "// GoAdd1 returns x+1. The directive stops the compiler from inlining it,\n// so that a benchmark of it measures a real call.\n//\n//go:noinline\nfunc GoAdd1(x int) int { return x + 1 }\n",
      "note": "**The baseline: the same work as `add1`, as a Go call.** Without `//go:noinline` the compiler would paste `x + 1` into the benchmark loop and there would be no call left to time."
    },
    {
      "code": "// CAdd1 returns x+1, computed by a C function.\nfunc CAdd1(x int) int { return int(C.add1(C.int(x))) }\n"
    },
    {
      "code": "// CRCLines returns the CRC-32 of the lines joined together, calling zlib's\n// crc32 once per line: one crossing into C for every line.\nfunc CRCLines(lines [][]byte) uint32 {\n\tvar c C.uLong\n\tfor _, l := range lines {\n\t\tc = C.crc32(c, (*C.Bytef)(unsafe.Pointer(&l[0])), C.uInt(len(l)))\n\t}\n\treturn uint32(c)\n}\n",
      "note": "One crossing per line. `crc32` takes the checksum so far as its first argument, so 20,000 calls in a row give the checksum of the whole file."
    },
    {
      "code": "// Lengths returns the length of each line, in the type crc_lines reads.\nfunc Lengths(lines [][]byte) []C.uInt {\n\tlens := make([]C.uInt, len(lines))\n\tfor i, l := range lines {\n\t\tlens[i] = C.uInt(len(l))\n\t}\n\treturn lens\n}\n",
      "note": "**Batching means giving C everything it needs in one go.** A slice of `C.uInt` is Go memory holding no pointers, so `&lens[0]` may be lent to C for a call, like `&buf[0]` in section 03."
    },
    {
      "code": "// CRCLinesInC makes the same crc32 calls as CRCLines from a loop written\n// in C: one crossing, however many lines there are. data is the lines\n// joined together.\nfunc CRCLinesInC(data []byte, lens []C.uInt) uint32 {\n\treturn uint32(C.crc_lines((*C.Bytef)(unsafe.Pointer(&data[0])), &lens[0], C.size_t(len(lens))))\n}\n"
    },
    {
      "code": "// CRC returns the CRC-32 of data, asking zlib once.\nfunc CRC(data []byte) uint32 {\n\treturn uint32(C.crc32(0, (*C.Bytef)(unsafe.Pointer(&data[0])), C.uInt(len(data))))\n}",
      "note": "One crossing, and one `crc32` call over the whole file."
    }
  ]
}
```

The benchmarks, in the style of `go-concurrency` lesson 29, check first that every way of computing
the checksum agrees with the standard library's `hash/crc32`, and only then time them.
`cost/cost_test.go`:

```go
package cost

import (
	"bytes"
	"hash/crc32"
	"os"
	"slices"
	"testing"
)

var sink int

func BenchmarkGoAdd1(b *testing.B) {
	for i := range b.N {
		sink = GoAdd1(i)
	}
}

func BenchmarkCAdd1(b *testing.B) {
	for i := range b.N {
		sink = CAdd1(i)
	}
}

// BenchmarkCRC checksums the 20,000-line log four ways, and checks that all
// four agree with the standard library before it times any of them.
func BenchmarkCRC(b *testing.B) {
	data, err := os.ReadFile("../access.log")
	if err != nil {
		b.Fatal(err)
	}
	lines := slices.Collect(bytes.Lines(data))
	lens := Lengths(lines)
	want := crc32.ChecksumIEEE(data)
	cases := []struct {
		name string
		f    func() uint32
	}{
		{"zlib-per-line-from-Go", func() uint32 { return CRCLines(lines) }},
		{"zlib-per-line-from-C", func() uint32 { return CRCLinesInC(data, lens) }},
		{"zlib-once", func() uint32 { return CRC(data) }},
		{"hash-crc32", func() uint32 { return crc32.ChecksumIEEE(data) }},
	}
	for _, c := range cases {
		b.Run(c.name, func(b *testing.B) {
			if got := c.f(); got != want {
				b.Fatalf("got %08x, want %08x", got, want)
			}
			b.SetBytes(int64(len(data)))
			for range b.N {
				c.f()
			}
		})
	}
}
```

```
ana@vm:~/cgo$ go test -run=^$ -bench=. -count=1 ./cost
goos: linux
goarch: amd64
pkg: example.com/cgo/cost
cpu: Intel(R) Xeon(R) Processor
BenchmarkGoAdd1-4   	1000000000	         0.7894 ns/op
BenchmarkCAdd1-4    	46889370	        28.70 ns/op
BenchmarkCRC/zlib-per-line-from-Go-4         	     585	   2121470 ns/op	 431.24 MB/s
BenchmarkCRC/zlib-per-line-from-C-4          	     636	   1857619 ns/op	 492.49 MB/s
BenchmarkCRC/zlib-once-4                     	    6520	    174377 ns/op	5246.50 MB/s
BenchmarkCRC/hash-crc32-4                    	   64395	     19476 ns/op	46974.37 MB/s
PASS
ok  	example.com/cgo/cost	7.713s
```

**`GoAdd1` took 0.7894 ns and `CAdd1` took 28.70 ns**, for the same `x + 1`. That ratio, about
36 to 1 in this run and in the thirties in every run on this machine, is the crossing on its
own; the decimals move from run to run. What the 28.70 ns pays for is a sequence, written down in the
comments at the top of `runtime/cgocall.go` in the Go source:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"A call from Go to the C function add1, in six steps. On the goroutine's stack: 1, CAdd1 calls _Cfunc_add1, the wrapper cgo wrote; 2, runtime.cgocall calls entersyscall, so the scheduler may give the processor to another thread. 3, asmcgocall switches to the thread's system stack. 4, add1 runs there, compiled by gcc. 5, the stack switches back. 6, exitsyscall waits for a processor and returns. A Go call to the same function took 0.79 ns; this round trip took 28.70 ns.\"><defs><marker id=\"c4p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"c4a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"330\" height=\"300\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"370\" y=\"20\" width=\"330\" height=\"300\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the goroutine's stack</text><text x=\"535\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the thread's system stack, g0</text><text x=\"185\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">small, grows, moved by the runtime</text><text x=\"535\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">from the operating system; C runs here</text><rect x=\"40\" y=\"75\" width=\"290\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">1</text><text x=\"195\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CAdd1 → _Cfunc_add1</text><text x=\"195\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the wrapper cgo wrote</text><rect x=\"40\" y=\"135\" width=\"290\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">2</text><text x=\"195\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">runtime.cgocall</text><text x=\"195\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">entersyscall: the P may go to another thread</text><rect x=\"390\" y=\"195\" width=\"290\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"406\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">4</text><text x=\"545\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">add1(x)</text><text x=\"545\" y=\"227\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">C, compiled by gcc</text><rect x=\"40\" y=\"255\" width=\"290\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"56\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">6</text><text x=\"195\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">exitsyscall</text><text x=\"195\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">wait for a P, then return</text><path d=\"M185 119 L185 131\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#c4p)\"></path><path d=\"M330 179 L470 191\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#c4a)\"></path><text x=\"440\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3  switch stacks</text><path d=\"M470 239 L330 255\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#c4a)\"></path><text x=\"440\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">5  switch back</text><text x=\"360\" y=\"346\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the same x + 1 as a Go call: 0.79 ns</text><text x=\"360\" y=\"370\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">as a call into C, steps 1 to 6: 28.70 ns</text></svg>", "caption": "A call into C is a call plus a trip through the scheduler and a change of stack, on the way in and on the way out."}
```

**A goroutine's stack is small and moves.** It starts at a few kilobytes, and the runtime copies
it somewhere bigger when it grows, adjusting every pointer into it. C code compiled by `gcc`
assumes a large stack that stays where it is, so it cannot run on a goroutine's. Every Go thread
has a second stack for the runtime's own work, `g0`, allocated by the operating system, and
`asmcgocall` switches to it for the length of the C call. Around that switch, `entersyscall` and
`exitsyscall` tell the scheduler that this thread has gone where the scheduler cannot follow, as a
system call does. Meanwhile the processor slot, the P, can run other goroutines, and afterwards it
has to be got back.

## Batching, and what it can and cannot save

`CRCLines` and `CRCLinesInC` make the same 20,000 `crc32` calls over the same bytes. The only
difference is which side of the line the loop is on: 20,000 crossings against one.

| benchmark | crossings | time per checksum of the log |
|---|---|---|
| `zlib-per-line-from-Go` | 20,000 | 2.12 ms |
| `zlib-per-line-from-C` | 1 | 1.86 ms |
| `zlib-once` | 1 | 0.174 ms |
| `hash-crc32` | 0 | 0.019 ms |

**Moving the loop into C saved 0.26 ms**, about 12% of the time. That is less than the
0.57 ms that 20,000 crossings at 28.70 ns each would predict, so take the empty-function number for
what it is: the crossing at its most exposed, a ceiling rather than a price. Every call also
did about 90 ns of `crc32` work, so the crossing was never the main cost here. **The ratio
that decides whether batching pays is the crossing against the work done per call.** A C
function whose own work takes as long as the crossing spends half its time crossing; one that runs
for a millisecond does not notice.

The next row is the bigger lesson. `zlib-once` hands zlib the whole file in one call and takes
0.174 ms, 11 times faster than either per-line version, because zlib
is quicker over one large buffer than over many small ones. Batching across cgo usually means
exactly this: **design the call so that C gets a whole buffer, an array, a batch of work**, and
let it loop where looping is cheap.

The last row is the one to remember when deciding whether to use C at all. **`hash/crc32` computed
the same checksum in 0.019 ms, 9 times faster than zlib's best**, with no cgo. On amd64 it
uses the processor's carry-less multiply instruction, `PCLMULQDQ`, from assembly in the standard
library, which the Ubuntu build of zlib does not. "C is faster" is a belief worth measuring before
paying for it; section 06 comes back to it.

## A blocked call holds a thread

The crossing has a second cost, which a benchmark of a fast function cannot show. While a goroutine
is inside C, the thread under it belongs to C. If the C function blocks, waiting on a disk, a lock
or a network, the thread blocks with it, and the scheduler starts another thread so that Go code can
keep running. `threads/main.go` starts 100 goroutines that sleep for half a second, in Go or in C's
`usleep`. While they sleep, it reads the process's thread count from `/proc`:

```go
// Command threads starts 100 goroutines that each sleep for half a second,
// either in Go or inside a C function, and counts the process's threads
// while they sleep.
package main

/*
#include <unistd.h>
*/
import "C"

import (
	"bytes"
	"fmt"
	"os"
	"sync"
	"time"
)

func main() {
	inC := len(os.Args) > 1 && os.Args[1] == "c"
	var wg sync.WaitGroup
	for range 100 {
		wg.Go(func() {
			if inC {
				C.usleep(500000)
			} else {
				time.Sleep(500 * time.Millisecond)
			}
		})
	}
	time.Sleep(250 * time.Millisecond)
	status, _ := os.ReadFile("/proc/self/status")
	for line := range bytes.Lines(status) {
		if bytes.HasPrefix(line, []byte("Threads:")) {
			fmt.Printf("%s", line)
		}
	}
	wg.Wait()
}
```

```
ana@vm:~/cgo$ go build -o bin/ ./threads && bin/threads && bin/threads c
Threads:	6
Threads:	104
```

**Six threads for 100 sleeping goroutines in Go; 104 when they sleep in C.** A goroutine
asleep in `time.Sleep` is parked by the scheduler and costs a few kilobytes of stack. A goroutine
asleep in C costs a thread of the operating system, with a stack of its own. The
`net` package's documentation gives this as the reason Go prefers its own DNS resolver to the C
library's: "a blocked DNS request consumes only a goroutine, while a blocked C call consumes an
operating system thread". A server that calls a blocking C function from every request handler
discovers it as a thread count that follows its traffic.
