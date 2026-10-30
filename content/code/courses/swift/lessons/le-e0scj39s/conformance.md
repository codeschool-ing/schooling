---
title: The compiler checks the promise
version: 1
---

Declaring `: Describable` is a claim, and the compiler checks it before anything runs. **A type
that misses one requirement does not conform, and nothing is built.** Here a session forgets its
summary:

```swift
// Missing.swift
protocol Describable {
    var title: String { get }
    func summary() -> String
}

struct StudySession: Describable {
    var title: String
    var minutes: Int
}
```

```
ana@vm:~/sw/l08$ swiftc Missing.swift -o missing
Missing.swift:7:8: error: type 'StudySession' does not conform to protocol 'Describable'
 2 | protocol Describable {
 3 |     var title: String { get }
 4 |     func summary() -> String
   |          `- note: protocol requires function 'summary()' with type '() -> String'
 5 | }
 6 | 
 7 | struct StudySession: Describable {
   |        |- error: type 'StudySession' does not conform to protocol 'Describable'
   |        `- note: add stubs for conformance
 8 |     var title: String
 9 |     var minutes: Int
```

The message comes in two halves, as lesson 1 showed most do. The `error` is on the struct: it does
not conform. The `note` above it points into the protocol at the requirement nobody met, with its
full type, `() -> String`. The second note, "add stubs for conformance", is what an editor offers
as a one-click fix that writes empty methods for you; the compiler on its own only names them.

A requirement is matched by **name and type together**. A `func summary() -> Substring`, or a
`summary(short: Bool)`, is a different method and leaves the requirement unmet, with the same
error.

## Structs, classes and enums all conform

Any named type can conform, and each meets a requirement in its own way:

```swift
// Conform.swift
protocol Describable {
    var title: String { get }
    func summary() -> String
}

enum Level: Describable {
    case beginner, advanced
    var title: String { self == .beginner ? "Beginner" : "Advanced" }
    func summary() -> String { "level: \(title)" }
}

final class Planner: Describable {
    let owner: String
    init(owner: String) { self.owner = owner }
    var title: String { "\(owner)'s planner" }
    func summary() -> String { title }
}

let things: [any Describable] = [Level.beginner, Planner(owner: "Ana")]
for thing in things { print(thing.summary()) }
```

```
ana@vm:~/sw/l08$ swift Conform.swift
level: Beginner
Ana's planner
```

`Level` meets `var title: String { get }` with a **computed** property, which is allowed because
the requirement asked only to read it. `Planner` is a class, and a class meets the requirements in
the same way; the `final` says nothing inherits from it, which lesson 10 comes back to. The array
holds an enum case and a class instance side by side, because what they share is the protocol.

## Several protocols at once

A type may conform to as many protocols as it needs, separated by commas:
`struct StudySession: Describable, Equatable`. A class that also has a superclass names it first.
There is no limit, and in practice most types in an app conform to three or four, most of them
from the standard library, which section 06 is about.
