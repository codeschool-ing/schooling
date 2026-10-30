---
title: Transitions, for views that arrive and leave
version: 1
---

**A transition is how a view enters or leaves the screen, and it only plays when the change is
animated.** Section 03 ended on the rule: a view that keeps its identity is interpolated, and a view
that starts or stops existing is handed to a transition. The default transition is a fade. Nothing here
was run; it is written from Apple's documentation for `transition(_:)` and `AnyTransition`, as it
stood on 30 October 2026.

## The planner's case

The week screen can show a short note under the bar when the week's plan is complete. It is there or
it is not, so it arrives and leaves:

```swift
// WeekView.swift, the note when the week is done
VStack(alignment: .leading, spacing: 12) {
    WeekBar(total: total)
    if total.planned > 0 && total.done == total.planned {
        Label("Every session this week is done", systemImage: "checkmark.seal")
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
.animation(.easeInOut, value: total.done == total.planned)
```

`.transition` says **how** the label arrives and leaves: sliding from the bottom edge and fading at
the same time. It says nothing about **when** or **how fast**. That comes from the animation of the
change that inserts it, here the `animation(_:value:)` on the stack, watching the one condition that
puts the label there. **A transition with no animation in the transaction does nothing at all**: the
label appears in one frame. This is the commonest reason a transition "does not work", and the cure is
never in the `.transition` line.

## Building one from parts

| transition | what it does |
|---|---|
| `.opacity` | fades; the default |
| `.scale` | grows from nothing, or shrinks to it |
| `.move(edge:)` | slides in from that edge and out to it |
| `.slide` | in from the leading edge, out to the trailing one |
| `a.combined(with: b)` | both at once |
| `.asymmetric(insertion: a, removal: b)` | one way in, another way out |

`asymmetric` is the one that reads as designed rather than default. A row added to a list can arrive
from the top, where the person's eyes are after tapping Add, and leave by fading, because sliding away
something that has just been deleted draws attention to a thing that no longer matters.

## Rows in a list

A `List` animates its own rows. When a session is added or removed inside `withAnimation`, the list
inserts or removes the row with its own animation, and the other rows move to make room. Apple's
documentation does not describe a transition you attach to a row for that; the list decides. **What
the list needs from you is stable identity**, the `id` lesson 8 insisted on: a list told that a row was
removed and another inserted, when a session was only edited, animates a removal and an insertion where
nothing left.
