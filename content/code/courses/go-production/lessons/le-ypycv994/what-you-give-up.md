---
title: What the binary gives up
version: 1
---

The usual picture of cgo is that it changes how one call is made and leaves the rest of the program
alone. **It changes the binary, the build, and what every machine that builds or runs the program
must have.** Lessons 16 and 18 showed those effects on a standard package that happens to use C.
This section measures them on programs that call C on purpose, with a twin that does the same job
in pure Go beside each one.

## The pure Go twin

`gzgo` counts the lines of a gzip file like section 03's `gzlines`, with the standard library's
`compress/gzip` instead of zlib. `gzgo/main.go`:

```go
// Command gzgo counts the lines of a gzip-compressed file, like gzlines,
// with the standard library's compress/gzip and no C at all.
package main

import (
	"bytes"
	"compress/gzip"
	"fmt"
	"io"
	"os"
)

func main() {
	for _, name := range os.Args[1:] {
		n, err := count(name)
		if err != nil {
			fmt.Fprintln(os.Stderr, "gzgo:", err)
			os.Exit(1)
		}
		fmt.Println(n, name)
	}
}

// count reads name through a gzip reader and counts the newlines.
func count(name string) (int, error) {
	f, err := os.Open(name)
	if err != nil {
		return 0, err
	}
	defer f.Close()
	zr, err := gzip.NewReader(f)
	if err != nil {
		return 0, fmt.Errorf("%s: %w", name, err)
	}
	buf := make([]byte, 64*1024)
	lines := 0
	for {
		n, err := zr.Read(buf)
		lines += bytes.Count(buf[:n], []byte{'\n'})
		if err == io.EOF {
			return lines, nil
		}
		if err != nil {
			return lines, fmt.Errorf("%s: %w", name, err)
		}
	}
}
```

## Dynamically linked

```
ana@vm:~/cgo$ go build -o bin/ ./gzgo && file bin/gzlines bin/gzgo | cut -d, -f1,4
bin/gzlines: ELF 64-bit LSB executable, dynamically linked
bin/gzgo:    ELF 64-bit LSB executable, statically linked
ana@vm:~/cgo$ ldd bin/gzlines | awk '{print $1}'
linux-vdso.so.1
libz.so.1
libc.so.6
/lib64/ld-linux-x86-64.so.2
ana@vm:~/cgo$ bin/gzgo access.log.gz cut.gz; echo $?
20000 access.log.gz
gzgo: cut.gz: unexpected EOF
1
```

**`gzlines` is dynamically linked and `gzgo` is static.** `ldd` lists what the loader must find
before `gzlines` can start: `libz.so.1`, the C library `libc.so.6`, and the loader itself;
`linux-vdso.so.1` is supplied by the kernel and is never a file. Every machine that runs `gzlines`
needs a compatible zlib installed, and lesson 18 showed what a dynamic binary does in an image that
has no loader at all. `gzgo` carries everything it runs, and it reports the cut file in Go's own
terms, as `unexpected EOF` from the reader, with no second call to ask whether the end was the end of
the data.

A static binary with C in it is possible when every library has a static archive. Ubuntu's
`zlib1g-dev` ships `libz.a` beside `libz.so`, and `-extldflags=-static` asks `gcc`, the external
linker, to use archives only:

```
ana@vm:~/cgo$ go build -ldflags=-extldflags=-static -o bin/gzlines-static ./gzlines && file bin/gzlines-static | cut -d, -f1,4 && bin/gzlines-static access.log.gz
bin/gzlines-static: ELF 64-bit LSB executable, statically linked
zlib 1.3
20000 access.log.gz
ana@vm:~/cgo$ stat -c "%s bytes  %n" bin/gzlines bin/gzlines-static bin/gzgo
2374888 bytes  bin/gzlines
3491192 bytes  bin/gzlines-static
2521628 bytes  bin/gzgo
```

**Static, and 1.1 MB bigger**, because zlib and the parts of the C library it uses are now copied
into the file. It also took a flag a reader of the build has to understand, and it depends on a
static archive that not every C library ships; the pure Go twin was static by doing nothing.

## Cross-compiling stops working

Lesson 16 showed what a cross build does to a file that imports `"C"`. Here it is on `gzlines`.
The second command turns cgo on and names a C compiler for ARM in `CC`, which is how the cgo
documentation says a cross build must be done:

```
ana@vm:~/cgo$ GOARCH=arm64 go build -o bin/gzlines-arm64 ./gzlines; echo $?
package example.com/cgo/gzlines: build constraints exclude all Go files in /home/ana/cgo/gzlines
1
ana@vm:~/cgo$ CGO_ENABLED=1 GOARCH=arm64 CC=aarch64-linux-gnu-gcc go build -o bin/gzlines-arm64 ./gzlines; echo $?
# runtime/cgo
cgo: C compiler "aarch64-linux-gnu-gcc" not found: exec: "aarch64-linux-gnu-gcc": executable file not found in $PATH
1
ana@vm:~/cgo$ GOARCH=arm64 go build -o bin/gzgo-arm64 ./gzgo && qemu-aarch64-static bin/gzgo-arm64 access.log.gz
20000 access.log.gz
```

**With cgo off, `gzlines` has no files left to build; with it on, there is no compiler to build
them.** `aarch64-linux-gnu-gcc` is Ubuntu's cross compiler for 64-bit ARM, and this lesson does not
install it. Installing it would not be the end either. The cross build also needs the C library's
headers and libraries for ARM, and an ARM build of zlib to link against, and every C library the
program uses multiplies that. `clang`, which can generate ARM code with `--target`, was tried in the
lab and stopped at the first header of the C library, for the same reason. `gzgo` crossed in one
command, and `qemu-aarch64-static`, the emulator lesson 16 used, ran it.

## The build gets slower, sometimes much slower

`gzlines` asks `gcc` to compile only the few lines cgo generates around its calls, because zlib
arrived on the machine already compiled. A cgo package that brings its C as source is another matter. The best-known one is
`github.com/mattn/go-sqlite3`, a driver for the `database/sql` package that compiles SQLite itself.
A program that only asks it for its version, `sq/main.go`:

```go
// Command sq asks SQLite, through the cgo driver go-sqlite3, which version
// of SQLite it is.
package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

func main() {
	log.SetFlags(0)
	db, err := sql.Open("sqlite3", ":memory:")
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()
	var v string
	if err := db.QueryRow("select sqlite_version()").Scan(&v); err != nil {
		log.Fatal(err)
	}
	fmt.Println("sqlite", v)
}
```

```
ana@vm:~/cgo$ go get github.com/mattn/go-sqlite3@v1.14.52
go: added github.com/mattn/go-sqlite3 v1.14.52
ana@vm:~/cgo$ cd $(go env GOMODCACHE)/github.com/mattn/go-sqlite3@v1.14.52 && wc -l sqlite3-binding.c && head -4 sqlite3-binding.c | tail -2
269653 sqlite3-binding.c
** This file is an amalgamation of many separate C source files from SQLite
** version 3.53.4.  By combining all the individual C code files into this
```

Ana had downloaded the module before, so the go command did not print its `go: downloading` line.
**The module carries SQLite as one C file of 269,653 lines**, the amalgamation its own header
describes, and `gcc` compiles all of it. The command below times three builds with an empty cache in
`/tmp/cgo-cold`: `gzgo` first, which fills that cache with the standard library, then `sq`, then
`sq` again:

```
ana@vm:~/cgo$ TIMEFORMAT="%R s"; time GOCACHE=/tmp/cgo-cold go build -o /dev/null ./gzgo; time GOCACHE=/tmp/cgo-cold go build -o bin/ ./sq; time GOCACHE=/tmp/cgo-cold go build -o /dev/null ./sq
4.623 s
32.722 s
0.634 s
```

**4.623 s for all of `gzgo` and the standard library under it; 32.722 s more for `sq`**, nearly all of
it `gcc` compiling SQLite; 0.634 s once the result is cached. The cache hides it on a laptop that
builds every day. It does not hide it from a CI runner that starts empty, from the first build after
a Go upgrade, or from `go test -race`, which builds a separate set of packages.

The other thing `sq` shows is what happens without cgo. The binary links SQLite in, so `ldd` lists
only the C library and the loader. Built with `CGO_ENABLED=0`, it still builds:

```
ana@vm:~/cgo$ bin/sq; ldd bin/sq | awk "{print \$1}"
sqlite 3.53.4
linux-vdso.so.1
libc.so.6
/lib64/ld-linux-x86-64.so.2
ana@vm:~/cgo$ CGO_ENABLED=0 go build -o bin/sq-nocgo ./sq && bin/sq-nocgo; echo $?
Binary was compiled with 'CGO_ENABLED=0', go-sqlite3 requires cgo to work. This is a stub
1
```

**The build succeeded and the program failed when it ran.** go-sqlite3 ships a stub for builds
without cgo, so that a package depending on it still compiles, and the stub's first act is to
refuse. A release script that sets `CGO_ENABLED=0`, as lesson 16's does, produces a binary that
passes every step of the pipeline that does not open a database.
