---
title: Deciding whether to write it
version: 1
---

**Start sequential. Make a stream parallel only when a measurement on real data says it is faster, and
the pipeline is free of shared state.** The default is right more often than not, and a parallel
stream that is merely no faster still costs something: the work moves to threads the rest of the
program needed.

## A checklist before `parallel()`

| question | parallel helps when | parallel hurts when |
|---|---|---|
| how much work per element? | real computation: parsing, maths, hashing | a field read, an addition |
| how many elements? | tens of thousands or more | dozens or hundreds |
| what is the source? | `ArrayList`, an array, `IntStream.range` | `LinkedList`, `Stream.iterate`, `Files.lines` |
| do the lambdas touch anything shared? | no: they read their argument and return | yes: a list, a counter, a field |
| does the result need source order? | no, or the terminal operation keeps it cheaply | `forEachOrdered`, `findFirst`, `limit` on a huge stream |
| does any lambda wait? | never | network calls, database queries, `sleep` |

## The pool is shared

The last row is about the **common pool** from section 02. Every parallel stream in the program, in
every library it uses, runs on the same few workers, three on this machine. A lambda that waits for a
network reply holds a worker for the whole wait, and while three such lambdas wait, **every other
parallel stream in the program stands still**. Parallel streams are for work that keeps a processor
busy. Work that waits, for files, sockets or databases, belongs to executors and virtual threads,
which lessons 16 and 17 build for exactly that.

The pool's size can be changed with the system property
`java.util.concurrent.ForkJoinPool.common.parallelism`, set when the JVM starts. That is a decision
for the whole program, not a tuning knob for one stream, and changing it to make one pipeline faster
is how other pipelines get slower.

## What you have after lessons 6 to 9

A pipeline you can read top to bottom, built from `filter`, `map`, `flatMap`, `sorted` and a terminal
operation; reductions that are correct because their combining function is associative; collectors
that answer questions about groups; and a measured reason, or none, to make it parallel. Lesson 10
takes the `Optional` that `findFirst`, `max` and `reduce` kept returning, and makes it the subject.
