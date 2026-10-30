---
title: Sections, swipe actions and deleting a row
version: 1
---

**A list groups rows into sections, and gives each row actions the person reaches by swiping.**
Both are `List` features, which is one of the reasons to use `List` rather than a stack. Nothing in
this section was run; it is written from Apple's documentation for `Section`, `onDelete(perform:)`
and `swipeActions(edge:allowsFullSwipe:content:)`.

The course screen groups a course's sessions into those still to do and those done:

```swift
// in CourseDetailView's body
let shown = model.plan.sessions(of: course.id)
List {
    Section("To do") {
        ForEach(shown.filter { !$0.done }) { session in
            SessionRow(session: session)
                .swipeActions(edge: .leading) {
                    Button("Done") { try? model.markDone(session.id) }
                        .tint(.green)
                }
        }
    }
    Section("Done") {
        ForEach(shown.filter(\.done)) { session in
            SessionRow(session: session)
        }
    }
}
```

`swipeActions` adds buttons revealed by a swipe from the edge named; a leading swipe is the one
Mail uses to mark as read. **`try?` throws the error away**, and here that is defensible for one
reason: the id came from the row the person just swiped, which exists, so `unknownSession` cannot
happen. A screen where it could would show the error, and lesson 12 is about showing one.

The standard way to delete is `onDelete`, applied to a `ForEach` inside a `List`. It gives the swipe
to delete, and the *Edit* button's red circles when an `EditButton` is on screen. What it hands you
is the important part:

```swift
ForEach(shown) { session in SessionRow(session: session) }
    .onDelete { offsets in
        model.plan.delete(at: offsets, in: shown)
    }
```

**`offsets` is an `IndexSet` of positions in the collection that `ForEach` showed**, not in
`model.plan.sessions`. On the course screen those are different arrays: the screen shows one
course's sessions, and the plan holds all of them. Section 06 writes `delete(at:in:)` to translate
the one into the other by id, and tests what happens if you skip the translation.
