---
title: A protocol says what, never how
version: 1
---

A planner shows courses and study sessions in the same list, and each needs a line of text for it.
The two types have nothing else in common: a course has lessons, a session has minutes. **A
protocol names what a set of types promises to provide, and says nothing about how each provides
it.** It is a list of requirements, and a type that meets them is said to **conform**.

```swift
// Describable.swift
protocol Describable {
    var title: String { get }
    func summary() -> String
}

struct Course: Describable {
    var title: String
    var lessons: Int
    func summary() -> String { "\(title): \(lessons) lessons" }
}

struct StudySession: Describable {
    var title: String
    var minutes: Int
    func summary() -> String { "\(title), \(minutes) min" }
}

func printAll(_ items: [any Describable]) {
    for item in items {
        print("-", item.summary())
    }
}

printAll([
    Course(title: "Swift", lessons: 20),
    StudySession(title: "Optionals", minutes: 45),
    StudySession(title: "Closures", minutes: 30),
])
```

```
ana@vm:~/sw/l08$ swift Describable.swift
- Swift: 20 lessons
- Optionals, 45 min
- Closures, 30 min
```

Read the protocol from the top. `var title: String { get }` requires a property called `title`, of
type `String`, that can be **read**. It does not say the property is stored: a type may compute it.
`{ get set }` would require one that can also be written. `func summary() -> String` requires a
method with exactly that name and type, and the protocol has no body for it, only the signature.

`Course: Describable` after the type's name declares the conformance, in the same place a class
would name its superclass. The compiler then checks the promise, which section 03 shows failing.

## A protocol is also a type

`printAll` takes `[any Describable]`: an array whose elements may be of any type at all, as long as
each conforms. Inside the loop the code knows only what the protocol promises, so `item.summary()`
compiles and `item.lessons` would not, because not every describable thing has lessons. The word
`any` marks a value whose concrete type is only known while the program runs; lesson 9 says what
that costs and when to write `some` instead.

## What a protocol is not

A protocol has **no storage** of its own and cannot be created: `Describable()` means nothing,
because there is nothing to create. That is the first difference from a superclass, which is a
type with fields and a body. Structs and enums cannot inherit at all, so for them a protocol is
the only way to be treated as one of a family, and that is why the Swift standard library is built
out of protocols rather than class hierarchies. Lesson 10 turns that observation into a way of
designing.
