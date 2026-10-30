---
title: Optional chaining, and ?? for a default
version: 1
---

`if let` and `guard let` take the optional apart. Two operators work on it without taking it apart:
**`?.` asks the value something if it is there, and `??` supplies a value for when it is not.**

## ?. passes nil along

`note?.count` asks `note` for its `count` if `note` holds a string, and gives `nil` without asking if
it does not. So the result is itself optional: `note?.count` is an `Int?`, never an `Int`.

```swift
// Chain.swift
let notes: [String?] = ["read chapter 3", nil, ""]
for note in notes {
    let length = note?.count
    print(String(describing: length))
}
let shouted = notes[1]?.uppercased().count
print(String(describing: shouted))
```

```
ana@vm:~/sw/l02$ swift Chain.swift
Optional(14)
nil
Optional(0)
nil
```

`String(describing:)` prints an optional as it is, without lesson 1's warning, which is why it is
here. The three lines are the three outcomes worth telling apart: **a length, `nil` for the missing
note, and `0` for the empty one.**

`notes[1]?.uppercased().count` reads as one question: the length of the capitalised second note, if
there is one. The `?` after `notes[1]` is the only one needed. If that note is `nil`, nothing to its
right runs at all, and the whole expression is `nil`. If it is not, `uppercased()` returns a plain
`String` and `.count` is asked of that. **One `?` guards everything after it in the chain.**

## ?? ends the question

`??` is the **nil-coalescing operator**. On its left, an optional; on its right, a value of the plain
type. It gives the left side's value if there is one and the right side otherwise, so its result is
never optional:

```swift
// Coalesce.swift
let entries = ["45", "forty", "30"]
var total = 0
for typed in entries {
    total += Int(typed) ?? 0
}
print("total \(total)")
let note: String? = nil
print("note: " + (note ?? "none"))
let length = note?.count ?? 0
print(length, type(of: length))
```

```
ana@vm:~/sw/l02$ swift Coalesce.swift
total 75
note: none
0 Int
```

`Int(typed) ?? 0` is an `Int`, so `+=` accepts it, and the word `"forty"` counts as zero. Compare that
with section 03's loop: shorter, and it no longer says which entries were skipped. **`??` is the right
answer when the default really means the same as the value**, and the wrong one when the student
needs to know that something was missing.

The last two lines put both operators together, as you will see them in most Swift code:
`note?.count ?? 0` is "the length of the note, or zero", and `type(of:)` confirms it is a plain `Int`.

## A default that costs something

The right side of `??` runs only when it is needed. Swift evaluates it lazily, so a default that is
expensive to make, such as reading a file, is not made when the left side has a value. It is a small
fact, and it means you never have to write an `if` just to avoid computing a default.
