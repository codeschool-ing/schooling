---
title: Previews, a screen in every state at once
version: 1
---

**A preview is a view drawn by Xcode beside its code, redrawn as you type, without running the app.**
It is not a test, since nothing fails, and it is the fastest way to look at a screen in a state that
is hard to reach by tapping: a week with no sessions, a course title three lines long, the largest
text size, the dark theme. Nothing here was run; it needs Xcode's canvas. It is written from Apple's
documentation for the `#Preview` macro and the canvas, read on 30 October 2026.

```swift
// WeekView+Previews.swift
import SwiftUI
import PlannerCore

#Preview("An ordinary week") {
    WeekView(total: WeekTotal(monday: "2026-10-19", planned: 180, done: 120))
}

#Preview("Nothing planned yet") {
    WeekView(total: WeekTotal(monday: "2026-10-19", planned: 0, done: 0))
}

#Preview("All done, largest text") {
    WeekView(total: WeekTotal(monday: "2026-10-19", planned: 180, done: 180))
        .environment(\.dynamicTypeSize, .accessibility5)
}
```

**Each `#Preview` is a named state**, and the canvas shows them as tabs. The values are the
package's own types, built by hand, which is the payoff of keeping the planner's data in plain
Swift: a preview needs no server, no database and no simulator state, only a value.

## Using them as a working tool

- **Write the awkward states first.** The ordinary week looks fine by construction. `planned: 0` is
  where a division by zero turns a progress bar into nothing, and the largest text size is where
  lesson 19 section 05's layouts break.
- **The canvas's Variants mode** draws one preview in every colour scheme, orientation or text size
  at once, so a screen is checked against all of them in one look.
- **A preview that needs the whole app to draw is a warning.** If `WeekView` cannot be previewed
  without a network client and a store, it is doing more than drawing a week, and lesson 14's
  repository is where that work belongs.

A preview proves nothing on its own. It shows you what to fix; the unit test is what keeps it fixed.
