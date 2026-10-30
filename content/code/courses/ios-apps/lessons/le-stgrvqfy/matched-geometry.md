---
title: Matched geometry, one view in two places
version: 1
---

**`matchedGeometryEffect` makes two views look like one view moving.** When a view with an identifier is
removed and another with the same identifier is inserted in the same change, SwiftUI interpolates the
frame of the first into the frame of the second. Apple's documentation for
`matchedGeometryEffect(id:in:properties:anchor:isSource:)` says it plainly: the system interpolates
their frame rectangles in window space "to make it appear that there is a single view moving from its
old position to its new position". Nothing in this section was run; that documentation, read on 30
October 2026, is its source.

## The day picker on the week screen

The week screen lets the student pick a day to see its sessions. Seven buttons, Monday to Sunday, and a
capsule behind the one that is chosen. With matched geometry the capsule slides from day to day instead
of vanishing under one and appearing under another:

```swift
// DayPicker.swift
import SwiftUI

struct DayPicker: View {
    let days: [String]            // the week's days, YYYY-MM-DD, Monday first
    @Binding var selected: String
    @Namespace private var picker

    var body: some View {
        HStack(spacing: 4) {
            ForEach(days, id: \.self) { day in
                Button {
                    withAnimation(.spring) { selected = day }
                } label: {
                    Text(day.suffix(2))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background {
                            if day == selected {
                                Capsule()
                                    .fill(.tint.opacity(0.2))
                                    .matchedGeometryEffect(id: "selection", in: picker)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

Three pieces make it work:

- **`@Namespace`** gives the identifiers a scope of their own, so `"selection"` here cannot collide
  with a `"selection"` in another view.
- **One capsule exists at a time.** It is drawn under whichever day is selected, so changing `selected`
  removes the capsule from one button and inserts one under another, which is exactly the case the
  documentation describes.
- **The change is animated**, by `withAnimation(.spring)`. As with every transition in section 05,
  without an animation in the transaction there is nothing to interpolate over, and the capsule jumps.

## What it does not do

The documentation is just as plain about the limits. It links **geometry**, the frame, and nothing
else: "the usual transition mechanisms define how each of the two views is rendered during the
transition". Two views that look different, a small icon and a large one, still each fade in and out
with their own transitions while their frames are matched. And the documentation says the results are
undefined if the group does not have exactly one view with `isSource` true. Two capsules drawn at once,
because a bug selected two days, give a capsule that goes somewhere nobody chose. That makes the
`selected` property, one day and never two, more than tidiness.

`day.suffix(2)` turns `2026-10-21` into `21`, the day of the month. A real app formats the day with
the person's locale; lesson 19 is where the label each button reads aloud gets that care.
