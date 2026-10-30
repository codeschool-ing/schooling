---
title: Protocols with a type left open
version: 1
---

Lesson 8's protocols named every type in full: `title` is a `String`, `summary()` returns a
`String`. Some protocols cannot. The planner keeps sessions in a store, keeps courses in another, and
a test in lesson 18 will want a store of plain numbers; the operations are the same and the type of
the thing stored differs. **An associated type is a type parameter that belongs to a protocol**, and
each conforming type decides what it is.

```swift
// Store.swift
protocol Store {
    associatedtype Item
    var all: [Item] { get }
    mutating func add(_ item: Item)
}

struct StudySession {
    var course: String
    var minutes: Int
}

struct SessionStore: Store {
    var all: [StudySession] = []
    mutating func add(_ item: StudySession) { all.append(item) }
}

struct CourseList: Store {
    typealias Item = String
    var all: [String] = []
    mutating func add(_ item: String) {
        if !all.contains(item) { all.append(item) }
    }
}

func fill<S: Store>(_ store: inout S, with items: [S.Item]) {
    for item in items { store.add(item) }
}

var sessions = SessionStore()
fill(&sessions, with: [StudySession(course: "Swift", minutes: 45),
                       StudySession(course: "Swift", minutes: 30)])
var courses = CourseList()
fill(&courses, with: ["Swift", "Kotlin", "Swift"])
print(sessions.all.count, courses.all)
```

```
ana@vm:~/sw/l09$ swift Store.swift
2 ["Swift", "Kotlin"]
```

`associatedtype Item` leaves the stored type open. `SessionStore` never says what its `Item` is: the
compiler reads it from `add(_ item: StudySession)` and `[StudySession]`, which must agree.
`CourseList` writes `typealias Item = String` to say it outright, which is allowed and only needed
when nothing else settles it. Each conforming type has **one** `Item`, fixed when it conforms; a
`CourseList` stores strings and nothing else.

## Using one from a generic function

`fill` is generic over any store, `S: Store`, and its second parameter is `[S.Item]`: an array of
whatever that store holds. Read the signature as a sentence, "for any store, an array of its items",
and the call sites check themselves. Passing courses to `sessions` would be refused, because
`SessionStore.Item` is `StudySession`. Lesson 3's `inout` and `&` let `fill` change the store it was
given; the `if !all.contains(item)` is why `CourseList` kept `"Swift"` once.

## Where the standard library does this

`Collection` is a protocol with associated types, `Element` among them, and `Sequence`,
`IteratorProtocol` and `Identifiable` are others. That is why section 03's `C.Element == Int` could
be written: a constraint can name an associated type and pin it down. **Associated types are what
let one protocol describe "a collection of something" without saying of what**, and nearly every
generic algorithm in the standard library is written against one.

The price is that such a protocol is awkward to use as a plain type, since a value of "some store"
says nothing about what goes into it. Section 07 shows exactly where that bites.
