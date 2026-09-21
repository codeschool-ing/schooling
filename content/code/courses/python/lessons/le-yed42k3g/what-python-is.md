---
title: An interpreter reads your file, one line at a time
version: 1
---

You write a file. A program called **the interpreter** reads it and does what it says. That is the
whole arrangement, and Python's name for the interpreter is `python3`.

Some languages do this differently. C and Go are **compiled**: a separate program turns your file
into machine instructions once, and what you ship is the result. Python is **interpreted**: there
is no separate result, and `python3` is reading your file every time it runs.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 215\" role=\"img\" aria-label=\"A compiled language turns your file into a machine program once, with a compiler in the middle, and what runs afterwards is that program. Python has no separate result: the interpreter reads your file every time the program runs.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"20\" y=\"20\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">compiled — C, Go</text> <rect x=\"20\" y=\"30\" width=\"152\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"96\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">your file</text> <rect x=\"196\" y=\"30\" width=\"152\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"272\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a compiler</text> <path d=\"M178 52 L190 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"372\" y=\"30\" width=\"152\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"448\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a machine program</text> <path d=\"M354 52 L366 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"548\" y=\"30\" width=\"152\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"624\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">it runs</text> <path d=\"M530 52 L542 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"20\" y=\"110\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">interpreted — Python</text> <rect x=\"20\" y=\"120\" width=\"186.667\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"113.333\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">your file</text> <rect x=\"266.667\" y=\"120\" width=\"186.667\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">python3 reads it</text> <path d=\"M212.667 142 L260.667 142\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"513.333\" y=\"120\" width=\"186.667\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"606.667\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">it runs</text> <path d=\"M459.333 142 L507.333 142\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">The middle box of the top row is the one Python does not have.</text> </svg>", "caption": "The compiled row happens once. The Python row happens on every run, which is the whole of what interpreted means."}
```

## What that buys

**You can run a half-finished program.** The interpreter reads to the point where it breaks and
tells you, which means you find out about line 4 without having to make line 40 correct first.
On a compiled language nothing runs until all of it compiles.

**And you can talk to it directly**, which is the next section.

## What it costs

**Speed.** A loop that adds up ten million numbers takes about a second in Python and about ten
milliseconds in C. That sounds fatal and is not, for a reason worth understanding now:

> The Python you will write for data work spends almost all of its time inside libraries that
> are not written in Python. `pandas` and `numpy` are C underneath. Your code is the thin layer
> that says what to do; the arithmetic happens somewhere fast.

Lesson 20 is where this gets precise. For now: Python is slow at arithmetic and it is almost
never the thing that makes your program slow.

**And the errors arrive late.** A misspelled name in a branch nobody took is a problem you meet in
production rather than at build time. That is the hole lessons 14 to 16 are about filling —
annotations and a checker that reads them, which is a compiler's early warning bolted back on by
choice.

## Where it actually runs

The same file runs on Linux, macOS and Windows, because the interpreter is what differs and the
file does not. That is a real promise and it has one famous edge — paths, which lesson 9 handles
with `pathlib` for exactly this reason.
