---
title: Strings and byte slices without a copy
version: 1
---

`string(b)` copies. **A Go string is immutable and a byte slice is not**, so the conversion has to
give the string bytes of its own, or a later write to `b` would change a value the language promises
never changes. That copy is an allocation and a `memmove`, and in a loop over every line of a log it
is paid once per line. The usual reaction is to reach for `unsafe`; the right one is to check first
whether the compiler already removed the copy, which it does in more places than people expect. This
section measures both and then breaks the promise on purpose.

## Four functions, since Go 1.20

A string is two words, a pointer to its bytes and a length. A slice is three, a pointer, a length
and a capacity. Converting one into the other without copying means building one header that points
at the other's bytes. Go 1.20 added four functions to `unsafe` for exactly that, so that nobody has
to fake a header with pattern 6:

| function | gives | from |
|---|---|---|
| `unsafe.StringData(s)` | `*byte`, the first byte of a string | a string |
| `unsafe.SliceData(b)` | a pointer to a slice's first element | a slice |
| `unsafe.String(p, n)` | a string of `n` bytes starting at `p` | a `*byte` and a length |
| `unsafe.Slice(p, n)` | a slice of length and capacity `n` starting at `p` | a pointer and a length |

The rule for using them sits in two doc comments. `unsafe.String`: "the bytes passed to String must
not be modified as long as the returned string value exists". `unsafe.StringData`: "the bytes
returned by StringData must not be modified". **Everything else in this section is what happens when
somebody forgets one of those two sentences.**

Following section 05's rule, the conversions live in one small package and nowhere else. Save it as
`internal/zc/zc.go`:

```go
// Package zc converts between strings and byte slices without copying.
//
// Both functions hand out memory that two values now share. Whoever calls
// them promises that the bytes never change while the result exists.
package zc

import "unsafe"

// String returns a string that uses b's bytes as they are. b must not be
// modified afterwards, ever, or the string changes with it.
func String(b []byte) string {
	return unsafe.String(unsafe.SliceData(b), len(b))
}

// Bytes returns the bytes of s as a slice. The slice must never be written
// to: the bytes may be in read-only memory, and other strings may share them.
func Bytes(s string) []byte {
	return unsafe.Slice(unsafe.StringData(s), len(s))
}
```

## Measured against the ordinary conversion

The test file checks the one property the package exists for, that nothing is copied, and then
benchmarks the conversion of a 46-byte log line and of a 4 KiB page both ways. Its last five
benchmarks ask a different question, whether ordinary code needs `zc` at all. Save it as
`internal/zc/zc_test.go`:

```go
package zc

import (
	"strings"
	"testing"
	"unsafe"
)

// TestShares checks the one thing the package is for: nothing is copied.
func TestShares(t *testing.T) {
	b := []byte("GET /login")
	s := String(b)
	if s != "GET /login" {
		t.Fatalf("String = %q", s)
	}
	if unsafe.StringData(s) != &b[0] {
		t.Error("String copied the bytes")
	}
	if &Bytes(s)[0] != &b[0] {
		t.Error("Bytes copied the bytes")
	}
	if String(nil) != "" || Bytes("") != nil {
		t.Error("empty input should give an empty result")
	}
}

var (
	line = []byte("2026-10-01T09:00:01Z POST /api/users 404 115ms")
	page = []byte(strings.Repeat("x", 4096))
	sink string
)

func BenchmarkLineCopy(b *testing.B) {
	for b.Loop() {
		sink = string(line)
	}
}

func BenchmarkLineUnsafe(b *testing.B) {
	for b.Loop() {
		sink = String(line)
	}
}

func BenchmarkPageCopy(b *testing.B) {
	for b.Loop() {
		sink = string(page)
	}
}

func BenchmarkPageUnsafe(b *testing.B) {
	for b.Loop() {
		sink = String(page)
	}
}

var (
	hits = map[string]int{"/api/users": 1}
	path = []byte("/api/users")
	long = []byte("/static/vendor/charts/2026-10/app.min.js")
)

// m[string(b)], written in the index expression, is looked up without
// building a string at all.
func BenchmarkLookup(b *testing.B) {
	n := 0
	for b.Loop() {
		n += hits[string(path)]
	}
}

func BenchmarkLookupLong(b *testing.B) {
	n := 0
	for b.Loop() {
		n += hits[string(long)]
	}
}

// The same conversion one line earlier is an ordinary one. A short string
// that does not escape is still built without the heap.
func BenchmarkLookupVar(b *testing.B) {
	n := 0
	for b.Loop() {
		k := string(path)
		n += hits[k]
	}
}

func BenchmarkLookupVarLong(b *testing.B) {
	n := 0
	for b.Loop() {
		k := string(long)
		n += hits[k]
	}
}

// Counting may insert the key, and a key in a map has to be a real string.
func BenchmarkIncrement(b *testing.B) {
	for b.Loop() {
		hits[string(path)]++
	}
}
```

```
ana@vm:~/unsafe$ go test -race -count=1 ./internal/zc
ok  	example.com/hits/internal/zc	1.009s
```

```
ana@vm:~/unsafe$ go test -run "^$" -bench . -benchmem ./internal/zc
goos: linux
goarch: amd64
pkg: example.com/hits/internal/zc
cpu: Intel(R) Xeon(R) Processor
BenchmarkLineCopy-4        	32549576	        39.35 ns/op	      48 B/op	       1 allocs/op
BenchmarkLineUnsafe-4      	1000000000	         0.8246 ns/op	       0 B/op	       0 allocs/op
BenchmarkPageCopy-4        	  630120	      1605 ns/op	    4096 B/op	       1 allocs/op
BenchmarkPageUnsafe-4      	1000000000	         0.8174 ns/op	       0 B/op	       0 allocs/op
BenchmarkLookup-4          	141466650	         8.477 ns/op	       0 B/op	       0 allocs/op
BenchmarkLookupLong-4      	123594883	         9.704 ns/op	       0 B/op	       0 allocs/op
BenchmarkLookupVar-4       	95115313	        12.82 ns/op	       0 B/op	       0 allocs/op
BenchmarkLookupVarLong-4   	24622020	        51.34 ns/op	      48 B/op	       1 allocs/op
BenchmarkIncrement-4       	28707585	        50.54 ns/op	      16 B/op	       1 allocs/op
PASS
ok  	example.com/hits/internal/zc	10.311s
```

The first four lines are the case for `unsafe`. **The copy costs one allocation the size of the
input**, 48 bytes for the line and 4096 for the page, and its time grows with the size: tens of
nanoseconds for the line, over a microsecond for the page. The unsafe conversion builds a header and
copies nothing, so it takes under a nanosecond whatever the size.

The last five are the case against reaching for it. `hits[string(path)]`, written inside the index
expression, **allocated nothing at all, for a 10-byte key and for a 40-byte one**. The compiler
recognises a conversion used only to look a key up and passes the bytes to the map without building
a string. Move the same conversion one line up, into a variable, and the 10-byte key still costs
nothing, for a different reason: **a converted string that does not escape and fits in 32 bytes is
built in a buffer on the stack** (`tmpStringBufSize` in `runtime/string.go`). The 40-byte key does
not fit, and costs its allocation again.

The increment is the interesting one. `hits[string(path)]++` allocated 16 bytes on every call,
although the key was already in the map, because `++` on a map may insert, and **a key stored in a
map has to be a real string that nothing else can change**. That is the allocation a program
counting paths pays per line, and the next program is what happens when somebody removes it with
`zc`.

## Breaking the promise

First the promise in its smallest form. Save this as `mutate/main.go`:

```go
// Command mutate breaks the promise zc asks for, in both directions.
package main

import (
	"fmt"

	"example.com/hits/internal/zc"
)

func main() {
	b := []byte("GET /login")
	s := zc.String(b)
	fmt.Println("before:", s)
	copy(b, "PUT")
	fmt.Println("after: ", s) // nobody assigned to s

	method := "GET"
	zc.Bytes(method)[0] = 'P' // a literal lives in read-only memory
	fmt.Println(method)
}
```

```
ana@vm:~/unsafe$ go build -o bin/mutate ./mutate && bin/mutate 2>&1 | head -5; echo ${PIPESTATUS[0]}
before: GET /login
after:  PUT /login
unexpected fault address 0x49a058
fatal error: fault
[signal SIGSEGV: segmentation violation code=0x2 addr=0x49a058 pc=0x499f2f]
2
```

**`s` changed although nothing assigned to it**, because `s` and `b` share their bytes. In the other
direction, writing through `zc.Bytes` into a string literal killed the program with a segmentation
violation: literals live in memory the operating system has marked read-only, and the exit status 2
is the runtime's fatal error. It is not a panic, and no `recover` can catch it.

Now the same mistake where it actually happens. `bufio.Scanner.Bytes` returns the current line as a
slice of the scanner's own buffer, and its documentation says "the underlying array may point to
data that will be overwritten by a subsequent call to Scan". This program counts the paths of a log
twice, once with `string(b)` as the key and once with `zc.String(b)`. Save it as `paths/main.go`:

```go
// Command paths counts the requests per path in an access log, once with
// ordinary strings and once with strings that share the scanner's buffer.
package main

import (
	"bufio"
	"bytes"
	"fmt"
	"os"
	"strings"

	"example.com/hits/internal/zc"
)

func count(name string, key func([]byte) string) (map[string]int, error) {
	f, err := os.Open(name)
	if err != nil {
		return nil, err
	}
	defer f.Close()
	byPath := map[string]int{}
	sc := bufio.NewScanner(f)
	for sc.Scan() {
		fields := bytes.Fields(sc.Bytes())
		byPath[key(fields[2])]++
	}
	return byPath, sc.Err()
}

func main() {
	safe, err := count(os.Args[1], func(b []byte) string { return string(b) })
	if err != nil {
		fmt.Fprintln(os.Stderr, "paths:", err)
		os.Exit(1)
	}
	fast, _ := count(os.Args[1], zc.String)
	fmt.Println("copied:   ", len(safe), "keys,", safe["/login"], "requests for /login")
	fmt.Println("zero-copy:", len(fast), "keys,", fast["/login"], "requests for /login")
	total, spaced := 0, 0
	for k, v := range fast {
		total += v
		if strings.ContainsAny(k, " \n") {
			spaced++
		}
	}
	fmt.Println("requests the zero-copy map counted:", total)
	fmt.Println("keys with a space or a newline in them:", spaced)
}
```

Run on the 20,000 lines lesson 1's `genlog` writes:

```
ana@vm:~/unsafe$ go run ./tools/genlog -n 20000 > access.log && go run ./paths access.log
copied:    8 keys, 2576 requests for /login
zero-copy: 1535 keys, 19 requests for /login
requests the zero-copy map counted: 20000
keys with a space or a newline in them: 1065
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Two headers point at the same ten bytes. The slice b is a pointer, a length of 10 and a capacity of 10; the string s from zc.String is a pointer and a length of 10. Both pointers lead to one row of bytes reading PUT /login, whose first three bytes were written through b.\"><defs><marker id=\"zc-arrow\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20.0\" y=\"32.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">b []byte</text><rect x=\"20.0\" y=\"46.0\" width=\"52.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ptr</text><rect x=\"76.0\" y=\"46.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">len 10</text><rect x=\"148.0\" y=\"46.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"182.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cap 10</text><text x=\"20.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">slice header: pointer, length, capacity</text><text x=\"20.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">s string</text><rect x=\"20.0\" y=\"138.0\" width=\"52.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ptr</text><rect x=\"76.0\" y=\"138.0\" width=\"68.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">len 10</text><text x=\"20.0\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">string header: pointer, length</text><text x=\"515.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ten bytes, stored once</text><rect x=\"341.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"357.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">P</text><rect x=\"376.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"392.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">U</text><rect x=\"411.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"427.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">T</text><rect x=\"446.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"462.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&#x2423;</text><rect x=\"481.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"497.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/</text><rect x=\"516.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"532.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">l</text><rect x=\"551.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"567.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">o</text><rect x=\"586.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"602.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">g</text><rect x=\"621.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"637.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">i</text><rect x=\"656.0\" y=\"94.0\" width=\"32.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"672.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">n</text><path d=\"M392.5 136 V148\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"392.5\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">written through b</text><path d=\"M46 76 V81 H240 C 290 81, 300 106, 336 106\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#zc-arrow)\"></path><path d=\"M46 168 V173 H240 C 290 173, 300 114, 336 114\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#zc-arrow)\"></path></svg>", "caption": "What zc.String builds: a second header, not a second copy. After copy(b, \"PUT\") the three bytes changed in the one place both headers point at, so s reads PUT /login without anybody assigning to it."}
```

**The copied map has the eight paths of the log, and `/login` with its 2,576 requests.** The
zero-copy map counted every one of the 20,000 requests and filed them under some fifteen hundred
keys, most of which are pieces of other lines: each key was a window onto the scanner's buffer, and
the scanner refilled the buffer underneath them. Over a thousand keys contain a space or a newline,
which no path in the log does. The exact numbers change a little from run to run; that the zero-copy
map is nonsense does not.

And no tool notices:

```
ana@vm:~/unsafe$ go vet ./paths ./internal/zc && go run -race ./paths access.log
copied:    8 keys, 2576 requests for /login
zero-copy: 1536 keys, 19 requests for /login
requests the zero-copy map counted: 20000
keys with a space or a newline in them: 1063
```

**`vet`, the race detector and checkptr all passed.** No conversion was invalid at the moment it was
made, no two goroutines touched the memory, and no pointer left its allocation. The bug is a broken
promise about the future, and only a person reading the code can see it: `zc.String`'s doc comment
says the bytes must never change, and the call site handed it bytes whose owner says they will.
