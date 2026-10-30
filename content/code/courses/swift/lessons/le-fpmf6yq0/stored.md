---
title: Stored properties
version: 1
---

Lesson 5's types held their data in **stored properties**: a name and a type inside the type's
braces, with storage reserved for it in every instance. This lesson is about the four other things a
property can be, and it starts by pinning down the plain one, because two details of it decide what
the others are for.

```swift
// Stored.swift
struct StudySession {
    let course: String
    var minutes: Int
    var done = false
}
var monday = StudySession(course: "Swift", minutes: 45)
monday.done = true
monday.minutes += 15
print(monday)
let tuesday = StudySession(course: "Swift", minutes: 30, done: true)
print(tuesday.done)
```

```
ana@vm:~/sw/l06$ swift Stored.swift
StudySession(course: "Swift", minutes: 60, done: true)
true
```

`monday` is a variable, and its `done` and `minutes` changed. Its course cannot:

```swift
// Course.swift
struct StudySession {
    let course: String
    var minutes: Int
}
var monday = StudySession(course: "Swift", minutes: 45)
monday.course = "Kotlin"
```

```
ana@vm:~/sw/l06$ swiftc Course.swift -o course
Course.swift:7:8: error: cannot assign to property: 'course' is a 'let' constant
1 | // Course.swift
2 | struct StudySession {
3 |     let course: String
  |     `- note: change 'let' to 'var' to make it mutable
4 |     var minutes: Int
5 | }
6 | var monday = StudySession(course: "Swift", minutes: 45)
7 | monday.course = "Kotlin"
  |        `- error: cannot assign to property: 'course' is a 'let' constant
8 | 
```

**A `let` property is set once, when the instance is made, and never again**, even in a `var`
instance. That is the right shape for a session: the minutes are corrected after the fact, and a
session that moved to another course is a different session.

**A default value makes the argument optional.** `var done = false` gives the memberwise initialiser
a `done:` argument with that default, so `monday` was made without it and `tuesday` with it. A
`let` with a default gets no argument at all, since nothing could ever give it another value.

## Where the storage lives

A stored property of a struct is part of the value: copy the struct and you copy the property, as
lesson 5 measured. A stored property of a class lives in the one instance on the heap. Nothing else
about declaring one differs, and **every kind of property in this lesson exists on both**, with one
exception named in section 05.
