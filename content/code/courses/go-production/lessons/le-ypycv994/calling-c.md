---
title: A C function in a Go file
version: 1
---

cgo is often pictured as a foreign-function call that Go makes at run time, the way Python's
`ctypes` opens a library and looks a symbol up by name. **It is a build step.** A Go file that
imports the pseudo-package `"C"` goes to a tool called `cgo` before the compiler sees it. `cgo`
writes Go and C files from it, `gcc` compiles the C half, and the linker joins the two into one
binary. By the time the program runs, a call to C is an ordinary call to machine code that was
linked in, with the bridge between the two languages in front of it.

Lesson 16 built a three-line program that did this and moved on. This section takes the same
mechanism apart: where the C goes, how its types meet Go's, how to name a C library, and what the
go command runs to make it work.

## The preamble

Every program in this lesson lives in one module, `~/cgo`, made with `go mod init example.com/cgo`,
one directory per program. The first, `first/main.go`:

```go
// Command first calls two C functions: one written in the comment above
// import "C", and one from the C maths library.
package main

/*
#cgo LDFLAGS: -lm
#include <math.h>

// mean divides in floating point, which C's integer division would not.
static double mean(long total, int n) {
	return (double)total / n;
}
*/
import "C"

import "fmt"

func main() {
	total, n := 7, 2
	m := C.mean(C.long(total), C.int(n))
	fmt.Printf("%T %v\n", m, m)
	fmt.Printf("%.4f\n", float64(C.cbrt(m)))
	fmt.Println(C.sizeof_long, C.sizeof_int, C.sizeof_double)
}
```

**The comment directly above `import "C"` is C source**, and the cgo documentation calls it the
preamble. It is compiled as the header of the package's C half, so anything declared in it can be
called from Go as a member of `C`. Here that is `mean`, a function written on the spot, and `cbrt`,
the cube root, which `math.h` declares and the C maths library defines. "Directly" is literal. The
documentation's rule is that the comment must immediately precede the import, so a blank line
between them turns the preamble into an ordinary comment and every `C.` name into an error. That is
why `import "C"` conventionally stands on a line of its own, apart from the other imports, with the
preamble sitting right on top of it.

One line in the preamble is not C at all. **`#cgo LDFLAGS: -lm` is a directive to cgo**,
read and removed before `gcc` sees the rest, and it tells the build to pass `-lm`, "link the
maths library", to the linker. `#cgo CFLAGS:` does the same for the compiler, and `#cgo
pkg-config: zlib` asks `pkg-config` for both. The flags a directive may carry are limited, notably
to `-D`, `-U`, `-I` and `-l`, because a dependency's source should not be able to hand your
compiler any option it likes. The `CGO_CFLAGS` and `CGO_LDFLAGS` variables pass anything else,
from your environment rather than from somebody's code.

## Types that do not mix

cgo is on by default wherever the go command finds a C compiler, and it says which one it will use:

```
ana@vm:~/cgo$ go env CC CXX CGO_ENABLED
gcc
g++
1
```

Built and run, `first` prints a type, a cube root and three sizes. The build is shown in full
further down; this is what the program said:

```
ana@vm:~/cgo$ GOCACHE=/tmp/cgo-cold go build -x -o bin/ ./first 2> build.log && bin/first
main._Ctype_double 3.5
1.5183
8 4 8
```

**Every C type has a Go twin with a name of its own.** `C.double` is the Go type
`main._Ctype_double`, and the same goes for `C.int`, `C.long`, `C.size_t` and `C.char`. They are
distinct from Go's `float64` and `int` even where the bits agree. They also belong to the package
that wrote `import "C"`, so a `C.int` in one package is a different type from a `C.int` in another,
which is why the documentation advises never putting C types in a package's exported API. The
last line shows why the names are kept apart. `C.sizeof_long` is 8 and `C.sizeof_int` is 4 on this
machine, while Go's `int` is 8: a C `int` and a Go `int` are not the same size, and on 64-bit Windows
a C `long` is 4 bytes rather than 8.

So **every value crosses with an explicit conversion**, `C.long(total)` on the way in and
`float64(...)` on the way out. Leaving the conversions out is a compile error, and the quickest way
to see it is a copy of `first` with them taken out by `sed`:

```
ana@vm:~/cgo$ mkdir -p noconv && sed 's/C.long(total), C.int(n)/total, n/' first/main.go > noconv/main.go && go build -o bin/ ./noconv
# example.com/cgo/noconv
noconv/main.go:20:14: cannot use total (variable of type int) as C.long value in argument to (C.mean)
noconv/main.go:20:21: cannot use n (variable of type int) as C.int value in argument to (C.mean)
```

That strictness is the useful kind. The Go compiler checks every call into C against the
declaration in the preamble, with the same rules it applies to Go code, so a wrong argument count
or a pointer where a number belongs fails here rather than at run time.

## A library that was not linked

The other mistake fails one step further on, in the link. A copy with the `LDFLAGS` line removed
compiles, because `math.h` still declares `cbrt`. Then the linker has nothing to join the call to:

```
ana@vm:~/cgo$ mkdir -p nolm && grep -v LDFLAGS first/main.go > nolm/main.go && go build -o bin/ ./nolm 2>&1 | grep -E "running gcc|undefined"
/usr/local/go/pkg/tool/linux_amd64/link: running gcc failed: exit status 1
/tmp/go-build/main.cgo2.c:54:(.text+0x1a): undefined reference to `cbrt'
```

**A header tells the compiler a function exists; only the library gives the linker its code.** The
full message is a page of `gcc` command line, which the `grep` trims to the two lines that matter:
Go's linker ran `gcc` to finish the job, and `gcc` found no `cbrt` in anything it was given.
`undefined reference` in a cgo build almost always means a missing `-l` in `LDFLAGS`, or a library
whose development package is not installed.

## What the go command ran

The `-x` flag prints every command a build runs. The build above used an empty cache in
`/tmp/cgo-cold`, so that nothing came from a previous run, and saved the list to `build.log`. It is
long, nearly all of it the standard library being compiled, and the main package's work is the part
under `$WORK/b001`. The second command keeps those lines, and of each one the program it ran and its
last two arguments:

```
ana@vm:~/cgo$ wc -l < build.log
859
ana@vm:~/cgo$ grep b001 build.log | grep -v '#' | grep -E '^([A-Z_]+=[^ ]* )*(gcc|[^ ]*/(cgo|compile|link)) ' | sed -E 's/^([A-Z_]+=[^ ]* )+//' | awk '{print $1, $(NF-1), $NF}'
/usr/local/go/pkg/tool/linux_amd64/cgo -g ./main.go
gcc -c _cgo_export.c
gcc -c main.cgo2.c
gcc -c _cgo_main.c
gcc -g -lm
/usr/local/go/pkg/tool/linux_amd64/cgo -dynout $WORK/b001/_cgo_import.go
/usr/local/go/pkg/tool/linux_amd64/compile $WORK/b001/main.cgo1.go $WORK/b001/_cgo_import.go
/usr/local/go/pkg/tool/linux_amd64/link -extld=gcc $WORK/b001/_pkg_.a
```

Read top to bottom, it is the pipeline from the first paragraph:

| step | what it does |
|---|---|
| `cgo ./main.go` | splits the file: `main.cgo1.go`, the Go half with every `C.x` rewritten as a call to generated code, and `main.cgo2.c`, the preamble plus a small C wrapper for each function called |
| `gcc -c` three times | compiles the C half and the files cgo generated around it |
| `gcc -g -lm` | links those objects once with `-lm`, to find out which symbols come from shared libraries |
| `cgo -dynout` | writes that answer down as Go, in `_cgo_import.go` |
| `compile` | compiles the Go half, the same compiler as always |
| `link -extld=gcc` | links the program, and hands the final step to `gcc` |

**A cgo build runs `gcc` at least five times for a seven-line preamble**, and every run is a
place where the C toolchain, its headers and its libraries have to be present and right. That is
what `CGO_ENABLED=1` was reporting all along, and it is the thread the last two sections of this
lesson pull on.
