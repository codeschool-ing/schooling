---
title: Custom modifiers: a chain with a name
version: 1
---

**When the same chain of modifiers appears on three screens, it deserves a name, and SwiftUI gives
two ways to name it.** The planner draws a card around `WeekView`, around the summary at the top of
`CourseDetailView` and around an empty-state message: the same padding, the same rounded background,
the same font for the heading. Repeating the chain three times means three places to change it, and
one that will be forgotten.

## A `ViewModifier`

Apple's documentation for `ViewModifier` shows the shape: a type with one method, `body(content:)`,
which receives the view being modified as `content` and returns what to wrap it in.

```swift
// CardStyle.swift
import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: .rect(cornerRadius: 12))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
```

**The extension is the part people use.** The documentation calls it the common and idiomatic
approach: `modifier(_:)` applies the type, and a method named for what it does lets every screen write
`WeekView().cardStyle()`. The order inside `body(content:)` follows section 03's rules: padding first,
so the background has room inside it.

## Or an extension and nothing else

When the chain needs no state of its own, a plain extension on `View` does the same job with one type
fewer:

```swift
extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: .rect(cornerRadius: 12))
    }
}
```

**Choose the `ViewModifier` when the modifier needs state**, because a `ViewModifier` is a struct
whose `body` may declare `@State` like a view's, which lesson 6 introduces; the plain extension has
nowhere to keep any. For the planner's card, either works, and the course uses the first so that
lesson 11 can add an animation to it.

Like `View`, a type that conforms to `ViewModifier` in its own declaration runs on the main actor,
Apple's documentation says. Nothing in this section was run for the course; it is written from Apple's
documentation for `ViewModifier` and `modifier(_:)`, read on 30 October 2026.
