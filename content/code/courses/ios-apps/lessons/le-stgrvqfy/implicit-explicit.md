---
title: Two ways to ask for an animation
version: 1
---

**SwiftUI never animates a view; it animates a change of state.** The belief to drop is that an
animation is something you start, like a timer. In SwiftUI the state changes at once, and the body runs at once with the new value. An animation is
an instruction attached to that change, saying how the screen should travel from what it showed to
what it now has to show. There are two places to attach it.
Nothing in this section was run: it is written from Apple's documentation for `animation(_:value:)`,
`withAnimation(_:_:)` and `Transaction`, as it stood on 30 October 2026.

## Implicit: on the view, for one value

The planner's week bar fills as sessions are marked done. It can say, once, that whenever its fraction
changes the change is animated:

```swift
// WeekBar.swift
import SwiftUI
import PlannerCore

struct WeekBar: View {
    let total: WeekTotal

    var body: some View {
        let fraction = total.planned == 0 ? 0 : Double(total.done) / Double(total.planned)
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule().fill(.tint).frame(width: proxy.size.width * fraction)
            }
        }
        .frame(height: 12)
        .animation(.easeInOut, value: fraction)
    }
}
```

Apple's documentation for `animation(_:value:)` says it applies the animation to this view whenever
the value changes. **`value` is the part that matters.** The bar animates when `fraction` changes and
for no other reason, so a rotation of the phone or a font-size change that redraws the bar is not
dragged out over 0.35 seconds. The older `animation(_:)` without a value animated the view whenever
anything about it changed, and Apple's documentation marks it deprecated for exactly the surprises that
caused.

## Explicit: around the change, for everything it touches

The other place is the moment of the change itself:

```swift
// CourseDetailView.swift, the button on a session's row
Button("Mark done") {
    withAnimation(.easeOut) {
        markDone(session.id)
    }
}
```

`markDone(_:)` is the screen's own method that changes the plan. Apple's documentation for
`withAnimation(_:_:)` says it sets the animation on the current **transaction**, the record SwiftUI
keeps of one change and everything it causes. So every view whose appearance changes because of this
one tap animates with `.easeOut`: the row's checkmark, the row moving to another group, the week bar,
the total in the navigation bar, wherever they are on the screen. Nothing on those views has to know.

## Which one

| | `animation(_:value:)` | `withAnimation` |
|---|---|---|
| written on | the view that moves | the code that changes the state |
| animates | this view, when this value changes | everything the change causes |
| good for | a view that always moves the same way, like the bar | an action whose whole effect should move together |
| surprise to watch for | a change from elsewhere animates too, if it moves the same value | a view that should snap now slides, because it changed in the same transaction |

When both apply to the same change, the view's own `animation(_:value:)` wins for that view. Apple's
documentation for `Transaction` describes the order: the animation set by `withAnimation` travels down
the view tree, and a modifier lower down can replace it for its subtree. The planner uses the implicit
form for the bar, so the bar moves the same way whoever changes the total, and the explicit form for
"mark done", so the row and everything else move together.

`withAnimation` with no animation at all uses `Animation.default`, and section 04 shows what that is.
