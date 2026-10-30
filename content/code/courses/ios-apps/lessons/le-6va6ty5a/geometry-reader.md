---
title: GeometryReader, and the newer ways to size by the container
version: 1
---

**`GeometryReader` is the one view that hands you the proposal itself.** Its content is a closure
that receives a `GeometryProxy`, from which you read the size the reader was offered, and you build
views from that number. Apple's documentation for `GeometryReader` adds the half that surprises
people: it returns a flexible preferred size to its parent, which in practice means **it takes all the
space it is offered**, whatever its content needs.

```swift
GeometryReader { proxy in
    let done = Double(total.done) / Double(max(total.planned, 1))
    Capsule()
        .fill(.tint)
        .frame(width: proxy.size.width * done)
}
.frame(height: 8)
```

That is a progress bar for `WeekView`: a capsule as wide as the fraction of the week done. **The
`.frame(height: 8)` outside is not decoration.** Without it the reader would take all the height the
`VStack` around it offered, and the bar would push everything else off the screen.

## Why it is the last resort

A `GeometryReader` breaks the three steps of section 02 in one direction: its content decides
nothing about the reader's size, so content that wants to be small cannot make the reader small. It is
easy to end up with a screen full of readers fighting over space, and it is the view most answers
online reach for first.

Three newer tools cover most of what it used to be used for, and each keeps the normal rules:

| need | tool | since |
|---|---|---|
| a size that is a fraction of the screen or the scroll view | `containerRelativeFrame(_:alignment:)` | iOS 17 |
| show the largest of several layouts that fits | `ViewThatFits` | iOS 16 |
| an arrangement no stack provides | a type that conforms to `Layout` | iOS 16 |

`containerRelativeFrame` sizes a view relative to the nearest container, which Apple's documentation
lists as the window or the screen, a navigation stack, a tab, or a scroll view. `ViewThatFits` tries
its children in order and shows the first whose ideal size fits the proposal, so a row can fall back
from "title, bar and minutes" to "title and minutes" on a narrow phone. And a custom `Layout`
implements the two methods section 08 models in plain Swift: `sizeThatFits`, the second step, and
`placeSubviews`, the third.

Nothing in this section was run for the course; it is written from Apple's documentation for
`GeometryReader`, `containerRelativeFrame(_:alignment:)`, `ViewThatFits` and `Layout`, read on 30
October 2026. The progress bar's arithmetic, fraction done times width, is the only part with no
SwiftUI in it, and `max(total.planned, 1)` is there so a week with nothing planned divides by one
instead of zero.
