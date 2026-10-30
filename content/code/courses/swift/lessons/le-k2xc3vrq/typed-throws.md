---
title: Typed throws
version: 1
---

`throws` on its own means "may throw any error". That is why section 02 needed a final bare `catch`,
and why the caller of a throwing function cannot know, from its declaration, which failures to plan
for. **Since Swift 6, a function can name the one type it throws**, in brackets after the word:
`throws(PlannerError)`. The compiler then holds both sides to it.

```swift
// Typed.swift
enum PlannerError: Error {
    case notANumber(String)
    case tooLong(minutes: Int)
}

func parseMinutes(_ text: String) throws(PlannerError) -> Int {
    guard let minutes = Int(text) else { throw .notANumber(text) }
    guard minutes <= 240 else { throw .tooLong(minutes: minutes) }
    return minutes
}

do {
    print(try parseMinutes("300"))
} catch {
    switch error {
    case .notANumber(let text): print("not a number: \(text)")
    case .tooLong(let minutes): print("\(minutes) minutes is longer than a study block")
    }
}
```

```
ana@vm:~/sw/l12$ swift Typed.swift
300 minutes is longer than a study block
```

Three things changed from section 02, and each is the compiler using the type it was given:

- **`throw .notANumber(text)`** needs no type name, because the only type it can be is
  `PlannerError`, as in a `switch` over an enum;
- in the `catch`, **`error` is a `PlannerError`**, not an `any Error`, so a `switch` can list its
  cases;
- **the `switch` has no `default` and the `do` no second `catch`.** Both cases are covered and the
  compiler knows there is nothing else, so section 02's refusal does not happen.

The promise holds in the other direction too. A function that declares `PlannerError` and throws
something else does not compile:

```swift
// TypedWrong.swift
enum PlannerError: Error { case notANumber(String) }
struct NetworkDown: Error {}

func parseMinutes(_ text: String) throws(PlannerError) -> Int {
    guard let minutes = Int(text) else { throw NetworkDown() }
    return minutes
}
```

```
ana@vm:~/sw/l12$ swiftc TypedWrong.swift -o typedwrong
TypedWrong.swift:6:48: error: thrown expression type 'NetworkDown' cannot be converted to error type 'PlannerError'
4 | 
5 | func parseMinutes(_ text: String) throws(PlannerError) -> Int {
6 |     guard let minutes = Int(text) else { throw NetworkDown() }
  |                                                `- error: thrown expression type 'NetworkDown' cannot be converted to error type 'PlannerError'
7 |     return minutes
8 | }
```

## When to name the type

Typed throws make a contract with every caller, and a contract is hard to change: add a case to
`PlannerError`, or start throwing a network error from the same function, and every `switch` that
listed the cases stops compiling. **Name the type when the set of failures is closed and belongs to
the function**, as parsing a number of minutes is. Leave plain `throws` where failures come from
underneath and may grow, such as reading a file or calling a server, which can fail in ways no enum
of yours will ever list. SE-0413, the Swift proposal that introduced typed throws, says the same:
untyped `throws` remains the better default for most code.
