---
title: One language on the page, four in the track
version: 1
---

**Every program in this course is Python, and that is a decision made on your behalf, so here is
the reasoning.** The track that brings you here, `software-architecture`, continues `backend`, and
`backend` lets you choose a server language: JavaScript with Node.js, Python, Java or Go. So you
arrive holding one of four, and a course about design has to show designs in code somebody can
run.

There were three ways to do it. Four versions of every example would be four times the reading and
would bury the design under the syntax. Pseudocode would run nowhere, and a pattern you cannot run
is a pattern you have to take on trust. One language, chosen for how little of it gets in the way,
was the option left. Python wins that on two counts: a class with two methods is about ten lines,
and the interpreter is already installed on most Linux machines and one download away on the rest.

**What you learn here is not Python.** A strategy, an aggregate, a projection or an actor is the
same idea in all four languages. Where the four genuinely differ, the lesson says so in a table like
the one below, and this section is the dictionary for everything else.

## The Python you need, and what it is called in yours

You need very little Python to read this course: classes, functions, lists and dictionaries, and
the few constructs in this table. If you came through `backend` on another language, read the row
in your column the first time a construct appears.

| in this course (Python) | JavaScript / TypeScript | Java | Go |
|---|---|---|---|
| `class Loan:` with `__init__` | `class Loan { constructor() {} }` | `class Loan { Loan() {} }` | `type Loan struct {}` plus a `NewLoan` function |
| `self` | `this` | `this` | the receiver, `func (l *Loan)` |
| `_due`, a leading underscore | `#due`, a private field | `private` | a lower-case name |
| `class Channel(Protocol)` | `interface Channel` (TypeScript) | `interface Channel` | `type Channel interface` |
| `@dataclass(frozen=True)` | `Object.freeze` on a plain object | `record` | a struct passed by value |
| a function passed as an argument | the same | a lambda or a method reference | a `func` value |
| `raise ValueError(...)` | `throw new Error(...)` | `throw new IllegalArgumentException(...)` | `return ..., errors.New(...)` |
| `threading`, `queue`, `asyncio` | `async`/`await`, worker threads | threads, `ExecutorService`, virtual threads | goroutines and channels |

The last row matters most in lessons 16 to 18, where the four languages differ the most. Those
lessons name what your language offers beside each Python program.

## How to work through it

Each lesson builds small programs in a directory of its own, under `~/patterns` on your machine. The
programs are shown whole, so you can copy each one, run it and see the output the lesson shows.
Typing them out yourself is slower and teaches more, and it is a good habit with any example you
want to keep.

If you want to go further, rewrite a lesson's program in your own language once it runs in Python.
Nothing checks that work, but the place where the translation fights you is usually the place where
your language has a better answer than the pattern, and lesson 6 has a section about exactly that.
