---
title: Sizes, alignment and the padding between fields
version: 1
---

The common picture of a struct is a row of fields laid end to end, so that its size is the sum of
theirs. **The compiler often leaves gaps between fields, and `unsafe` has three functions that show
where they are.** `unsafe.Sizeof` answers how many bytes a value takes, `unsafe.Alignof` which
addresses it may start at, and `unsafe.Offsetof` where inside its struct a field begins. They read
no memory and write none. **Each call is a constant the compiler works out while it builds the
program**, which makes them the one corner of the package that cannot corrupt anything. They live in
`unsafe` because the answers depend on the machine the program is compiled for, as section 05 shows.

This lesson works in `~/unsafe`, a module called `example.com/hits` holding copies of two files from
lesson 1: the `tally` package and `genlog`. Put `internal/tally/tally.go` and `tools/genlog/main.go`
there as lesson 1 prints them, and run `go mod init example.com/hits` in the directory. The first
program measures `tally.Entry` and two structs that hold the same five fields in different orders.
Save it as `layout/main.go`:

```schooling-example
{
  "language": "go",
  "file": "layout/main.go",
  "parts": [
    {
      "code": "// Command layout prints where the compiler puts the fields of three structs,\n// and what a million of two of them cost on the heap.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"runtime\"\n\t\"unsafe\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "A program of its own in the module that holds a copy of lesson 1's `tally`. **Importing `unsafe` is the whole ceremony**: no flag, no build tag, no warning from the compiler."
    },
    {
      "code": "// Loose is what a request did, in the order somebody thought of it.\ntype Loose struct {\n\tCached bool\n\tBytes  int64\n\tTLS    bool\n\tStatus int32\n\tRetry  bool\n}\n",
      "note": "Five fields that add up to 15 bytes: three `bool`s of one byte, an `int32` of four and an `int64` of eight. The order is the order a person would list them in."
    },
    {
      "code": "// Tight holds the same five fields, largest first.\ntype Tight struct {\n\tBytes  int64\n\tStatus int32\n\tCached bool\n\tTLS    bool\n\tRetry  bool\n}\n",
      "note": "**The same fields, sorted from the largest alignment to the smallest.** Nothing else changes: a program using `Tight` instead of `Loose` reads and writes the same names."
    },
    {
      "code": "func row(name string, off, size uintptr) {\n\tfmt.Printf(\"  %-9s offset %2d  size %2d\\n\", name, off, size)\n}\n",
      "note": "All three functions return a `uintptr`, the integer type big enough to hold an address. Here it is only a count of bytes."
    },
    {
      "code": "func main() {\n\tvar e tally.Entry\n\tfmt.Printf(\"tally.Entry  size %d  align %d\\n\", unsafe.Sizeof(e), unsafe.Alignof(e))\n\trow(\"Time\", unsafe.Offsetof(e.Time), unsafe.Sizeof(e.Time))\n\trow(\"Method\", unsafe.Offsetof(e.Method), unsafe.Sizeof(e.Method))\n\trow(\"Path\", unsafe.Offsetof(e.Path), unsafe.Sizeof(e.Path))\n\trow(\"Status\", unsafe.Offsetof(e.Status), unsafe.Sizeof(e.Status))\n\trow(\"Duration\", unsafe.Offsetof(e.Duration), unsafe.Sizeof(e.Duration))\n",
      "note": "`unsafe.Offsetof` takes a field selector, `e.Time`, and answers how many bytes from the start of the struct that field begins."
    },
    {
      "code": "\tvar l Loose\n\tfmt.Printf(\"Loose        size %d  align %d\\n\", unsafe.Sizeof(l), unsafe.Alignof(l))\n\trow(\"Cached\", unsafe.Offsetof(l.Cached), unsafe.Sizeof(l.Cached))\n\trow(\"Bytes\", unsafe.Offsetof(l.Bytes), unsafe.Sizeof(l.Bytes))\n\trow(\"TLS\", unsafe.Offsetof(l.TLS), unsafe.Sizeof(l.TLS))\n\trow(\"Status\", unsafe.Offsetof(l.Status), unsafe.Sizeof(l.Status))\n\trow(\"Retry\", unsafe.Offsetof(l.Retry), unsafe.Sizeof(l.Retry))\n\n\tvar t Tight\n\tfmt.Printf(\"Tight        size %d  align %d\\n\", unsafe.Sizeof(t), unsafe.Alignof(t))\n\trow(\"Bytes\", unsafe.Offsetof(t.Bytes), unsafe.Sizeof(t.Bytes))\n\trow(\"Status\", unsafe.Offsetof(t.Status), unsafe.Sizeof(t.Status))\n\trow(\"Cached\", unsafe.Offsetof(t.Cached), unsafe.Sizeof(t.Cached))\n\trow(\"TLS\", unsafe.Offsetof(t.TLS), unsafe.Sizeof(t.TLS))\n\trow(\"Retry\", unsafe.Offsetof(t.Retry), unsafe.Sizeof(t.Retry))\n"
    },
    {
      "code": "\tconst n = 1_000_000\n\tlb := grown(func() { looseSink = make([]Loose, n) })\n\ttb := grown(func() { tightSink = make([]Tight, n) })\n\tfmt.Printf(\"%d Loose  %d bytes\\n\", n, lb)\n\tfmt.Printf(\"%d Tight  %d bytes\\n\", n, tb)\n}\n",
      "note": "The same question asked of the heap: a slice of a million of each, and how many bytes the allocator handed out to make it."
    },
    {
      "code": "// Package variables keep both slices alive until main returns.\nvar (\n\tlooseSink []Loose\n\ttightSink []Tight\n)\n\n// grown reports how many bytes the heap handed out while f ran.\nfunc grown(f func()) uint64 {\n\tvar before, after runtime.MemStats\n\truntime.ReadMemStats(&before)\n\tf()\n\truntime.ReadMemStats(&after)\n\treturn after.TotalAlloc - before.TotalAlloc\n}",
      "note": "`runtime.ReadMemStats` before and after: `TotalAlloc` only ever grows, so the difference is what `f` allocated, whatever the collector did meanwhile. Lesson 19 is about the heap and the collector these numbers come from."
    }
  ]
}
```

And run:

```
ana@vm:~/unsafe$ go run ./layout
tally.Entry  size 72  align 8
  Time      offset  0  size 24
  Method    offset 24  size 16
  Path      offset 40  size 16
  Status    offset 56  size  8
  Duration  offset 64  size  8
Loose        size 32  align 8
  Cached    offset  0  size  1
  Bytes     offset  8  size  8
  TLS       offset 16  size  1
  Status    offset 20  size  4
  Retry     offset 24  size  1
Tight        size 16  align 8
  Bytes     offset  0  size  8
  Status    offset  8  size  4
  Cached    offset 12  size  1
  TLS       offset 13  size  1
  Retry     offset 14  size  1
1000000 Loose  32010416 bytes
1000000 Tight  16007168 bytes
```

## Where the padding comes from

`tally.Entry` is 72 bytes and its fields add up to 72: a `time.Time` of 24, two strings of 16 (a
pointer and a length each), an `int` and a `time.Duration` of 8. Every field starts where the last
one ended. **That is luck rather than a rule**, and `Loose` shows the rule.

**A field whose alignment is k starts at an offset that is a multiple of k.** On this machine an
`int64` has alignment 8, an `int32` 4 and a `bool` 1, so after the one byte of `Cached` the compiler
skips seven bytes to put `Bytes` at offset 8. `TLS` takes offset 16, three bytes are skipped so that
`Status` sits at 20, and `Retry` lands at 24. Fifteen bytes of fields now take up 25 bytes. **The
size of a struct is then rounded up to a multiple of its own alignment**, which is the largest
alignment among its fields, 8, so `Loose` ends at 32: the seven bytes after `Retry` belong to it
too. They are there so that in a slice of `Loose` values the next element's `Bytes` is also at a
multiple of 8.

`Tight` puts the largest first. `Bytes` at 0, `Status` at 8, and the three `bool`s at 12, 13 and 14,
which need no alignment at all. Fifteen bytes of fields round up to 16. **Same fields, same names,
half the memory**, and the gaps are where the compiler put them:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two structs drawn as rows of eight bytes. Loose takes four rows, 32 bytes: Cached at byte 0 and seven bytes of padding, Bytes filling bytes 8 to 15, TLS at 16 and three bytes of padding, Status at 20 to 23, Retry at 24 and seven bytes of padding to the end. Tight takes two rows, 16 bytes: Bytes at 0 to 7, Status at 8 to 11, Cached, TLS and Retry at 12, 13 and 14, and one byte of padding.\"><text x=\"44.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Loose</text><text x=\"44.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">32 bytes, 17 of them padding</text><text x=\"62.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"98.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"134.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"170.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"206.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"242.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"278.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"314.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"36.0\" y=\"88.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"36.0\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"36.0\" y=\"152.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><text x=\"36.0\" y=\"184.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">24</text><rect x=\"45.5\" y=\"73.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"62.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">Cached</text><rect x=\"45.5\" y=\"105.5\" width=\"285.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"188.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bytes</text><rect x=\"45.5\" y=\"137.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"62.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">TLS</text><rect x=\"189.5\" y=\"137.5\" width=\"141.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Status</text><rect x=\"45.5\" y=\"169.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"62.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">Retry</text><rect x=\"81.5\" y=\"73.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"117.5\" y=\"73.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"153.5\" y=\"73.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"189.5\" y=\"73.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"225.5\" y=\"73.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"261.5\" y=\"73.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"297.5\" y=\"73.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"81.5\" y=\"137.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"117.5\" y=\"137.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"153.5\" y=\"137.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"81.5\" y=\"169.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"117.5\" y=\"169.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"153.5\" y=\"169.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"189.5\" y=\"169.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"225.5\" y=\"169.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"261.5\" y=\"169.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"297.5\" y=\"169.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"404.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Tight</text><text x=\"404.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">16 bytes, 1 of them padding</text><text x=\"422.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"458.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"494.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"530.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"566.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"602.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"638.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"674.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"396.0\" y=\"88.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"396.0\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><rect x=\"405.5\" y=\"73.5\" width=\"285.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"548.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bytes</text><rect x=\"405.5\" y=\"105.5\" width=\"141.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"476.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Status</text><rect x=\"549.5\" y=\"105.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"566.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">Cached</text><rect x=\"585.5\" y=\"105.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"602.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">TLS</text><rect x=\"621.5\" y=\"105.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"638.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">Retry</text><rect x=\"657.5\" y=\"105.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"405.5\" y=\"161.5\" width=\"33.0\" height=\"23.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a field</text><rect x=\"405.5\" y=\"195.5\" width=\"33.0\" height=\"23.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"450.0\" y=\"207.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">padding the compiler added</text></svg>", "caption": "The offsets the layout program printed, drawn eight bytes to a row. The same five fields take 32 bytes in the order Loose declares them and 16 in Tight's, where nothing larger follows a smaller field."}
```

Half of 32 bytes is not worth a thought for one value. It is worth one for a million: the last two
lines of the run are the heap growing by **32,010,416 bytes** for a million `Loose` and
**16,007,168** for a million `Tight`. Each is within a tenth of a percent of 32 and 16 million
bytes, and the last digits change from run to run. The ratio does not.

## A tool that does the arithmetic

Nobody should compute offsets by hand for every struct in a program. The `fieldalignment` analyzer
in `golang.org/x/tools` does it for every struct in a package and says which ones would be smaller
in another order. It is not part of `go vet`, so it is installed on its own, pinned like every tool
in this course:

```
ana@vm:~/unsafe$ go install golang.org/x/tools/go/analysis/passes/fieldalignment/cmd/fieldalignment@v0.52.0
ana@vm:~/unsafe$ fieldalignment ./...; echo $?
/home/ana/unsafe/internal/tally/tally.go:47:14: Summary has 24 leading bytes of pointer data but optimal value is 16
/home/ana/unsafe/layout/main.go:14:12: Loose has size 32 but the optimal size is 16 leading to a waste of 16 bytes (50%)
3
```

**It found `Loose`, with the same 32 and 16 the program printed**, and it found nothing wrong with
`Tight` or with `tally.Entry`. The exit status 3 is how analyzers built on
`golang.org/x/tools/go/analysis` say they reported something, so a CI step that runs it fails on any
finding.

The first line is the other diagnostic it makes, and it is about `tally.Summary`, a struct from
lesson 1. **"Pointer bytes" is how far into a value the garbage collector has to look for
pointers.** `Summary` starts with `Lines`, an `int`, and its two maps are pointers, so the collector
scans 24 bytes of every `Summary`; with the maps first it could stop at 16. The analyzer's own
documentation is frank about what that is worth: these diagnostics "very rarely indicate a
significant problem", which is why it is not in `go vet` or `gopls` by default. **`hits` makes one
`Summary` per run, so eight bytes of scanning saved once is nothing.** A million-element slice of
`Loose` is the case it is for.

The documentation names one more reason not to obey it blindly. The most compact order can put two
fields that two goroutines update on their own into the same cache line of the processor, and each
write then slows the other down. That is called false sharing, and it is the case where the padding
was the point. **Reorder a struct when a measurement says its size matters**, and leave it in the
order that reads well everywhere else.
