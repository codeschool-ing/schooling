---
title: Identifiable, and what an id is for
version: 1
---

**SwiftUI keeps a row's state, its animation and its place on screen by the row's identity, and in a
`ForEach` the identity is the element's id.** When the collection changes, SwiftUI compares the ids
before and after: an id that is new is a row inserted, an id that is gone is a row removed, an id in
a different place is a row moved. Everything else about the row is just content to redraw.

`Identifiable` is a one-requirement protocol from the Swift standard library, not from SwiftUI, so it
is checked on Linux like anything else:

```swift
public protocol Identifiable<ID> {
    associatedtype ID: Hashable
    var id: ID { get }
}
```

Lesson 1 made `Course` and `StudySession` conform by giving each a `let id: String`. **Three
properties make an id fit for this job**, and the planner's ids have all three:

- **stable**: the same element has the same id for as long as it exists. `let`, not `var`, says so.
- **unique** within the collection: Apple's article on scrollable stacks says each element a
  `ForEach` iterates over *must be uniquely identifiable*, because two rows with one id are one row
  as far as SwiftUI is concerned, and which of them keeps the state is nothing to rely on.
- **owned by the data, not by the screen**: the id came with the session, from the person who
  created it or, from lesson 12, from the server.

For a collection whose elements are not `Identifiable`, `ForEach` takes the id as a key path:

```swift
ForEach(model.plan.courses, id: \.title) { course in Text(course.title) }
```

That compiles, and it is a bug waiting for two courses with the same title, or for a rename, which
lesson 1 section 05 called the reason ids exist. **`id: \.self` on an array of strings is the same
bet**, and it loses the moment the list holds two equal strings.

The common worst choice is not on that list at all: the position. Section 04 shows what it does.
