---
title: One file to copy
version: 1
---

To run a Python program on a server, you install Python on the server first; a Java program needs
a Java runtime, and a Node program needs Node. It is easy to assume every language works that way.
Go does not. **The go command compiles a program into machine code for one operating system and
one processor, and the result is a single file that needs nothing else installed.** This section
builds one, looks at what it asks of the machine, and builds it again for machines this lab is not.

The program says which system it was compiled for:

```go
// Command why says which system it was compiled for.
package main

import (
	"fmt"
	"runtime"
)

func main() {
	fmt.Println("compiled for", runtime.GOOS+"/"+runtime.GOARCH, "by", runtime.Version())
}
```

`runtime.GOOS` and `runtime.GOARCH` are fixed when the program is compiled, so they report the
system the binary was built **for**, whatever machine it later runs on. That makes the cross-builds
at the end of this section easy to tell apart.

```
ana@vm:~/why$ go clean -cache
ana@vm:~/why$ time go build

real	0m4.738s
user	0m10.803s
sys	0m1.688s
ana@vm:~/why$ ./why
compiled for linux/amd64 by go1.27.1
ana@vm:~/why$ wc -c main.go why
    201 main.go
2342001 why
2342202 total
```

The cache was emptied first, so most of the 4.738 seconds went on compiling the parts of the
standard library the program uses, exactly as in lesson 4. The 201 bytes of source became
2,342,001 bytes of program, and the difference is the Go runtime, which every Go program carries:
the memory manager, the scheduler, the code that prints a stack trace.

## What the file asks of the machine

Three commands answer the question from three directions:

```
ana@vm:~/why$ file why
why: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=WwBw_hKHsHbVuataMSov/IzDaYBoww3uTpwLKqiZV/2TCEAa5I9bA-iMoBjqc5/jV7AQI73pmBUDpWB8c01, BuildID[sha1]=68ce336aee68663de8c691b0449381323b0488e6, with debug_info, not stripped
ana@vm:~/why$ ldd why
	not a dynamic executable
ana@vm:~/why$ readelf -d why

There is no dynamic section in this file.
ana@vm:~/why$ readelf -d /bin/ls | grep NEEDED
 0x0000000000000001 (NEEDED)             Shared library: [libselinux.so.1]
 0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
```

`file` says `statically linked`. `ldd`, which lists the shared libraries a program loads, has none
to list. `readelf -d` prints a binary's dynamic section, the part where those libraries would be
named, and `why` has no such section at all. `/bin/ls`, a C program, names two: `libselinux.so.1`
and `libc.so.6` have to be on the machine already, in a version that fits, or `ls` does not start.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Two programs and what each needs from the machine. On the left, /bin/ls, a C program: the file holds its own code and points at two shared libraries, libselinux.so.1 and libc.so.6, which must already be on the machine and are loaded when it starts, before it reaches the Linux kernel. On the right, why, a Go program: one file of 2,342,001 bytes holding your code, the packages it imports and the Go runtime, talking to the kernel directly.\"><defs><marker id=\"l1bin-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l1bin-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"160\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a C program</text><rect x=\"40\" y=\"48\" width=\"140\" height=\"72\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/bin/ls</text><text x=\"110\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">its own code</text><rect x=\"222\" y=\"44\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"292\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">libselinux.so.1</text><rect x=\"222\" y=\"92\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"292\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">libc.so.6</text><path d=\"M180 66 L220 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1bin-phosphor)\"></path><path d=\"M180 102 L220 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1bin-phosphor)\"></path><text x=\"300\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">found on the machine</text><text x=\"300\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">when it starts</text><path d=\"M110 120 L110 226\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1bin-wire)\"></path><path d=\"M292 124 L292 226\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1bin-wire)\"></path><text x=\"550\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a Go program</text><rect x=\"420\" y=\"40\" width=\"260\" height=\"156\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"550\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">why</text><rect x=\"440\" y=\"74\" width=\"220\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">your code</text><rect x=\"440\" y=\"112\" width=\"220\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the packages it imports</text><rect x=\"440\" y=\"150\" width=\"220\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the Go runtime</text><text x=\"500\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2,342,001 bytes, one file</text><path d=\"M640 196 L640 226\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1bin-wire)\"></path><rect x=\"40\" y=\"228\" width=\"640\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the Linux kernel</text></svg>", "caption": "What each program needs when it starts. /bin/ls names two shared libraries that must already be on the machine; why carries its packages and the Go runtime inside the file and asks only the kernel."}
```

**Copy `why` to any Linux machine on an x86-64 processor and it runs**, with no Go installed and
no library to match. That is the trade Go makes: a bigger file, in exchange for nothing to install
beside it. Lesson 4 comes back to it when it builds its first program.

## The exception: a C compiler on the machine

One file is the default and not a law. This program asks the operating system for the address of
`localhost`:

```go
// Command lookup resolves a host name.
package main

import (
	"fmt"
	"net"
)

func main() {
	addrs, err := net.LookupHost("localhost")
	fmt.Println(addrs, err)
}
```

```
ana@vm:~/why-net$ go env CGO_ENABLED
1
ana@vm:~/why-net$ go build && ./lookup
[127.0.0.1] <nil>
ana@vm:~/why-net$ file lookup
lookup: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, Go BuildID=Xxy7vpsJBpPu2GZgP08g/vrk3hxOuiD6NpMAG-oXk/Z7wh7g3Am7uWtKGyjlO5/KUIGafK3cqceQw2ti98l, BuildID[sha1]=7efe1b9bfe64020edae1653574ab38d94bb4a972, with debug_info, not stripped
ana@vm:~/why-net$ readelf -d lookup | grep NEEDED
 0x0000000000000001 (NEEDED)             Shared library: [libc.so.6]
ana@vm:~/why-net$ CGO_ENABLED=0 go build && file lookup
lookup: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, Go BuildID=OteiPLfIk6JdDu5DYCYC/e8Xk6ckEUUe3G3QF1_Y2/_dx7mW5qgQVmWz9Em7A9/jNDDMJFqKt1CTNcrcMW8, BuildID[sha1]=110866a3acf76909aee5b8259ee664d3c8274124, with debug_info, not stripped
```

This time the binary is `dynamically linked` and needs `libc.so.6`. `go doc net` explains why under
*Name Resolution*: the `net` package can resolve names itself, or through C library routines such
as `getaddrinfo`, and it keeps the C route available when it can. **That route is cgo, the part of
the go command that lets Go call C**, and `go env` shows it switched on. `go doc cmd/cgo` says when:
it is enabled for native builds on a machine where a C compiler is found on the `PATH`, which this
lab has, because `gcc` is installed. With `CGO_ENABLED=0` the same source builds static again.

So a Go program is one self-contained file unless something in it uses C, and you can see which
case you have with `file` before you ship it.

## Building for another machine

`GOOS` and `GOARCH` choose the system a build is for. Set them on the command line and the go
command compiles for that system instead of this one:

```
ana@vm:~/why$ time GOOS=windows GOARCH=amd64 go build -o why.exe

real	0m4.752s
user	0m10.981s
sys	0m1.885s
ana@vm:~/why$ GOOS=darwin GOARCH=arm64 go build -o why-mac
ana@vm:~/why$ GOOS=linux GOARCH=arm64 go build -o why-arm64
ana@vm:~/why$ file why.exe why-mac why-arm64
why.exe:   PE32+ executable (console) x86-64, for MS Windows, 16 sections
why-mac:   Mach-O 64-bit arm64 executable, flags:<|DYLDLINK|PIE>
why-arm64: ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, Go BuildID=1fHCSRqENJHPXzkxYIb4/t2KOm_kz4tkhJ0DbG5_X/u2ch0QQcx8ZxIhccHute/GZbPcB6-dbDgaKdq3Xz2, BuildID[sha1]=b89614b04ff4a62c60f300afc43fbf27518891c1, with debug_info, not stripped
ana@vm:~/why$ ./why-arm64
bash: line 1: ./why-arm64: cannot execute binary file: Exec format error
```

Three binaries for three systems, from one Linux machine, and **nothing was installed to make
them**: the Go toolchain carries the compiler for every target it supports. The Windows build took
4.752 seconds because the cache held the standard library compiled for Linux and not for Windows;
the Mac and ARM builds came after it and were not timed.

The last line is the proof that the ARM binary really is for another processor. This machine is
x86-64, so the kernel refuses to run code for ARM. Copied to an ARM server running 64-bit
Linux, it would print `compiled for linux/arm64`.

The Mac binary carries `DYLDLINK` because on macOS the Go runtime calls the system through Apple's
own library, `/usr/lib/libSystem.B.dylib`, rather than the kernel directly; `src/runtime/sys_darwin.go`
in the Go source names it on every import. Every Mac has that library, so it is still one file to
copy. None of these three binaries was run in the lab, because there is no Windows, Mac or ARM
machine in it.

How many systems can one Go build for? The go command lists them:

```
ana@vm:~/why$ go tool dist list | wc -l
47
ana@vm:~/why$ go tool dist list | grep linux
linux/386
linux/amd64
linux/arm
linux/arm64
linux/loong64
linux/mips
linux/mips64
linux/mips64le
linux/mipsle
linux/ppc64
linux/ppc64le
linux/riscv64
linux/s390x
```

Forty-seven pairs of operating system and processor, thirteen of them Linux. Each is a value you
can put in `GOOS` and `GOARCH`.
