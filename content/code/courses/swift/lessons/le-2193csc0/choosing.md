---
title: Which one to write
version: 1
---

Apple's documentation has an article on exactly this question, "Choosing Between Structures and
Classes", and its first recommendation is the one this course follows: **use a struct by default.**
The reasons are the ones the previous sections measured. A struct is copied, so code holding one
cannot be surprised by somebody else's change. A `let` struct cannot change at all. `==` comes from
the compiler. And copy-on-write makes the copies cheap.

The article gives three reasons to reach for a class instead:

- **when identity matters**: the value is one thing in the world, and every part of the program
  must see the same one. An open file, a network connection, the single store the screens of an app
  read from;
- **when Objective-C has to call it**, because Apple's older frameworks only understand classes.
  That is `ios-apps`' concern and not this course's;
- **when inheritance is the right model**, which lesson 10 argues is rarer than it looks.

## One of each, together

The study planner keeps sessions as values and the place they are kept as a single shared instance.
Two "screens", each a struct, hold the same store:

```swift
// Choosing.swift
struct StudySession {
    var course: String
    var minutes: Int
}
final class PlannerStore {
    var sessions: [StudySession] = []
}
struct WeekScreen {
    let store: PlannerStore
    func show() { print("week:", store.sessions.map(\.minutes)) }
}
struct AddScreen {
    let store: PlannerStore
    func add(_ session: StudySession) { store.sessions.append(session) }
}
let store = PlannerStore()
let week = WeekScreen(store: store)
let add = AddScreen(store: store)
add.add(StudySession(course: "Swift", minutes: 45))
add.add(StudySession(course: "Swift", minutes: 30))
week.show()
var edited = store.sessions[0]
edited.minutes = 90
week.show()
```

```
ana@vm:~/sw/l05$ swift Choosing.swift
week: [45, 30]
week: [45, 30]
```

**Both screens saw the two sessions, because there is one store.** `AddScreen.add` is not `mutating`
and is called on a `let`, and it still changed the store: the screen holds a reference, and the
reference did not change. Taking `store.sessions[0]` out into `edited` copied the session, so setting
its minutes to 90 changed nothing the screens can see. To change a stored session, the code has to
write the value back, which is the moment a reader can see. `\.minutes` is a key path, a way of
naming a property, and `map(\.minutes)` reads it from each session.

This shape, **values for the data and one reference for the place it lives**, is the one SwiftUI
apps are built on, and `ios-apps` builds it. Lesson 15 changes `PlannerStore` from a class to an
actor, because a shared instance that two tasks change at once has a problem this lesson has not
met yet.
