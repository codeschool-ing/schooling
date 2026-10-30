---
title: Result, an error you can keep
version: 1
---

A thrown error has to be dealt with on the spot: caught, passed on or converted. Sometimes the failure
needs to be **kept** instead, stored in an array, returned from a callback or handed to a screen that
draws it later. **`Result<Success, Failure>` is a value that holds either a success or an error**, an
enum with two cases, `.success` and `.failure`, each carrying its value.

```swift
// ResultDemo.swift
enum PlannerError: Error {
    case notANumber(String)
}

func minutes(from text: String) -> Result<Int, PlannerError> {
    guard let minutes = Int(text) else { return .failure(.notANumber(text)) }
    return .success(minutes)
}

let results = ["45", "forty"].map { minutes(from: $0) }
for result in results {
    switch result {
    case .success(let minutes): print("success:", minutes)
    case .failure(let error): print("failure:", error)
    }
}

let hours = results[0].map { Double($0) / 60 }
print(hours)
print(try results[0].get())

func parseMinutes(_ text: String) throws -> Int {
    guard let minutes = Int(text) else { throw PlannerError.notANumber(text) }
    return minutes
}
let caught = Result { try parseMinutes("forty") }
print(caught, type(of: caught))
```

```
ana@vm:~/sw/l12$ swift ResultDemo.swift
success: 45
failure: notANumber("forty")
success(0.75)
45
failure(ResultDemo.PlannerError.notANumber("forty")) Result<Int, Error>
```

`minutes(from:)` does not throw at all. It returns a `Result<Int, PlannerError>`, and **the error is
part of the return value**, so the caller can map two strings to two results and keep both. A
`switch` over each result, with one `case` per outcome, reads them back.

Three operations come with it:

- **`map`** transforms the success and leaves a failure untouched: `results[0].map { Double($0) / 60 }`
  turned `success(45)` into `success(0.75)`, hours instead of minutes, without unwrapping it;
- **`get()`** turns a `Result` back into a throwing call: the value, or the error thrown, which is
  why it needs `try`;
- **`Result { … }`**, the initialiser called `Result(catching:)`, goes the other way and turns a
  throwing call into a `Result`. The last line shows its catch: the type is `Result<Int, Error>`, with
  `Error` and not `PlannerError`, because `parseMinutes` is declared with plain `throws` and the
  compiler knows no more than that.

## Result or throws

Before Swift had `async`/`await`, a function that finished later called a closure with a `Result`,
and most older iOS code still does. Lesson 14's `async` functions throw instead, and **inside new
code, `throws` is the default**: the compiler makes callers deal with it, which a `Result` left in a
variable does not. `Result` stays the right tool where a failure is data, kept for later, as in an
array of outcomes or a value a screen draws.
