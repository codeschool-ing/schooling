---
title: What animates, and what only changes
version: 1
---

**SwiftUI animates numbers.** Whatever moves on the screen during an animation, a width, a colour, a
position, an angle, is a value SwiftUI can compute partway between two others. Apple's documentation for
the `Animatable` protocol describes the mechanism: when an animatable value changes inside an animated
change, SwiftUI reads the old and the new values and interpolates between them over successive frames,
writing each interpolated value back on every frame. Anything that cannot be computed partway does not
move; it changes, and at most fades. Nothing in this section was run; section 04 computes the
interpolation itself.

## The body runs once

When `fraction` goes from two thirds to one, the bar's body runs once, with the new value, and returns
a bar that is full. It does not run 21 times on the way. What runs on every frame is SwiftUI's own
interpolation of the properties it knows how to animate, `frame(width:)` here, from the width it drew to
the width it now has to draw. That is why animation in SwiftUI costs little: the expensive part, your
body, ran once.

## A shape that does not animate until told how

A progress ring instead of a bar is a `Shape` with a fraction in it:

```swift
// ProgressRing.swift
import SwiftUI

struct ProgressRing: Shape {
    var fraction: Double

    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                        radius: min(rect.width, rect.height) / 2,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * fraction),
                        clockwise: false)
        }
    }
}
```

**Without `animatableData`, the ring jumps.** Apple's documentation for `animatableData` says the
default implementation returns `EmptyAnimatableData`, "meaning nothing is animated": SwiftUI asks the
shape what to interpolate and is told nothing, so it draws the old ring and then the new one. The four
lines of `animatableData` hand it `fraction`, and on every frame SwiftUI sets `fraction` to the next
interpolated value and calls `path(in:)` again. Here, unlike the bar, your code does run per frame, so a
`path(in:)` that does real work is paid for on every one of the 21 frames a 0.35-second animation
has at 60 Hz.

## What does not interpolate

| change | what happens |
|---|---|
| a width, an opacity, an offset, a colour | interpolated, frame by frame |
| the text of a `Text`, `"120 min"` to `"150 min"` | swapped, with a cross-fade; `.contentTransition(.numericText())` asks for digits that roll instead |
| `if done { checkmark }` | the checkmark is inserted or removed: that is a **transition**, section 05 |
| a different view in the same place | removal of one and insertion of the other, also section 05 |
| a `Bool` or an enum property of your own | swapped, because nothing is between `true` and `false` |

The rule under the table: **SwiftUI interpolates values and transitions identities.** A view that is
the same view with new numbers moves; a view that stops existing, or starts, is handed to a transition.
Lesson 3 is where structural identity was defined, and this is the first place it shows on the screen.
