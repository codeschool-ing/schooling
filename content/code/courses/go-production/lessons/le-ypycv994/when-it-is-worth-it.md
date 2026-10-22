---
title: When it is worth paying for
version: 1
---

Sections 04 and 05 priced cgo in nanoseconds, threads, seconds of build and a binary that only runs
where its libraries are. Two more costs are not numbers, and then the question the whole lesson
leads to: **when is it worth it?** The short answer is when there is a C library you need and no
way to replace it. The long answer is a list of places to look first.

## The standard library's own C

Two packages use C on Linux without your asking: `net`, for looking up host names, and `os/user`,
for accounts. Lesson 16 showed their pure Go halves taking over when cgo is off. **Two build tags
choose the pure Go halves with cgo still on**, which matters when a program has C of its own and
cannot turn cgo off. `lookup/main.go` asks both packages a question:

```go
// Command lookup asks two standard packages that can use the C library
// who is running it and what localhost resolves to.
package main

import (
	"fmt"
	"net"
	"os/user"
)

func main() {
	u, err := user.Current()
	fmt.Println(u.Username, err)
	addrs, err := net.LookupHost("localhost")
	fmt.Println(addrs, err)
}
```

```
ana@vm:~/cgo$ go build -o bin/ ./lookup && file bin/lookup | cut -d, -f1,4 && bin/lookup
bin/lookup: ELF 64-bit LSB executable, dynamically linked
ana <nil>
[127.0.0.1] <nil>
ana@vm:~/cgo$ go build -tags netgo,osusergo -o bin/lookup-pure ./lookup && file bin/lookup-pure | cut -d, -f1,4 && bin/lookup-pure
bin/lookup-pure: ELF 64-bit LSB executable, statically linked
ana <nil>
[127.0.0.1] <nil>
ana@vm:~/cgo$ go list -f "{{.ImportPath}} {{.CgoFiles}}" net os/user
net [cgo_linux.go cgo_resnew.go cgo_socknew.go cgo_unix_cgo.go cgo_unix_cgo_res.go]
os/user [cgo_lookup_cgo.go getgrouplist_unix.go]
ana@vm:~/cgo$ go list -tags netgo,osusergo -f "{{.ImportPath}} {{.CgoFiles}}" net os/user
net []
os/user []
```

`go list -f '{{.CgoFiles}}'` names the files in a package that import `"C"`. **`netgo` and
`osusergo` empty both lists, and the binary comes out static** with the same two answers. The
answers can differ on other machines. The C library may be configured to ask a company directory
for accounts, or to resolve names in ways Go's resolver does not implement, while the pure Go halves
read the files under `/etc` themselves. The tags cannot remove C that you wrote: a program
that imports zlib stays dynamic, whatever tags it is built with.

## A crash in C is a crash of the program

In Go, a nil pointer dereference is a panic, and a deferred `recover` can stop it from ending the
program. **In C, the same mistake is a signal that the Go runtime does not turn into a panic**: it
cannot know what state the C code was left in, so it stops everything. `crash/main.go` makes the mistake twice,
under the same `recover`:

```go
// Command crash reads through a null pointer twice: once in Go, where
// recover catches it, and once in C, where nothing can.
package main

/*
static int first(const int *p) { return p[0]; }
*/
import "C"

import "fmt"

func try(name string, f func() int) {
	defer func() {
		if r := recover(); r != nil {
			fmt.Println(name, "recovered:", r)
		}
	}()
	fmt.Println(name, "returned", f())
}

func main() {
	var p *int
	try("go", func() int { return *p })
	try("c", func() int { return int(C.first(nil)) })
	fmt.Println("still running")
}
```

```
ana@vm:~/cgo$ go build -o bin/ ./crash && bin/crash 2>&1 | head -4; echo ${PIPESTATUS[0]}
go recovered: runtime error: invalid memory address or nil pointer dereference
SIGSEGV: segmentation violation
PC=0x49c096 m=0 sigcode=1 addr=0x0
signal arrived during cgo execution
2
```

The Go half was recovered and the program went on. The C half killed it with exit status 2 in
the middle of `try`, and `still running` was never printed. `signal arrived during cgo execution`
is the runtime saying where it was; the four lines are the start of a dump of every goroutine,
which `head` cut off. A C library with a bug in it is now a bug that takes the whole process with
it, every goroutine included. The race detector of lesson 15 is a cost in the other direction: it is built on cgo, so a
pipeline that turns cgo off to get static binaries loses it.

## Where to look before writing `import "C"`

| what you give up | measured in this lesson |
|---|---|
| a cheap call | 28.70 ns per call against 0.7894 ns, section 04 |
| a cheap goroutine | 104 threads for 100 goroutines asleep in C, against 6 |
| a static binary | `libz.so.1`, `libc.so.6` and the loader, needed at run time |
| cross-compiling | no `aarch64-linux-gnu-gcc`, and no ARM zlib to link |
| a fast cold build | 32.722 s to compile SQLite's C |
| Go's errors and Go's crashes | a truncated file reported only if you ask `gzerror`; a C crash that `recover` cannot catch |

**cgo is worth that bill when a C library does something you need and cannot get any other way**:
a database engine, a codec, a vendor's SDK for a device, an operating system interface Go does not
wrap. Before paying it, the places to look are, in order:

1. **The standard library.** `compress/gzip` and `hash/crc32` replaced both of this lesson's uses
   of zlib, and `hash/crc32` was 9 times faster than it. `crypto`, `image`, `archive` and
   `compress` do in Go what other languages often hand to a C library.
2. **A pure Go port.** The C library's work, rewritten or translated into Go: `modernc.org/sqlite`
   describes itself as "a CGo-free port of the C SQLite3 library", which by that description needs
   no C compiler to build, for any target.
3. **A separate process.** If the C exists as a command-line tool, `os/exec` runs it as a program
   of its own. A crash stays in that process and the build does not change. The cost per call is a
   process start, which is fine for work done once per file and terrible for work done once per
   line.

When none of those fits, **put the cgo in one small package**, the way `cost` and `gzlines` do.
Keep C types out of its exported API, give every `C.CString` its `defer C.free`, put the loops on
the C side, and respect the pointer rules rather than switching them off. Without cgo such a package fails at
build time, as `gzlines` did for ARM, which is the failure you want: go-sqlite3's stub failed at run
time.
