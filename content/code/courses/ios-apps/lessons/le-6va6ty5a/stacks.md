---
title: Stacks: HStack, VStack and ZStack
version: 1
---

**A stack arranges its children along one axis, or on top of each other, and offers each a share of
its own proposal.** Three of them cover most screens: `HStack` side by side, `VStack` one under
another, and `ZStack` in layers, the later ones in front. Each takes two optional arguments, an
`alignment` for the other axis and a `spacing` between children.

```swift
// CourseRow.swift
import SwiftUI
import PlannerCore

struct CourseRow: View {
    let course: Course
    let minutes: Int

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(course.title)
                    .font(.headline)
                Text("this week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(minutes) min")
                .monospacedDigit()
        }
    }
}
```

**A `VStack(alignment: .leading)` aligns its children's leading edges, and that is what the argument
is for.** Without it the two texts would be centred on each other, a short caption under the middle of
a long title. The `HStack`'s own alignment, which this row leaves at the default, decides how the
`VStack` and the minutes line up vertically, and section 05 compares the choices.

`spacing: 12` is the gap between the stack's children. Leave it out and the stack uses a spacing the
platform chooses, which Apple's documentation describes as a default distance that depends on the
two adjacent views; the course's model in section 08 uses a fixed 8 to keep its arithmetic visible.

## Every child at once, or only what is on the screen

Apple's documentation for `HStack` makes a distinction worth knowing now: an `HStack` creates all of
its children at once, whether they are on the screen or not, while a `LazyHStack` creates them only
when they are needed. For a row of three views that is irrelevant. For a column of five hundred
sessions it is the difference lesson 8 is about, and `List` is lazy in the same way.

`ZStack` is for layering: a background shape behind a label, a badge over an icon. The planner uses it
once, in lesson 11, for a progress ring with the minutes written inside.

Nothing in this section was run for the course. `CourseRow` is written from Apple's documentation for
`HStack`, `VStack`, `Text` and `Spacer`, read on 30 October 2026.
