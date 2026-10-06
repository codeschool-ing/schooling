---
title: From a whiteboard to go1.27.1
version: 1
---

The version number misleads in two directions at once. Read `go1.27.1` as a version 1 that never
reached 2, and the language looks stalled; read every release as a new language, and seventeen
years of Go look like a pile of rewrites. Neither is right. **Go 1 is one language, kept compatible
since 2012, and the number after it counts the releases of that language.** Your toolchain says
which one it is:

```
ana@vm:~/history$ go version
go version go1.27.1 linux/amd64
ana@vm:~/history$ cat /usr/local/go/VERSION
go1.27.1
time 2026-08-28T16:20:06Z
ana@vm:~/history$ go list -f '{{context.ReleaseTags}}' runtime
[go1.1 go1.2 go1.3 go1.4 go1.5 go1.6 go1.7 go1.8 go1.9 go1.10 go1.11 go1.12 go1.13 go1.14 go1.15 go1.16 go1.17 go1.18 go1.19 go1.20 go1.21 go1.22 go1.23 go1.24 go1.25 go1.26 go1.27]
```

`/usr/local/go/VERSION` is a two-line file in every installation: the release and the moment it was
built. The list after it is the go command's own record of the releases it is compatible with,
from `go1.1` to `go1.27`. Each is a **build tag**: a file that starts with `//go:build go1.21` is
compiled only by Go 1.21 and later, which is how a package can use something new and still build
on an older release. Twenty-seven releases since Go 1, and `.1` at the end says this is the first
fix release of 1.27, which section 04 explains.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"A timeline from 2007 to 2026. 2007: the language is sketched on a whiteboard. 2009: public, open source. 2012: go1, the compatibility promise. 2015: go1.5, compiler written in Go. 2018: go1.11, modules. 2022: go1.18, generics. 2023: go1.21.0, toolchain switching. 2024: go1.22.0, a variable per loop turn. 2026: go1.27.1, this lab. Years separate go1.5, go1.11 and go1.18, and the last three marks fall within three years.\"><path d=\"M30 150 L700 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M44.0 147 L44.0 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M77.6 147 L77.6 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M111.2 147 L111.2 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M144.8 147 L144.8 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M178.4 147 L178.4 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M212.0 147 L212.0 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M245.60000000000002 147 L245.60000000000002 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M279.20000000000005 147 L279.20000000000005 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M312.8 147 L312.8 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M346.40000000000003 147 L346.40000000000003 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M380.0 147 L380.0 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M413.6 147 L413.6 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M447.20000000000005 147 L447.20000000000005 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M480.8 147 L480.8 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M514.4000000000001 147 L514.4000000000001 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M548.0 147 L548.0 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M581.6 147 L581.6 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M615.2 147 L615.2 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M648.8000000000001 147 L648.8000000000001 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M682.4 147 L682.4 153\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M44.0 144 L44.0 76\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"36.0\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sketched on a whiteboard</text><rect x=\"40.0\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"44.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2007</text><path d=\"M111.2 156 L111.2 178\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"111.2\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">public, open source</text><rect x=\"107.2\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"111.2\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2009</text><path d=\"M212.0 144 L212.0 126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"212.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">go1</text><text x=\"212.0\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the compatibility promise</text><rect x=\"208.0\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"212.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2012</text><path d=\"M312.8 156 L312.8 178\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"312.8\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">compiler written in Go</text><text x=\"312.8\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">go1.5</text><rect x=\"308.8\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"312.8\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2015</text><path d=\"M413.6 144 L413.6 126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"413.6\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">go1.11</text><text x=\"413.6\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">modules</text><rect x=\"409.6\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"413.6\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2018</text><path d=\"M548.0 156 L548.0 178\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"548.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">generics</text><text x=\"548.0\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">go1.18</text><rect x=\"544.0\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"548.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2022</text><path d=\"M581.6 144 L581.6 76\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"581.6\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">go1.21.0</text><text x=\"581.6\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">toolchain switching</text><rect x=\"577.6\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"581.6\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2023</text><path d=\"M615.2 156 L615.2 222\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"615.2\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a variable per loop turn</text><text x=\"615.2\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">go1.22.0</text><rect x=\"611.2\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.2\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2024</text><path d=\"M682.4 144 L682.4 126\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"682.4\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">go1.27.1</text><text x=\"682.4\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">this lab</text><rect x=\"678.4\" y=\"146\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"682.4\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2026</text></svg>", "caption": "The releases this lesson names, on a scale of years. Everything after go1 is a release of the same language, kept compatible with it."}
```

## The releases that changed the most

Lesson 1 told the start: a whiteboard in September 2007, and a public, open-source project on
10 November 2009. Every date below comes from the Go project's release history.

**Go 1, 28 March 2012**, is the line the rest of the timeline is drawn from. Before it, Go came out as
weekly snapshots, and Go 1 itself shipped with a tool, `go fix`, to update programs written against
them. Go 1 froze the specification and promised that a program written for it would keep compiling,
which is section 03.

**Go 1.5, 19 August 2015**, is when Go started compiling itself. The first compilers were written in
C; from 1.5 on, the compiler and the runtime are Go, with a little assembler. The note that explains
how Go is now built still says so:

```
ana@vm:~/history$ sed -n 3,4p /usr/local/go/src/cmd/dist/README
As of Go 1.5, dist and other parts of the compiler toolchain are written
in Go, making bootstrapping a little more involved than in the past.
```

That is why lesson 1 could build the go command from source with nothing but Go installed.

**Go 1.11, 24 August 2018**, added modules: a `go.mod` file naming the code and its dependencies.
Before it, all Go code lived in one directory tree called `GOPATH`, which lesson 3 shows. Lesson 4
wrote a `go.mod`, and lesson 38 is about modules properly.

**Go 1.18, 15 March 2022**, added generics, functions and types that work for several types at
once. Lessons 30 and 31 teach them as the ordinary part of the language they now are; section 03
shows an older `go.mod` refusing them.

**Go 1.21.0, 8 August 2023**, taught the go command to download and run another release of Go when a
module asks for one, which section 04 does. It also changed how releases are named. The first
release of a version used to be plain `go1.20`; from 1.21 it is `go1.21.0`, so every release name
now has three numbers.

**Go 1.22.0, 6 February 2024**, changed what a `for` loop's variable is: one per turn of the loop
instead of one for the whole loop. It is the clearest case of the promise of section 03 at work,
because it changed the meaning of code that already compiled, and section 03 runs it both ways.

Then the release this lab runs, go1.27.1, built on 28 August 2026 according to its `VERSION` file.
**Twenty-seven releases added to the language and its library, and each was held to the Go 1
promise.** The one that changed what old code means, 1.22, did it only for modules that ask for it,
and how a module asks is the next section.
