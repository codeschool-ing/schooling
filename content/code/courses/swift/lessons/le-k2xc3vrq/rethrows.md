---
title: rethrows, and defer for the way out
version: 1
---

Some functions throw only because a closure they were given throws. `map` is one: mapping with a
closure that cannot fail cannot fail, and mapping with one that can, can. **`rethrows` says exactly
that**: this function throws only if its closure argument does, and only the errors the closure
throws.

```swift
// Rethrows.swift
enum PlannerError: Error {
    case notANumber(String)
}

func parseMinutes(_ text: String) throws -> Int {
    guard let minutes = Int(text) else { throw PlannerError.notANumber(text) }
    return minutes
}

func total(_ texts: [String], reading read: (String) throws -> Int) rethrows -> Int {
    print("total: start")
    defer { print("total: leaving") }
    var sum = 0
    for text in texts {
        sum += try read(text)
    }
    return sum
}

print(total(["45", "30"], reading: { Int($0) ?? 0 }))
do {
    print(try total(["45", "forty", "30"], reading: parseMinutes))
} catch {
    print("caught:", error)
}
```

```
ana@vm:~/sw/l12$ swift Rethrows.swift
total: start
total: leaving
75
total: start
total: leaving
caught: notANumber("forty")
```

The first call passes `{ Int($0) ?? 0 }`, a closure that cannot throw, and is written **without
`try`**, because `rethrows` lets the compiler see that nothing can fail. It printed 75. The second
passes `parseMinutes`, a throwing function, as the closure, and needs `try` and a `catch`: `"forty"`
threw on the way through the loop, and the caught error is the one `parseMinutes` threw, unchanged.
`map`, `filter`, `compactMap` and `sorted(by:)` are all declared `rethrows`, which is why
section 03's `compactMap { try? … }` needed no outer `try` and a `map` with a plain `try` inside
would.

## defer runs on every way out

`total` prints `total: leaving` in both runs, once after a normal `return` and once after the error.
**A `defer` block runs when the scope it is in ends, however it ends**: a `return`, the end of the
block, or an error thrown through it. It is where cleanup goes, closing a file or stopping a timer,
so that an error halfway through cannot skip it.

Two details are worth knowing. A `defer` runs at the end of its **scope**, not of the function, so a
`defer` inside a loop body runs once per pass. And several `defer` blocks in one scope run in
**reverse order**, the last one written first, so the things opened last are closed first.
