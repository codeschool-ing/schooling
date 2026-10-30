---
title: if let, for a value that may be there
version: 1
---

The first answer to "and if it is nil?" is the one you will write most: **check, and inside the
check, use a plain value.** `if let minutes = Int(typed)` does both at once. If `Int(typed)` has a
number, `minutes` is that number, an `Int` and not an `Int?`, for the body of the `if`. If it is
`nil`, the body is skipped and `else` runs instead.

A student typed three durations into the planner, and one of them is a word:

```swift
// IfLet.swift
let entries = ["45", "forty", "30"]
var total = 0
for typed in entries {
    if let minutes = Int(typed) {
        total += minutes
        print("added \(minutes)")
    } else {
        print("skipped \(typed)")
    }
}
print("total \(total)")
```

```
ana@vm:~/sw/l02$ swift IfLet.swift
added 45
skipped forty
added 30
total 75
```

`for typed in entries` runs its body once for each string in the array, with `typed` standing for
each in turn; lesson 4 is about arrays. Inside the `if`, `total += minutes` compiles because
`minutes` is an `Int`. Write `total += Int(typed)` instead and the compiler refuses, for the reason
section 02 gave: an `Int?` has no `+=` with an `Int`.

**The unwrapped name exists only inside the braces.** After the closing brace, `minutes` is gone,
and only `typed` and `total` remain. That is the property that makes `if let` safe: there is no line
anywhere in the program where `minutes` could be `nil`.

## The short form

Often the optional already has a good name, and inventing a second one adds nothing. **`if let note`
unwraps `note` into a plain value with the same name**, for the length of the braces:

```swift
// Shorthand.swift
let note: String? = "read chapter 3"
if let note {
    print("note has \(note.count) characters")
}
let goal: Int? = nil
if let goal {
    print("goal is \(goal)")
} else {
    print("no goal set")
}
```

```
ana@vm:~/sw/l02$ swift Shorthand.swift
note has 14 characters
no goal set
```

Inside the first `if`, `note` is a `String`, and `note.count` compiles. Outside it, the same name is
the `String?` it always was. The short form arrived in Swift 5.7, so older code you read spells it
out as `if let note = note`, which means exactly the same.

## Several at once

A session needs a start and an end that are both numbers, and the end after the start. Commas join
the conditions, and **every one of them must succeed** for the body to run:

```swift
// Several.swift
func duration(start: String, end: String) {
    if let from = Int(start), let to = Int(end), to > from {
        print("\(to - from) minutes")
    } else {
        print("cannot read \(start)-\(end)")
    }
}
duration(start: "600", end: "645")
duration(start: "600", end: "noon")
duration(start: "645", end: "600")
```

```
ana@vm:~/sw/l02$ swift Several.swift
45 minutes
cannot read 600-noon
cannot read 645-600
```

The conditions are read left to right, and each may use the names unwrapped before it: `to > from`
compares two `Int`s because both `let`s have already succeeded. The first one that fails sends the
whole `if` to `else`. The function takes `start:` and `end:` labels at the call, which lesson 3
explains.
