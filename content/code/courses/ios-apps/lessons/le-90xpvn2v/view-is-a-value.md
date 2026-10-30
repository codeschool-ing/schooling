---
title: A view is a description, not a thing on the screen
version: 1
---

**A SwiftUI view is a small value that describes part of the screen, and it is not the part of the
screen.** `CourseListView` from lesson 2 is a `struct` with an array in it and a `body`. Creating one
allocates a few bytes and draws nothing. SwiftUI reads the description, works out what should be
on the screen, and keeps the real thing, the pixels and the platform's own objects behind them,
somewhere you never touch.

The picture most people bring from other toolkits is a view as an object that lives on the screen:
you create a label once, keep a reference to it, and later set its text. **There is nothing to keep a
reference to here.** A view value is created, read and thrown away, and a new one is created the
next time SwiftUI needs a description. Changing what the screen shows means changing the data the
description is made from, never reaching into the screen.

This is the `View` protocol as Apple's documentation for it presents it, read on 30 October 2026:

```swift
struct MyView: View {
    var body: some View {
        Text("Hello, World!")
    }
}
```

One requirement, `body`, which is a computed property: every time it is read, it runs and returns a
new description. Section 04 is about when SwiftUI reads it, and section 05 counts.

## What follows from a view being a value

- **Making a view is cheap, so SwiftUI makes them freely.** A screen of fifty rows creates fifty
  small structs every time it is described again, and that is the design working as intended.
- **A view cannot remember anything in an ordinary stored property.** A `var count = 0` inside a
  view struct is reset every time the struct is created again, which is every time its parent's
  `body` runs. What a view must remember goes in storage SwiftUI keeps for it, `@State`, which is
  lesson 6.
- **Two views with the same description are interchangeable.** That is what lets SwiftUI compare
  the new description with the old one and change only what differs.

Like `App`, a type that conforms to `View` in its own declaration runs on the main actor, Apple's
documentation for `View` says, which is where drawing happens. Nothing in this section was run for
the course; the parts of this lesson that ran are sections 03, 05, 06 and 07, which rebuild the
mechanisms in plain Swift.
