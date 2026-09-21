---
title: An interpreter reads your file, one line at a time
version: 1
---

You write a file. A program called **the interpreter** reads it and does what it says. That is the
whole arrangement, and Python's name for the interpreter is `python3`.

Some languages do this differently. C and Go are **compiled**: a separate program turns your file
into machine instructions once, and what you ship is the result. Python is **interpreted**: there
is no separate result, and `python3` is reading your file every time it runs.

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
