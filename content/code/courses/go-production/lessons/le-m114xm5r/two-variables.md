---
title: Two variables choose the machine
version: 1
---

A C programmer who wants a binary for a Raspberry Pi on an Intel laptop needs a second compiler: a
GCC built to emit ARM code, with a copy of the target's C library and headers beside it. **Go needs
two environment variables.** `GOOS` names the operating system the binary will run on and `GOARCH`
names the processor, and the same `go build` that makes a binary for this machine makes one for any
pair the toolchain knows. Nothing else is installed.

This lesson works on `hits` exactly as lesson 1 left it: the `tally` package, `main.go`,
`main_test.go` and `genlog`, in a fresh directory, `~/cross`, with the 20,000-line `access.log` that
`go run ./tools/genlog -n 20000` writes. Nothing in the program changes in this lesson; only the
machine it is built for does.

## What the toolchain knows

Left unset, both variables take the values of the machine the go command is running on, and `go env`
prints them. `go tool dist list` prints every pair the installed toolchain can build for:

```
ana@vm:~/cross$ go env GOOS GOARCH
linux
amd64
ana@vm:~/cross$ go tool dist list | wc -l
47
ana@vm:~/cross$ go tool dist list | grep -E "^(linux|darwin|windows)/"
darwin/amd64
darwin/arm64
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
windows/386
windows/amd64
windows/arm64
ana@vm:~/cross$ go tool dist list -json | grep -c '"FirstClass": true'
8
```

**Go 1.27.1 builds for 47 pairs**, eighteen of them on the three systems most people ship to.
`darwin` is macOS, and `amd64` is the 64-bit Intel and AMD instruction set whatever the vendor calls
it. The `-json` form adds two fields per pair; eight carry `"FirstClass": true`, the ports the Go
team treats as its primary ones, and the other 39 are kept working by the people who look after
them. Every pair you are likely to ship `hits` to is among the eight, and so is the 64-bit ARM Linux
of a Raspberry Pi 4 or a cloud ARM server.

## Four builds from one directory

Set the two variables for one command, the way the shell sets any variable for one command, and
build. The first line is the ordinary native build, for comparison:

```
ana@vm:~/cross$ go build -o hits .
ana@vm:~/cross$ GOOS=linux GOARCH=arm64 go build -o hits-arm64 .
ana@vm:~/cross$ GOOS=darwin GOARCH=arm64 go build -o hits-mac .
ana@vm:~/cross$ GOOS=windows GOARCH=amd64 go build .
ana@vm:~/cross$ ls
access.log
go.mod
hits
hits-arm64
hits-mac
hits.exe
internal
main.go
main_test.go
tools
```

The last build had no `-o`, and **the go command named the output `hits.exe` by itself**, because a
Windows program needs the extension to be run by name. None of the four printed anything, which is
what success looks like for `go build`. The `file` command reads the first bytes of each and says
what kind of executable it is. `cut` keeps the fields that matter here and drops the build ids:

```
ana@vm:~/cross$ file hits hits-arm64 hits-mac hits.exe | cut -d, -f1,2,4
hits:       ELF 64-bit LSB executable, x86-64, statically linked
hits-arm64: ELF 64-bit LSB executable, ARM aarch64, statically linked
hits-mac:   Mach-O 64-bit arm64 executable, flags:<|DYLDLINK|PIE>
hits.exe:   PE32+ executable (console) x86-64, for MS Windows
ana@vm:~/cross$ stat -c "%s bytes  %n" hits hits-arm64 hits-mac hits.exe
4031935 bytes  hits
3831466 bytes  hits-arm64
3909762 bytes  hits-mac
4217344 bytes  hits.exe
ana@vm:~/cross$ strings hits-mac | grep libSystem
/usr/lib/libSystem.B.dylib
```

**Three executable formats came out of one compiler**: ELF for Linux, Mach-O for macOS and PE32+ for
Windows. `aarch64` is what `file` calls the processor Go calls `arm64`. The sizes differ by a few
per cent because the instructions differ and so does each format's bookkeeping, and all four sit
near the **4,031,935 bytes** of the native build.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 260\" role=\"img\" aria-label=\"One module, main.go and internal/tally, goes through one go build, steered by GOOS and GOARCH, and comes out as four binaries: linux/amd64, an ELF of 4,031,935 bytes, built for the machine the build ran on; and, below a line where CGO_ENABLED drops from 1 to 0, linux/arm64 as an ELF of 3,831,466 bytes, darwin/arm64 as a Mach-O of 3,909,762 bytes that names libSystem, and windows/amd64 as a PE32+ named hits.exe of 4,217,344 bytes.\"><defs><marker id=\"cx-arrow\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"170\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">one module</text><rect x=\"36\" y=\"104\" width=\"138\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main.go</text><text x=\"105\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">internal/tally/</text><text x=\"105\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">plus the standard library,</text><text x=\"105\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">compiled from source</text><text x=\"105\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">for each target</text><rect x=\"225\" y=\"115\" width=\"130\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">go build</text><text x=\"290\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">GOOS  GOARCH</text><path d=\"M190 145 H221\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-arrow)\"></path><rect x=\"400\" y=\"20\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"412\" y=\"33\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">linux/amd64</text><text x=\"412\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ELF, statically linked, 4,031,935 bytes</text><path d=\"M355 145 C378 145 374 40 396 40\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-arrow)\"></path><rect x=\"400\" y=\"100\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"412\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">linux/arm64</text><text x=\"412\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ELF, statically linked, 3,831,466 bytes</text><path d=\"M355 145 C378 145 374 120 396 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-arrow)\"></path><rect x=\"400\" y=\"152\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"412\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">darwin/arm64</text><text x=\"412\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Mach-O, names libSystem, 3,909,762 bytes</text><path d=\"M355 145 C378 145 374 172 396 172\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-arrow)\"></path><rect x=\"400\" y=\"204\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"412\" y=\"217\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">windows/amd64</text><text x=\"412\" y=\"233\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">PE32+, named hits.exe, 4,217,344 bytes</text><path d=\"M355 145 C378 145 374 224 396 224\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cx-arrow)\"></path><text x=\"668\" y=\"33\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the build machine itself</text><path d=\"M370 86 H690\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\" fill=\"none\"></path><text x=\"690\" y=\"74\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">CGO_ENABLED is 1 above the line, 0 below it</text></svg>", "caption": "One source tree and one compiler, four binaries. Everything below the dashed line is a cross build, and the go command turns cgo off for it."}
```

## Why there is no cross toolchain to install

**The Go compiler, assembler and linker are Go programs, and so is the standard library**, apart
from small assembly files written for each processor, which ship in `/usr/local/go/src` for every
architecture at once. Nothing in `/usr/local/go/pkg` is a precompiled standard library: the go
command compiles the packages a build needs from source, for the target it was asked for, and keeps
the results in its build cache. A build for `arm64` therefore needs nothing an `amd64` build does
not, and the second one for the same target reuses the cache.

The other half is what the binary depends on when it runs. **On Linux a Go program makes its system
calls itself**, without the C library, which is why both ELF files say `statically linked`: they can
be copied to any Linux on that processor and started. macOS is different: Apple does not keep its
system calls stable and supports programs only through its system library, so the Mach-O file is
`DYLDLINK` and names `/usr/lib/libSystem.B.dylib`. That reference was written by Go's own linker. No
Apple tool and no macOS headers are on this machine, and none were needed, because the library is
only looked up when the program starts on a Mac.

The one part of a build that is not Go is cgo, the bridge to C, and section 04 is about what happens
to it when the target changes.
