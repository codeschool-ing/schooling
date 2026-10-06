---
title: A memory limit, and memory you did not mean to keep
version: 1
---

A garbage-collected language is often sold as one that cannot leak memory. **It cannot lose
memory, which is different: the collector frees what nothing can reach, and keeps everything that
something can.** A program that still points at bytes it will never read again holds them for as
long as the pointer lives. This section covers the two ways a program's memory surprises its
owner: a heap that grows to whatever `GOGC` allows, whatever the machine has, and a few bytes that
keep a great many alive.

## GOMEMLIMIT: a ceiling the runtime aims under

`GOGC` sets the next collection by a proportion, and a proportion knows nothing about the machine.
With 2 GB alive, `GOGC=100` lets the heap reach 4 GB before collecting, whether or not the
container it runs in has 4 GB to give. The second setting answers that:

```
ana@vm:~/memory-gc$ go doc runtime | grep -A 11 "The GOMEMLIMIT variable"
The GOMEMLIMIT variable sets a soft memory limit for the runtime. This memory
limit includes the Go heap and all other memory managed by the runtime, and
excludes external memory sources such as mappings of the binary itself, memory
managed in other languages, and memory held by the operating system on behalf
of the Go program. GOMEMLIMIT is a numeric value in bytes with an optional unit
suffix. The supported suffixes include B, KiB, MiB, GiB, and TiB. These suffixes
represent quantities of bytes as defined by the IEC 80000-13 standard. That is,
they are based on powers of two: KiB means 2^10 bytes, MiB means 2^20 bytes,
and so on. The default setting is math.MaxInt64, which effectively disables the
memory limit. runtime/debug.SetMemoryLimit allows changing this limit at run
time.
```

**The limit counts all the memory the runtime manages, not only the heap, and it is soft.** As the
total approaches it, the runtime collects more often, whatever `GOGC` says. The two settings work
together: `GOGC=off` with a limit means "do not collect at all until memory gets near this", which
suits a program alone in a container of known size. The `~/memory-gc` program of section 03, with
64 MiB to use:

```
ana@vm:~/memory-gc$ GOGC=off GOMEMLIMIT=64MiB ./gc
10 collections, 496 MB allocated, heap at most 63 MB
```

Ten collections instead of 61, and a heap that grew right up to the limit and stopped there. It
used memory that was available to save the time of 51 collections.

The other direction is the one to understand before using it. The program keeps 8 MB alive, and
no setting can make the collector free a reachable byte. Here is the same binary with a limit of 4
MiB, under what it needs, beside a run with no limit at all:

```
ana@vm:~/memory-gc$ time ./gc
61 collections, 496 MB allocated, heap at most 19 MB

real	0m0.420s
user	0m0.421s
sys	0m0.033s
ana@vm:~/memory-gc$ time GOMEMLIMIT=4MiB ./gc
2927 collections, 496 MB allocated, heap at most 19 MB

real	0m1.739s
user	0m1.612s
sys	0m1.439s
```

The program finished, which is what soft means: there is no error and no crash at the limit. It
ran 2,927 collections to stay as close as it could, and took four times as long. The runtime's
source, `mgclimit.go`, caps the collector at roughly half the processor time in that state, so the
program crawls instead of stopping. **A limit below what the program really keeps alive costs
time and saves nothing.** It belongs a margin above the live heap, and the live heap is the last of
the three numbers in a `gctrace` line's `#->#->#`.

`runtime/debug` has a function for each setting, `SetGCPercent` and `SetMemoryLimit`, for a
program that decides them itself; the environment variables are how an operator decides them from
outside.

## Sixteen bytes holding sixty-four megabytes

Lesson 9 section 03 showed that a substring shares the bytes of the string it was cut from, and
lesson 11 that a slice is a view of an array. Both are what make cutting cheap. They also mean a
small piece keeps the whole alive, because the collector sees one pointer into the array and keeps
the array, all of it. Nothing in the collector looks at how much of an array a slice can see.

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport (\n\t\"fmt\"\n\t\"runtime\"\n\t\"slices\"\n\t\"strings\"\n)\n"
    },
    {
      "code": "\n// heapMB collects, then reports what the heap still holds.\nfunc heapMB() uint64 {\n\truntime.GC()\n\tvar m runtime.MemStats\n\truntime.ReadMemStats(&m)\n\treturn m.HeapAlloc >> 20\n}\n",
      "note": "`runtime.GC` runs a whole collection before the measurement, so `HeapAlloc`, the bytes held by heap values, counts only what is still reachable."
    },
    {
      "code": "\n// load stands in for reading a 64 MB file into memory.\nfunc load() []byte {\n\treturn make([]byte, 64<<20)\n}\n\nvar header []byte\nvar name string\n",
      "note": "`64<<20` is 64 times 1,048,576. The two package variables are what the program keeps for later: a file's first bytes, and a name read from it."
    },
    {
      "code": "\nfunc main() {\n\tfmt.Printf(\"at start              %2d MB\\n\", heapMB())\n",
      "note": "Nearly nothing on the heap yet."
    },
    {
      "code": "\n\theader = load()[:16]\n\tfmt.Printf(\"16 bytes kept         %2d MB\\n\", heapMB())\n",
      "note": "**The slice can see 16 bytes, and the array behind it is 64 MB.** Nothing else points at the array, and the collector keeps it anyway, because `header` does."
    },
    {
      "code": "\theader = slices.Clone(header)\n\tfmt.Printf(\"after slices.Clone    %2d MB\\n\", heapMB())\n",
      "note": "`slices.Clone` copies the 16 bytes into a new, small array. Once `header` points there, the 64 MB array is unreachable and the next collection frees it."
    },
    {
      "code": "\n\tname = string(load())[:16]\n\tfmt.Printf(\"16-byte substring     %2d MB\\n\", heapMB())\n\tname = strings.Clone(name)\n\tfmt.Printf(\"after strings.Clone   %2d MB\\n\", heapMB())\n}\n",
      "note": "**The same thing happens with a string.** The 16-byte substring shares the bytes of a 64 MB string and keeps them alive, until `strings.Clone` gives it bytes of its own."
    }
  ],
  "output": "at start               0 MB\n16 bytes kept         64 MB\nafter slices.Clone     0 MB\n16-byte substring     64 MB\nafter strings.Clone    0 MB"
}
```

The program sits in `~/memory-keep`, and the numbers are the same on every run, because each one is
measured right after a full collection. The standard library documents the fix where you would
look for it:

```
ana@vm:~/memory-keep$ go doc strings.Clone
package strings // import "strings"

func Clone(s string) string
    Clone returns a fresh copy of s. It guarantees to make a copy of s into a
    new allocation, which can be important when retaining only a small substring
    of a much larger string. Using Clone can help such programs use less memory.
    Of course, since using Clone makes a copy, overuse of Clone can make
    programs use more memory. Clone should typically be used only rarely,
    and only when profiling indicates that it is needed. For strings of length
    zero the string "" will be returned and no allocation is made.

ana@vm:~/memory-keep$ go doc slices.Clone
package slices // import "slices"

func Clone[S ~[]E, E any](s S) S
    Clone returns a copy of the slice. The elements are copied using assignment,
    so this is a shallow clone. The result may have additional unused capacity.
    The result preserves the nilness of s.
```

The documentation's warning is the right one. Cloning everything doubles the copying for nothing;
cloning a short piece of a large value **that you are going to keep** is what saves the memory. A
request handler that reads a body, takes a header out of it and returns has nothing to fix, because
the whole body becomes unreachable when it returns. A cache that stores that header for a day does.
`slices.Clone` is a generic function, which is why its signature has square brackets; lesson 30 is
about those.
