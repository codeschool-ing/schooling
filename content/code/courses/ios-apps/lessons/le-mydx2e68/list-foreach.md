---
title: List and ForEach, and what each is for
version: 1
---

**`List` draws a scrolling column of rows in the platform's own style; `ForEach` makes views from a
collection.** They are often written together and they are different things. `List` is a container
with opinions: separators, insets, swipe actions, selection, an edit mode. `ForEach` has no
appearance at all: it turns each element of a collection into a view, inside whatever container
it sits in, a `List`, a `VStack` or a `Form`.

Nothing in this section was run for the course; it is written from Apple's documentation for
`List` and `ForEach`, read on 30 October 2026. The planner's course list is the simplest case:

```swift
// in CourseListView's body
List(model.plan.courses) { course in
    NavigationLink(course.title) {
        CourseDetailView(course: course)
    }
}
```

`List(_:rowContent:)` is a shorthand for a `List` wrapping one `ForEach`. The long form is what you
write when the list holds more than one kind of row:

```swift
List {
    ForEach(model.plan.courses) { course in
        NavigationLink(course.title) { CourseDetailView(course: course) }
    }
    NavigationLink("This week") { WeekView() }
}
```

**`ForEach` is not a loop.** A `for` loop runs its body once per element and is done. `ForEach` is
a view: it describes, for SwiftUI, a row per element, and SwiftUI decides when to build each row and
when to build it again. That is why it needs to know, for every element, **which row it is** — the
question sections 03 and 04 are about, and the one whose answer decides whether a list animates,
keeps its state and stays fast.

Both initialisers above take `model.plan.courses` and nothing else because `Course` conforms to
`Identifiable`, the protocol that answers that question. Lesson 1 declared it, with this lesson in
mind.
