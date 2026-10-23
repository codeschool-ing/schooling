---
title: One language, properly
version: 1
---

**You chose JavaScript for the server, and the advice that goes with the choice is to stay with it
until you know it well.** That sounds like a rule for beginners. It is the opposite: it is how
people who already program decide what to learn next, and the reasons are worth knowing, because
you will be tempted to break it.

## The wrong picture

The common picture is that a programming language is mostly its syntax. Learn the keywords of a
second one, the thinking goes, and you know two languages. So a few weeks into Node, somebody reads
that Go is faster or that Python has the better jobs, starts a Go tutorial, and three months later
has finished four tutorials and built nothing that runs anywhere but on their laptop.

**Syntax is the smallest part of a language.** What a working server needs from its author is
everything around the syntax:

| what you have to know | what it looks like in this course |
|---|---|
| the runtime, and how it runs your code | lesson 2: the event loop, the thread pool, why one slow loop stops every request |
| how code is split and found | lesson 3: two module systems and the rules Node uses to pick one |
| the ecosystem and its tools | lesson 4: npm, the lockfile, what a dependency brings with it |
| the standard library | lessons 5 and 8: the HTTP server and the file system with nothing installed |
| the libraries everybody uses | lessons 6 and 7: Express |
| how the program meets the machine | lessons 9 and 10: configuration, processes, workers and cluster mode |

None of the right-hand column is syntax, and none of it moves to Go when you do. Go has its own
runtime, its own way of finding a package and its own server library, and each of them takes as
long to learn as Node's did.

## What depth buys

**A problem in production is almost never a problem with syntax.** It is a request that hangs, a
process that runs out of memory at three in the morning, a dependency that changed under you, a
setting that is right on your laptop and wrong on the server. Each of those is found by somebody who
knows what the runtime does when nothing is written down, and that knowledge comes from time spent
in one language, not from a tour of several.

The second reason is that **the ideas transfer only once you have them**. HTTP, status codes,
middleware, configuration from the environment, streams, a process that shuts down cleanly: lesson
11 shows that Python, Go, Java, PHP and C# all have each of these. A person who has built them once,
properly, in Node, reads them in another language as the same idea with new names. A person who met
each of them for an afternoon in four languages has to learn all of them again in the fifth.

And the third is plain arithmetic. This track spends 140 hours on JavaScript and Node together,
and the courses after it are written for somebody who can build a server in one language. Spending
those hours on two languages means arriving at `sql-databases` and `apis` with half of each.

## When a second language is right

None of this says never learn another one. It says **not yet**. A second language is worth learning
when the first one is no longer the thing you are struggling with: when you can build, debug and
deploy a small service in it without looking up how to read a request body. Lesson 11 is about what
changes between languages and what does not, and it is the last lesson on purpose. By then the
comparison means something, because you have one side of it.
