---
title: Dynamic Type, text the person sizes
version: 1
---

**The person chooses how large text is, in Settings, and an app that ignores the choice is
unreadable to the people who made it.** iOS calls the feature **Dynamic Type**: a range of text
sizes from extra small to the five accessibility sizes at the top, which are far larger than the
default. Nothing in this section was run; it follows Apple's documentation for SwiftUI's `Font`,
`ScaledMetric` and `DynamicTypeSize`, read on 30 October 2026.

**Text styles scale; point sizes do not.** `.font(.body)`, `.font(.headline)` and the other text
styles follow the person's setting without any code. `.font(.system(size: 15))` is fifteen points
whatever the setting, so the person who asked for large text gets small text in that one place.

```swift
// SessionSummary.swift
import SwiftUI

struct SessionSummary: View {
    let minutes: Int
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 20

    var body: some View {
        Label {
            Text("\(minutes) minutes")
                .font(.body)
        } icon: {
            Image(systemName: "clock")
                .resizable()
                .frame(width: iconSize, height: iconSize)
        }
    }
}
```

`@ScaledMetric` is for the numbers that are not text but should grow with it: an icon's size, the
padding beside a line. **Twenty points at the default size becomes more at a larger one**, in step
with `.body`, so the icon does not end up a dot beside a large line of text.

## Layouts that survive the largest sizes

At the accessibility sizes, a row laid out side by side runs out of width: the course title and the
minutes no longer fit on one line, and something is cut off with an ellipsis. Two answers, both in
SwiftUI:

- read the size and change the layout, with `@Environment(\.dynamicTypeSize)` and
  `dynamicTypeSize.isAccessibilitySize`, stacking the row vertically when it is true;
- or let SwiftUI choose with `ViewThatFits`, which tries the horizontal layout first and falls back
  to the vertical one when the first does not fit.

**Never answer it by limiting the size.** `.dynamicTypeSize(...DynamicTypeSize.large)` caps a view
at a size, and it exists for the rare control that cannot grow, a fixed-height tab bar. Used on
ordinary text it undoes the person's choice.

In Xcode, the canvas's *Variants* button shows a preview at every size at once, and the Accessibility
Inspector can change the size of a running simulator; lesson 20 uses previews that way.
