---
title: A switch must cover every case
version: 1
---

`switch` in Swift looks like the statement of the same name in C or Java and behaves differently in
two ways that matter. **It must be exhaustive**: every possible value is handled, or it does not
compile. **And a case does not fall through** into the next one: when a case's body ends, the switch
ends. A version of section 03's function that forgot the exercises:

```swift
// Missing.swift
enum Activity {
    case reading(pages: Int)
    case video(minutes: Int)
    case exercises(done: Int, of: Int)
}
func minutes(for activity: Activity) -> Int {
    switch activity {
    case .reading(let pages):
        return pages * 3
    case .video(let minutes):
        return minutes
    }
}
```

```
ana@vm:~/sw/l07$ swiftc Missing.swift -o missing
Missing.swift:8:5: error: switch must be exhaustive
 6 | }
 7 | func minutes(for activity: Activity) -> Int {
 8 |     switch activity {
   |     |- error: switch must be exhaustive
   |     `- note: add missing case: '.exercises(done: let done, of: let of)'
 9 |     case .reading(let pages):
10 |         return pages * 3
```

**The note is the useful part**: it names the case that is missing, already written as a pattern you
could paste. This is the payoff of an enum over a string. Add a fourth activity next month, a
`.quiz`, and every `switch` over `Activity` in the program stops compiling until somebody decides
what a quiz means there. With strings, the new value would fall silently into whatever the last
branch did.

## default, and why to avoid it

`default:` matches anything not matched above it, and it makes any switch exhaustive. That is
exactly its danger with your own enum: **a `default` turns off the check the note above came from**.
The day `.quiz` is added, a switch with a `default` compiles happily and treats a quiz as whatever
`default` does. List the cases instead, and keep `default` for types whose values cannot be listed,
such as `Int` or `String`:

```swift
// Grades.swift
func label(for score: Int) -> String {
    switch score {
    case 90...100: return "excellent"
    case 70..<90: return "pass"
    case 0..<70: return "not yet"
    default: return "invalid"
    }
}
print(label(for: 95), label(for: 70), label(for: 69), label(for: 120))
```

```
ana@vm:~/sw/l07$ swift Grades.swift
excellent pass not yet invalid
```

`90...100` is a closed range, both ends included, and `70..<90` a half-open one that stops before
90. No case of an `Int` switch can list every integer, so the compiler insists on `default` here, and
it catches the impossible score.

## An enum somebody else owns

An enum from a framework may gain cases in a later version of the framework, which your compiled app
has never seen. For those, Swift offers `@unknown default:`, which handles the case nobody listed
and still **warns** at compile time when the enum you build against has a case your switch does not
name. You meet it in Apple's frameworks; for your own enums, listing every case is the whole
protection and costs nothing.
