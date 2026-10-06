---
title: The problem Go was built for
version: 1
---

"Go is fast" is the first thing most people hear about the language, and they take it to mean that
Go programs run fast. They do, but **the speed the designers set out to fix first was the speed of
the build.** Go started at Google in 2007 as an answer to three problems of writing server software
there: builds that took too long, dependencies nobody could keep track of, and machines that had
outgrown the languages that programmed them.

## Builds measured in minutes

Rob Pike, one of the three designers, gave the numbers in a talk at the SPLASH conference in 2012,
*Go at Google: Language Design in the Service of Software Engineering*. In 2007 Google's build
engineers instrumented the compilation of one large C++ program. Its source was about two thousand
files, 4.2 megabytes laid end to end. By the time every `#include` had been expanded, the compiler
was reading more than 8 gigabytes: **2,000 bytes of input for every byte of source.** That program
took 45 minutes to build, on a build system that spread the work across many machines.

Those numbers are the talk's, and nothing in this lab builds Google's C++. What the lab can measure
is the other side of the comparison. The go command is itself a Go program, and its source comes
with every Go installation, so it can be built from nothing:

```
ana@vm:~/why$ nproc
4
ana@vm:~/why$ go list -deps cmd/go | wc -l
334
ana@vm:~/why$ go clean -cache
ana@vm:~/why$ time go build -o /dev/null cmd/go

real	0m21.332s
user	0m57.345s
sys	0m11.351s
ana@vm:~/why$ time go build -o /dev/null cmd/go

real	0m0.837s
user	0m1.115s
sys	0m0.250s
```

`go list -deps` names every package the go command is made of, the standard library's included, and
there are 334. `go clean -cache` empties the build cache of lesson 4, so the first build compiles
all of them, on a virtual machine with four processors, in 21.332 seconds. `-o /dev/null` throws the
result away, because only the time matters here. The second build found every package already in
the cache and took 0.837 seconds.

**`user` is larger than `real` because the go command compiles independent packages at the same
time**, one per processor. That is the second problem showing up in the first one's answer.

## Dependencies the compiler can see

In C and C++ a file says what it needs with `#include`, which pastes the text of another file into
it. An include nobody needs any more is still pasted and still compiled, on every build, and
nothing tells you it could go. Multiply that by two thousand files and you get the 8 gigabytes.

Go made the dependency part of the language. An `import` names a package rather than a file to
paste, and **an import the file does not use is a compile error**: lesson 4 showed the compiler
refusing `"os" imported and not used`. So the list of what a Go program depends on is exact by
construction. The 2012 talk adds the other half. When the compiler meets `import "B"`, it opens one
file, the compiled form of `B`, which already carries everything about `B`'s own dependencies that
a user of `B` needs. Nothing is read twice.

## Many processors, and the network

The third problem was the machines. A Google server in 2007 had several processors and spent its
day answering other machines, and the talk says it plainly: C, C++ and, to some extent, Java were
designed before multicore machines, networking and web applications were normal.

Go put concurrency into the language rather than into a library. **The keyword `go` starts a
function running alongside the rest of the program**, and `chan` declares a channel that two of
them talk through. Both are among the 25 keywords section 03 counts. Using them well is the subject
of the `go-concurrency` course; this course teaches the language they are built on.

## Who, and when

According to the Go project's own FAQ, Robert Griesemer, Rob Pike and Ken Thompson started
sketching the goals of a new language on a whiteboard on 21 September 2007. It was a part-time
project at first and a full-time one by mid-2008, and **Go became a public, open-source project on
10 November 2009.** Lesson 2 takes the story from there to the go1.27.1 this lab runs.
