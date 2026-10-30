---
title: Initialisers
version: 1
---

An initialiser has one job: **every stored property has a value before the instance is used.** The
compiler checks that rule on every path through every `init`, and the rest of this section is what
follows from it. A class that forgets one property:

```swift
// Unset.swift
final class Planner {
    let owner: String
    var goal: Int
    init(owner: String) {
        self.owner = owner
    }
}
```

```
ana@vm:~/sw/l06$ swiftc Unset.swift -o unset
Unset.swift:7:5: error: return from initializer without initializing all stored properties
2 | final class Planner {
3 |     let owner: String
4 |     var goal: Int
  |         `- note: 'self.goal' not initialized
5 |     init(owner: String) {
6 |         self.owner = owner
7 |     }
  |     `- error: return from initializer without initializing all stored properties
8 | }
9 | 
```

The note points at `goal`, which no line of the initialiser set. A default value on the property, or
a line in the `init`, would satisfy it. A `let` property may be set in the initialiser and nowhere
else: the `init` is the one place a constant is not yet fixed.

## Keeping the memberwise initialiser

Section 06 found that writing an `init` inside a struct removes the one the compiler writes. **An
initialiser written in an extension keeps it.** An extension adds to a type from outside its main
braces, and lesson 8 is about them; here it is only a place to put a second way in:

```swift
// Extra.swift
struct StudySession {
    var course: String
    var minutes: Int
}
extension StudySession {
    init(hours: Double, course: String) {
        self.init(course: course, minutes: Int(hours * 60))
    }
}
let a = StudySession(course: "Swift", minutes: 45)
let b = StudySession(hours: 1.5, course: "Swift")
print(a.minutes, b.minutes)
```

```
ana@vm:~/sw/l06$ swift Extra.swift
45 90
```

`self.init(course:minutes:)` hands the work to the memberwise initialiser, so the rule is checked in
one place. An initialiser that calls another of the same type is called **delegating**.

## An initialiser that can fail

A session built from text a student typed may have no valid minutes. **`init?` is an initialiser that
may return `nil`**, and what it makes is an optional, exactly as `Int("45")` gave an `Int?` in lesson
1:

```swift
// Failable.swift
struct StudySession {
    var course: String
    var minutes: Int
}
extension StudySession {
    init?(course: String, typed: String) {
        guard let minutes = Int(typed), minutes > 0, minutes <= 600 else { return nil }
        self.init(course: course, minutes: minutes)
    }
}
let good = StudySession(course: "Swift", typed: "45")
let bad = StudySession(course: "Swift", typed: "forty")
let silly = StudySession(course: "Swift", typed: "9000")
print(good?.minutes ?? -1, bad?.minutes ?? -1, silly?.minutes ?? -1)
```

```
ana@vm:~/sw/l06$ swift Failable.swift
45 -1 -1
```

`guard … else { return nil }` is lesson 2's early exit, and `return nil` is the failure. The check
that section 04's observer could not make at initialisation is made here, before the value exists.
**A failable initialiser is how a type refuses to exist in an invalid state**: code that receives a
`StudySession` knows its minutes are between 1 and 600, because no other way to make one is offered.
