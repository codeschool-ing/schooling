---
title: What changes with the target
version: 1
---

`hits` cross-compiled without a word of complaint, and it is tempting to conclude that any Go
program does. **Three things about a build depend on the target.** Each can turn a program that
builds here into one that fails to build for another machine, or builds into something different:
cgo, the files a package chooses by operating system and processor, and the oldest processor the
code is allowed to assume.

## cgo is off unless you turn it on

Lesson 1's lab section showed `CGO_ENABLED` dropping to `0` on a machine with no C compiler. Cross
builds drop it too, on a machine that has one:

```
ana@vm:~/cross$ go env CGO_ENABLED; GOARCH=arm64 go env CGO_ENABLED; GOOS=windows go env CGO_ENABLED
1
0
0
```

**The host's `gcc` makes code for the host**, so the go command does not hand it a cross build. The
documentation of cgo says it in one sentence: cgo "is disabled by default when cross-compiling".
What that costs depends on the program, and there are two cases worth seeing.

### A package with two implementations

Some standard packages can do their job either through the C library or in pure Go, and pick by
whether cgo is on. `os/user`, which looks up accounts, is one. A program that asks it who is
running, `who/main.go`:

```go
// Command who prints the user running it and their home directory.
package main

import (
	"fmt"
	"os/user"
)

func main() {
	u, err := user.Current()
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(u.Username, u.HomeDir)
}
```

It lives in a module of its own, `~/cross/who`, made with `go mod init example.com/who`. Built for
this machine and for `arm64`:

```
ana@vm:~/cross/who$ go build -o who . && GOARCH=arm64 go build -o who-arm64 .
ana@vm:~/cross/who$ file who who-arm64 | cut -d, -f1,2,4
who:       ELF 64-bit LSB executable, x86-64, dynamically linked
who-arm64: ELF 64-bit LSB executable, ARM aarch64, statically linked
ana@vm:~/cross/who$ ./who; qemu-aarch64-static ./who-arm64
ana /home/ana
ana /home/ana
ana@vm:~/cross/who$ go list -f '{{.CgoFiles}}' os/user; GOARCH=arm64 go list -f '{{.CgoFiles}}' os/user
[cgo_lookup_cgo.go getgrouplist_unix.go]
[]
```

**The native build is `dynamically linked` and the cross build is `statically linked`**, from the
same sixteen lines. `go list -f '{{.CgoFiles}}'` names the files of a package that use cgo, and the
answer depends on the target. Natively the package compiles two cgo files that call the C library's
account functions, and for `arm64` it compiles none and uses its other implementation, which reads
`/etc/passwd` and `/etc/group` itself. Here both found Ana. On a machine where accounts come from a
company directory that the C library is configured to ask, the pure Go version sees only what
`/etc/passwd` lists, and the two builds can disagree about a user. `net` has the same split for
looking up host names.

### A package that needs C

A program that calls C itself has no second implementation to fall back on. Here is the smallest one
there is, in a module of its own in `~/cross/twice`. Lesson 23 is about what the comment above
`import "C"` does; here it is enough to know that `gcc` compiles the C function in it.
`twice/main.go`:

```go
// Command twice asks a C function to double a number.
package main

// int twice(int x) { return 2 * x; }
import "C"

import "fmt"

func main() {
	fmt.Println(C.twice(21))
}
```

```
ana@vm:~/cross/twice$ go build -o twice . && ./twice
42
ana@vm:~/cross/twice$ GOARCH=arm64 go build -o twice-arm64 .; echo $?
package example.com/twice: build constraints exclude all Go files in /home/ana/cross/twice
1
ana@vm:~/cross/twice$ CGO_ENABLED=1 GOARCH=arm64 go build -o twice-arm64 . 2>&1 | head -4
# runtime/cgo
gcc_arm64.S: Assembler messages:
gcc_arm64.S:30: Error: no such instruction: `stp x29,x30,[sp,'
gcc_arm64.S:34: Error: operand size mismatch for `mov'
```

Natively it prints 42. For `arm64` the build fails with a message that does not mention cgo at all.
**A file that imports `"C"` is built only when cgo is on**, so with cgo off the go command left
`main.go` out, and a package with no files left is the error it reports. Turning cgo on by hand gets
further and fails worse. The go command handed the host's `gcc` the ARM assembly of its own runtime,
and an assembler for Intel instructions has never heard of `stp x29,x30`. A cgo program for another
processor needs a C compiler for that processor, named in the `CC` variable; lesson 23 comes back to
that, and this lesson does not install one.

## Files chosen by the target

The `os/user` answer above came from file selection. `cgo_lookup_cgo.go` is compiled only when cgo
is on, `lookup_unix.go` only on Unix-like systems, and a package can carry a file per operating
system or per processor. **The build reads a different set of files for each target**, so a package
can compile for `linux` and fail for `windows` because the file that defines a function for Windows
was never written. The rules, written as a file name like `x_windows.go` or a `//go:build` line at
the top of a file, are lesson 11's subject. What matters here is recognising the symptom: the
message above that says *build constraints exclude all Go files*, or an `undefined:` error that
appears for one target only.

`hits` has none of this. It imports nothing that needs C and carries no file for one system, which
is why section 02's four builds needed nothing but the two variables.

## Same architecture, an older processor

`GOARCH` names an instruction set, and every instruction set has grown over the years. Four more
variables choose how much of that growth the compiler may use: `GOARM` for 32-bit ARM, `GOARM64` for
64-bit ARM, `GOAMD64` for Intel and AMD, and `GO386` for 32-bit Intel. `go help environment` lists
their values. 32-bit ARM is where the choice is most often needed, because old boards are still in
service:

```
ana@vm:~/cross$ GOARCH=arm go env GOARM
7
ana@vm:~/cross$ GOARCH=arm GOARM=6 go build -o hits-armv6 . && file hits-armv6 | cut -d, -f1,2
hits-armv6: ELF 32-bit LSB executable, ARM
ana@vm:~/cross$ qemu-arm-static ./hits-armv6 top -n 2 access.log
path         requests
/login       2576
/api/orders  2542
```

**The default for a cross build to `arm` is ARMv7**, and the first Raspberry Pi and the Pi Zero have
ARMv6 processors, which lack some of the instructions ARMv7 code uses. `GOARM=6` builds for them,
and `qemu-arm-static`, the 32-bit ARM emulator, ran the result and printed the same two rows as
every other build in this lesson.

On Intel and AMD the levels are called `v1` to `v4`. `v1` is the 64-bit instruction set of 2003 and
is the default; `v3` adds, among others, the AVX2, BMI and FMA instructions of Intel processors from
2013 on. A `v3` build lets the compiler use them, and the runtime checks at start-up that the
processor really has them. QEMU can pretend to be an older processor with `-cpu`, and `Nehalem` is
an Intel design from 2008:

```
ana@vm:~/cross$ go env GOAMD64
v1
ana@vm:~/cross$ GOAMD64=v3 go build -o hits-v3 . && go version -m hits-v3 | grep GOAMD64
	build	GOAMD64=v3
ana@vm:~/cross$ ./hits-v3 top -n 2 access.log
path         requests
/login       2576
/api/orders  2542
ana@vm:~/cross$ qemu-x86_64-static -cpu Nehalem ./hits-v3 top -n 2 access.log; echo $?
This program can only be run on AMD64 processors with v3 microarchitecture support.
1
ana@vm:~/cross$ qemu-x86_64-static -cpu Nehalem ./hits top -n 2 access.log; echo $?
path         requests
/login       2576
/api/orders  2542
0
```

**The `v3` binary refused to start on the older processor**, with a one-line message and exit status
1, before `main` ran; the `v1` binary of section 02 ran on it unchanged. That refusal is the cost of
raising the level, and the check exists so that it is a clear one rather than a crash at the first
AVX2 instruction somewhere in the middle of a run. Whether the level buys anything for a given
program is a question for a benchmark, the kind `go-concurrency` lesson 29 writes. Until one says
so, **ship `v1`**, which every 64-bit Intel and AMD processor runs.
