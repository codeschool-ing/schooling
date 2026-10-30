---
title: Functions, and what they return
version: 1
---

Lesson 2 already called functions with names such as `minutes(from:)`. A **function** is a named piece
of code with parameters going in and, if it says so, one value coming out. Its type is written in its
first line, and the compiler holds every call and every `return` to it.

The planner needs three small calculations about a week of study:

```schooling-example
{"language": "swift", "file": "Functions.swift", "parts": [{"code": "// Functions.swift\nfunc weekTotal(_ sessions: [Int]) -> Int {\n    var total = 0\n    for minutes in sessions {\n        total += minutes\n    }\n    return total\n}", "note": "`func`, a name, the parameters in brackets, and `-> Int` for the type of the result. `return` hands the result back. The `_` before `sessions` is section 03's subject; for now, it means the call writes no label."}, {"code": "func hours(_ minutes: Int) -> Double {\n    Double(minutes) / 60\n}", "note": "A body that is a single expression needs no `return`: its value is the result. This is the shape most short Swift functions have."}, {"code": "func progress(_ minutes: Int, goal: Int) -> (done: Int, left: Int) {\n    (minutes, max(goal - minutes, 0))\n}", "note": "Two results at once, as a **tuple** with named parts. `max` keeps the minutes left from going below zero once the goal is passed."}, {"code": "let total = weekTotal([45, 30, 60])\nprint(total, hours(total))\nlet week = progress(total, goal: 300)\nprint(week.done, week.left)", "note": "The calls. A tuple's parts are read by name, `week.done` and `week.left`, so nobody has to remember which number came first."}]}
```

```
ana@vm:~/sw/l03$ swift Functions.swift
135 2.25
135 165
```

The total is 135 minutes, or 2.25 hours, and against a goal of 300 that leaves 165. Three things in the
example are worth taking away. **The result type is part of the promise**: `weekTotal` says `-> Int`,
so every path through it has to end in an `Int`. **A one-expression body returns its value**, which
is why `hours` has no `return`. And **a tuple is how one function gives back two things** without a
type invented for the purpose; lesson 5 shows when it is time to invent one.

## The compiler checks both ends

Leave out the `return`, and call the function without using what it returns:

```swift
// Unused.swift
func weekTotal(_ sessions: [Int]) -> Int {
    var total = 0
    for minutes in sessions {
        total += minutes
    }
}
weekTotal([45])
```

```
ana@vm:~/sw/l03$ swiftc Unused.swift -o unused
Unused.swift:8:1: warning: result of call to 'weekTotal' is unused [#NoUsage]
6 |     }
7 | }
8 | weekTotal([45])
  | `- warning: result of call to 'weekTotal' is unused [#NoUsage]
9 | 

Unused.swift:7:1: error: missing return in global function expected to return 'Int'
5 |         total += minutes
6 |     }
7 | }
  | `- error: missing return in global function expected to return 'Int'
8 | weekTotal([45])
9 | 

[#NoUsage]: <https://docs.swift.org/compiler/documentation/diagnostics/no-usage>
```

**An error and a warning, about the two ends of one function.** The error is the promise broken: the
body can reach its closing brace without producing the `Int` the first line declared, so no program is
written. The warning is about the caller: `weekTotal([45])` computes a number and throws it away, which
is almost always a mistake, because a function that returns something was usually called to get it.
When discarding really is intended, `_ = weekTotal([45])` says so and silences the warning.

## A function with nothing to return

`print` returns nothing, and neither does a function that only reports. Leave out the `->` part and
the function's result type is `Void`, an empty tuple, `()`. You will see `Void` written out in function
types in section 06. Such a function may still `return` early, with nothing after the word, which is
how lesson 2's `guard` left a function that had no value to give.
