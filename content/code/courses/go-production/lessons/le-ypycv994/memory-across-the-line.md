---
title: Memory on both sides of the line
version: 1
---

Go frees memory when nothing points to it any more; C frees it when somebody calls `free`. A call
from one to the other crosses between those two worlds, and **the bugs that cgo is known for are
almost all about which side owns a piece of memory**. A C string nobody frees leaks for as long as
the process lives. A Go pointer that C keeps after the call returns points, sooner or later, at
memory the collector has moved or reused. Neither shows up in a test that runs for a second.

The rules are short and the cgo documentation states them in a section called "Passing pointers".
This section meets them on a real C library instead of a function written in a comment: zlib, the
library that reads and writes the gzip format.

## A real library: counting the lines of a gzip file

`gzlines` opens a compressed log with zlib, reads it in pieces of 64 KiB, and counts newlines. Every
call into C in it hands memory across the line in one direction or the other, and the notes say
which. `gzlines/main.go`:

```schooling-example
{
  "language": "go",
  "file": "gzlines/main.go",
  "parts": [
    {
      "code": "// Command gzlines counts the lines of a gzip-compressed file, reading it\n// through zlib, the C library behind gzip.\npackage main\n",
      "note": "zlib is the C library behind `gzip` and much else. Building against it needs its development files, the header and the library to link, which Ubuntu packages as `zlib1g-dev`: `sudo apt install zlib1g-dev`. The lab machine had them already."
    },
    {
      "code": "/*\n#cgo LDFLAGS: -lz\n#include <stdlib.h>\n#include <zlib.h>\n*/\nimport \"C\"\n",
      "note": "`-lz` links zlib, the way `-lm` linked the maths library in section 02. `stdlib.h` is there for `free`: **`C.free` exists only when the preamble includes the header that declares it.**"
    },
    {
      "code": "import (\n\t\"bytes\"\n\t\"errors\"\n\t\"fmt\"\n\t\"os\"\n\t\"unsafe\"\n)\n"
    },
    {
      "code": "func main() {\n\tfmt.Println(\"zlib\", C.GoString(C.zlibVersion()))\n\tfor _, name := range os.Args[1:] {\n\t\tn, err := count(name)\n\t\tif err != nil {\n\t\t\tfmt.Fprintln(os.Stderr, \"gzlines:\", err)\n\t\t\tos.Exit(1)\n\t\t}\n\t\tfmt.Println(n, name)\n\t}\n}\n",
      "note": "`zlibVersion` returns a `const char *` that points into zlib's own memory. `C.GoString` copies the bytes up to the zero that ends a C string into a new Go string. The pointer itself is never freed, because zlib owns it."
    },
    {
      "code": "// count opens name with zlib and counts the newlines in what it reads.\nfunc count(name string) (int, error) {\n\tcname := C.CString(name)\n\tdefer C.free(unsafe.Pointer(cname))\n\tmode := C.CString(\"rb\")\n\tdefer C.free(unsafe.Pointer(mode))\n",
      "note": "**`C.CString` copies a Go string into memory from C's `malloc`**, with the zero byte C expects at the end. The garbage collector does not know that memory exists, so freeing it is this function's job, and `defer` does it on every return."
    },
    {
      "code": "\tf, err := C.gzopen(cname, mode)\n\tif f == nil {\n\t\treturn 0, fmt.Errorf(\"%s: %w\", name, err)\n\t}\n\tdefer C.gzclose(f)\n",
      "note": "Any C function can be called for two results, and the second is C's `errno` as a Go error. `errno` can be left over from an earlier call even when this one succeeded, so the code checks `f == nil`, zlib's own sign of failure, before it trusts `err`."
    },
    {
      "code": "\tbuf := make([]byte, 64*1024)\n\tlines := 0\n\tfor {\n\t\tn := C.gzread(f, C.voidp(unsafe.Pointer(&buf[0])), C.uint(len(buf)))",
      "note": "**Go memory lent to C for one call.** `&buf[0]` points into a Go slice, and the rules allow passing it because the bytes hold no Go pointers. C may read and write them until `gzread` returns and must not keep the address afterwards. `unsafe.Pointer` is how any Go pointer becomes C's `void *`, which zlib calls `voidp`."
    },
    {
      "code": "\t\tif n <= 0 {\n\t\t\tvar code C.int\n\t\t\tmsg := C.gzerror(f, &code)\n\t\t\tif code != C.Z_OK {\n\t\t\t\treturn lines, errors.New(C.GoString(msg))\n\t\t\t}\n\t\t\treturn lines, nil\n\t\t}",
      "note": "`gzread` returns 0 at the end of a whole file and at the end of a cut one alike; zlib's header says it \"does not return -1 in the event of an incomplete gzip stream\". `gzerror` tells the two apart. Its message belongs to zlib too, so it is copied and never freed."
    },
    {
      "code": "\t\tlines += bytes.Count(buf[:n], []byte{'\\n'})\n\t}\n}"
    }
  ]
}
```

The log is the one lesson 1's `genlog` writes, and its source, `tools/genlog/main.go`, goes into
this module unchanged. Three files come out of it: the log, a compressed copy, and a copy of that
cut off after 3,000 bytes, the way a download that died halfway leaves one:

```
ana@vm:~/cgo$ go run ./tools/genlog -n 20000 > access.log && gzip -k access.log && head -c 3000 access.log.gz > cut.gz
ana@vm:~/cgo$ go build -o bin/ ./gzlines && bin/gzlines access.log.gz
zlib 1.3
20000 access.log.gz
ana@vm:~/cgo$ bin/gzlines cut.gz; echo $?
zlib 1.3
gzlines: cut.gz: unexpected end of file
1
ana@vm:~/cgo$ bin/gzlines nope.gz; echo $?
zlib 1.3
gzlines: nope.gz: no such file or directory
1
ana@vm:~/cgo$ bin/gzlines access.log
zlib 1.3
20000 access.log
```

The 20,000 lines are all there, and the two failures say what failed. `unexpected end of file`
came from `gzerror`, and asking it is the only reason the cut file is reported at all. A version of
`count` that returned on `n == 0` without asking printed a count and exit status 0 for a file
missing most of its lines. `no such file or directory` is
`errno`, carried back by the two-result call. The last command is a zlib habit worth knowing: given
a file with no gzip header, `gzopen` reads it as it is, so `gzlines` counted the plain log too.
**Each of those behaviours is a convention of one C library**, written in its header, and a cgo
wrapper inherits every one of them. Go's own `compress/gzip` has different ones, and section 05 shows them.

## Who frees what

Four kinds of memory crossed the line in `gzlines`, and each has one owner:

| value | allocated by | freed by | in `gzlines` |
|---|---|---|---|
| `C.CString(s)` | C's `malloc`, as a copy | you, with `C.free` | `cname` and `mode`, freed by `defer` |
| `C.GoString(p)` | Go, as a copy | the garbage collector | the version and the error message |
| a pointer a C library returns | the library | the library, or the function it documents | `zlibVersion()`, `gzerror(...)`, and `f`, freed by `gzclose` |
| `&buf[0]`, Go memory passed to C | Go | the garbage collector | lent to `gzread` for the length of one call |

**Every conversion between a Go string and a C string is a copy**, in both directions, because the
two disagree about what a string is: Go's carries its length and may contain zero bytes, C's ends
at the first zero. Copying costs a `malloc` and a loop, and it is what makes the ownership simple:
after `C.CString` returns, the Go string and the C string have nothing to do with each other.

## The rule the runtime checks

Lending `&buf[0]` worked because the bytes in `buf` are only bytes. The documentation's rule is
that **Go may pass C a pointer to Go memory only if that memory holds no pointers to other Go
memory that is not pinned**, and that C may not keep a copy after the call returns. The reason is
the garbage collector: it can see Go pointers in Go memory and keep their targets alive, and it
cannot see into C. A C struct holding a pointer into a Go slice is the shape that breaks the rule
without looking wrong. `rules/main.go`:

```go
// Command rules hands C a struct that points into Go memory, which the
// pointer-passing rules forbid, and lets the runtime notice.
package main

/*
#include <stddef.h>

typedef struct {
	const char *data;
	size_t len;
} span;

static size_t span_len(span *s) { return s->len; }
*/
import "C"

import (
	"fmt"
	"unsafe"
)

func main() {
	line := []byte("GET /login")
	s := C.span{data: (*C.char)(unsafe.Pointer(&line[0])), len: C.size_t(len(line))}
	fmt.Println(C.span_len(&s))
}
```

```
ana@vm:~/cgo$ go vet ./rules && go build -o bin/ ./rules && bin/rules; echo $?
panic: runtime error: argument of cgo function has Go pointer to unpinned Go pointer

goroutine 1 [running]:
main.main.func1(...)
	/home/ana/cgo/rules/main.go:25
main.main()
	/home/ana/cgo/rules/main.go:25 +0xa5
2
```

`s` is a Go variable, so `&s` is a Go pointer, and its `data` field points into `line`, which is Go
memory too. **`go vet` passed it and the compiler built it; the runtime caught it on the call**,
with a check the documentation describes as "reasonably cheap", on by default as `GODEBUG=cgocheck=1`.
Turning the check off does not make the program right:

```
ana@vm:~/cgo$ GODEBUG=cgocheck=0 bin/rules; echo $?
10
0
```

It printed the right answer, because `span_len` reads the length and returns before the collector
has had any reason to touch `line`. That is the danger in one line: **a violation the check does not
stop works until the collector runs at the wrong moment.** The fix is to tell the
runtime that `line` must stay where it is for as long as C can see it. `runtime.Pinner` does that,
and `pinned/main.go` is the same program with three lines added:

```go
// Command pinned hands C the same struct as rules, with the memory it
// points to pinned for as long as C can see it.
package main

/*
#include <stddef.h>

typedef struct {
	const char *data;
	size_t len;
} span;

static size_t span_len(span *s) { return s->len; }
*/
import "C"

import (
	"fmt"
	"runtime"
	"unsafe"
)

func main() {
	line := []byte("GET /login")
	var pin runtime.Pinner
	pin.Pin(&line[0])
	defer pin.Unpin()
	s := C.span{data: (*C.char)(unsafe.Pointer(&line[0])), len: C.size_t(len(line))}
	fmt.Println(C.span_len(&s))
}
```

```
ana@vm:~/cgo$ go build -o bin/ ./pinned && bin/pinned
10
```

`Pin` fixes the object in place until `Unpin`, and the check is satisfied because the pointer
inside `s` now points at pinned memory. There are two other fixes. `C.CBytes` allocates the bytes
on the C side, copying like `C.CString`, and they are freed the same way. Or the pointer and the
length go to C as two arguments, so that no Go memory C receives contains a pointer at all.

## Go values C must carry: `cgo.Handle`

A C library that calls you back usually takes a `void *` or an integer of "user data" and hands it
to every callback. You cannot pass it a Go map, a channel or a pointer to a struct full of slices:
all of them contain Go pointers, and C would be keeping them. **`runtime/cgo.Handle` turns any Go
value into an integer** that means nothing to C and that Go can turn back into the value. A C
function that splits a log into lines and calls Go once per line shows it. The C goes in two files
beside the Go file, which the go command compiles because the package imports `"C"`.
`each/each.h`:

```
#include <stddef.h>
#include <stdint.h>

// each_line calls the Go function goLine once for every line in buf,
// passing h through untouched.
void each_line(const char *buf, size_t n, uintptr_t h);
```

`each/each.c`:

```
#include "each.h"
#include "_cgo_export.h"

void each_line(const char *buf, size_t n, uintptr_t h) {
	size_t start = 0;
	for (size_t i = 0; i < n; i++) {
		if (buf[i] == '\n') {
			goLine(h, (char *)buf + start, (int)(i - start));
			start = i + 1;
		}
	}
}
```

`each/main.go`:

```go
// Command each hands a log to a C function that splits it into lines, and
// counts the methods in the lines C hands back.
package main

/*
#include "each.h"
*/
import "C"

import (
	"fmt"
	"os"
	"runtime/cgo"
	"strings"
	"unsafe"
)

//export goLine
func goLine(h C.uintptr_t, line *C.char, n C.int) {
	counts := cgo.Handle(h).Value().(map[string]int)
	fields := strings.Fields(C.GoStringN(line, n))
	counts[fields[1]]++
}

func main() {
	data, err := os.ReadFile(os.Args[1])
	if err != nil || len(data) == 0 {
		fmt.Fprintln(os.Stderr, "each: need a log that is not empty:", err)
		os.Exit(1)
	}
	counts := map[string]int{}
	h := cgo.NewHandle(counts)
	defer h.Delete()
	C.each_line((*C.char)(unsafe.Pointer(&data[0])), C.size_t(len(data)), C.uintptr_t(h))
	fmt.Println(counts)
}
```

```
ana@vm:~/cgo$ ls each && go build -o bin/ ./each && bin/each access.log
each.c
each.h
main.go
map[GET:15065 POST:4935]
```

`//export goLine` makes the Go function callable from C, and cgo declares it in `_cgo_export.h`,
which is why `each.c` includes that header. The map never leaves Go: `cgo.NewHandle(counts)` stores
it in a table and returns its number, C passes the number back 20,000 times, and
`cgo.Handle(h).Value()` looks the map up again. Each line arrives as a pointer and a length with no
zero byte after it, so `C.GoStringN` copies exactly that many bytes. `h.Delete()` removes the entry, and **a handle that
is never deleted keeps its value alive forever**, the same leak as a C string nobody frees, from
the other side. The C half lives in `.c` and `.h` files rather than in the preamble for a reason
the documentation gives. A file that uses `//export` may have only declarations in its preamble,
because the preamble is copied into two generated C files, and a definition there would be defined
twice.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" aria-label=\"Four things cross between Go memory, freed by the garbage collector, and C memory, freed by calling free. C.CString(name) copies a Go string into C memory, which you must free with C.free. &amp;buf[0] lends a Go slice to gzread for one call, and C must not keep it. C.GoString(p) copies the string zlibVersion returns into a new Go string, and zlib keeps its own. cgo.NewHandle(counts) leaves the Go map in Go and passes C only an integer.\"><defs><marker id=\"m3p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"m3a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"250\" height=\"345\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"450\" y=\"20\" width=\"250\" height=\"345\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Go memory</text><text x=\"145\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the garbage collector frees it</text><text x=\"575\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">C memory</text><text x=\"575\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">free() frees it</text><rect x=\"38\" y=\"85\" width=\"214\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">name</text><text x=\"145\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a Go string</text><rect x=\"468\" y=\"85\" width=\"214\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">cname</text><text x=\"575\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">yours to free: C.free</text><path d=\"M256 111 L464 111\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#m3p)\"></path><text x=\"360\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">C.CString(name)</text><text x=\"360\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">copied into C memory</text><rect x=\"38\" y=\"155\" width=\"214\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">buf</text><text x=\"145\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a Go slice of 64 KiB</text><rect x=\"468\" y=\"155\" width=\"214\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">gzread(f, &amp;buf[0], n)</text><text x=\"575\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uses it until it returns</text><path d=\"M256 181 L464 181\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#m3a)\" marker-start=\"url(#m3a)\"></path><text x=\"360\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">&amp;buf[0]</text><text x=\"360\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lent for one call, never kept</text><rect x=\"38\" y=\"225\" width=\"214\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&quot;1.3&quot;</text><text x=\"145\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a new Go string</text><rect x=\"468\" y=\"225\" width=\"214\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">zlibVersion()</text><text x=\"575\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zlib's own, never freed</text><path d=\"M464 251 L256 251\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#m3p)\"></path><text x=\"360\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">C.GoString(p)</text><text x=\"360\" y=\"265\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">copied into Go memory</text><rect x=\"38\" y=\"295\" width=\"214\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"313\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">counts</text><text x=\"145\" y=\"332\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a Go map, which stays here</text><rect x=\"468\" y=\"295\" width=\"214\" height=\"52\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"313\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">uintptr_t h</text><text x=\"575\" y=\"332\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a number C hands back</text><path d=\"M256 321 L464 321\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#m3p)\"></path><text x=\"360\" y=\"309\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">cgo.NewHandle(counts)</text><text x=\"360\" y=\"335\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">only an integer crosses</text></svg>", "caption": "Every crossing is a copy, a loan for the length of one call, or a number that stands for a Go value."}
```
