---
title: Extensions add to a type you did not write
version: 1
---

An **extension** adds methods, computed properties and conformances to a type that already exists,
including one from the standard library. It is written apart from the type, often in another file,
and once it is compiled the new members look exactly like the original ones:

```swift
// Hours.swift
extension Int {
    var asHours: String {
        let h = self / 60, m = self % 60
        return m == 0 ? "\(h)h" : "\(h)h\(m)"
    }
}

let week = [45, 30, 60, 90]
let total = week.reduce(0, +)
print(total.asHours)
print(300.asHours, 45.asHours)
```

```
ana@vm:~/sw/l08$ swift Hours.swift
3h45
5h 0h45
```

`Int` belongs to the standard library, and the planner just gave it a property. Inside the
extension, `self` is the integer the property was asked of, so `300.asHours` reads like English and
needs no helper function with a name to remember. Lesson 3's `reduce(0, +)` adds the week up.

## What an extension cannot add

**An extension adds behaviour and never storage.** A stored property would change the size of
every `Int` already in memory, and the compiler refuses it:

```swift
// Stored.swift
extension Int {
    var label: String = ""
}
```

```
ana@vm:~/sw/l08$ swiftc Stored.swift -o stored
Stored.swift:3:9: error: extensions must not contain stored properties
1 | // Stored.swift
2 | extension Int {
3 |     var label: String = ""
  |         `- error: extensions must not contain stored properties
4 | }
5 | 
```

Computed properties, methods, initialisers, nested types and subscripts are all allowed, because
none of them needs a byte more in each value.

## Conforming in an extension

An extension can also add a **conformance**. That is the usual way to keep a type's own fields in
one block and each protocol it meets in a block of its own:

```swift
// Retro.swift
protocol Describable {
    var title: String { get }
    func summary() -> String
}

struct Course {
    var title: String
    var lessons: Int
}

extension Course: Describable {
    func summary() -> String { "\(title): \(lessons) lessons" }
}

let swift: any Describable = Course(title: "Swift", lessons: 20)
print(swift.summary())
```

```
ana@vm:~/sw/l08$ swift Retro.swift
Swift: 20 lessons
```

`Course` was written with no protocol at all. The extension declares the conformance and supplies
the one missing method; `title` was already there, and the compiler counts it. **This works for
types you do not own as well**, which is how a library's type can be made to fit your protocol
without changing the library.
