---
title: An optional is an enum
version: 1
---

Lesson 2 treated `Int?` as its own kind of type, with its own syntax: `if let`, `??`, `!`. **Under
the syntax, `Int?` is `Optional<Int>`, an enum from the standard library with two cases**: `.none`,
which is what `nil` means, and `.some(Int)`, which carries the value. Everything lesson 2 showed is
sugar for patterns over that enum, and the plain enum is still there to use:

```swift
// Optional.swift
func parse(_ typed: String) -> Optional<Int> {
    Int(typed)
}
for typed in ["45", "forty"] {
    let minutes = parse(typed)
    switch minutes {
    case .some(let value):
        print("\(typed): some(\(value))")
    case .none:
        print("\(typed): none")
    }
    switch minutes {
    case let value? where value > 30:
        print("  a long session")
    case let value?:
        print("  \(value) minutes")
    case nil:
        print("  nothing typed that is a number")
    }
}
let spelled: Optional<Int> = .some(30)
let sugared: Int? = 30
print(spelled == sugared)
```

```
ana@vm:~/sw/l07$ swift Optional.swift
45: some(45)
  a long session
forty: none
  nothing typed that is a number
true
```

The first switch names the two cases outright. The second uses the forms you will meet in real code:
**`let value?` is a pattern meaning `.some(let value)`**, and `nil` in a pattern means `.none`. Both
switches are exhaustive with two kinds of case, because the enum has exactly two.

`Optional<Int>` and `Int?` are the same type spelled two ways, and `.some(30)` and `30` the same
value; the last line compares them and prints `true`. Writing `30` where an `Int?` is expected works
because the compiler wraps it in `.some` for you, the one conversion Swift does make without being
asked.

## Why this matters

It explains every rule lesson 2 had to state. A function that takes an `Int` cannot take an `Int?`,
because they are different types: one is a number and the other is an enum that may hold one. `!` is
"assume `.some` and crash on `.none`". `??` is a switch with a default for `.none`. **There is no
special null in Swift**, only one more enum, and every tool this lesson gave you for enums works on
it.
