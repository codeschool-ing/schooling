---
title: Reduce Motion, and the people animation makes ill
version: 1
---

**For some people, movement on a screen causes dizziness or nausea, and iOS has a setting that asks
apps to stop.** It is *Reduce Motion*, under the Accessibility settings, and an app reads it through
the environment. Apple's documentation for `accessibilityReduceMotion` says what the setting asks:
when it is true, the interface "should avoid large animations, especially those that simulate the third
dimension". It does not ask for no feedback. Nothing in this section was run; it is written from that
documentation, as it stood on 30 October 2026.

## Reading it

```swift
// DayPicker.swift, the button honouring Reduce Motion
@Environment(\.accessibilityReduceMotion) private var reduceMotion

Button {
    withAnimation(reduceMotion ? nil : .spring) { selected = day }
} label: {
    // as in section 06
}
```

`withAnimation(nil)` is a change with no animation: the capsule appears under the new day in one frame.
**The state changes the same way in both branches**, and only how the screen travels differs. That is
the shape every Reduce Motion fix should have, because a branch that also changed *what* happens would
be a second behaviour to test, and the one that fewer people use is the one that breaks.

## What the planner changes, and what it keeps

| animation | with Reduce Motion |
|---|---|
| the day picker's sliding capsule (section 06) | none: it moves across the screen, which is the case the setting is about |
| the "week done" note sliding up (section 05) | a fade instead: `.opacity`, with no `.move` |
| the week bar filling (section 02) | kept: it grows in place, is small, and tells the student that the tap worked |
| a sheet sliding up for `SessionForm` | the system's own, which follows the setting by itself |

The note's transition becomes a choice made in one place:

```swift
// WeekView.swift, the note's transition
.transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
```

**Removing motion is not removing feedback.** A person with Reduce Motion on still needs to see that
their tap did something: the bar still fills and the note still appears. What goes is travel across the
screen, scaling, and anything that pretends to be three-dimensional.

## Checking it

On a Mac, the simulator has the setting where a phone has it, in its own Settings app under
*Accessibility* and *Motion*, and lesson 19 is about the tools Xcode adds for checking accessibility.
None of that was run for this course: the table above is a decision made from the documentation, and
checking each row is a job for a Mac, or a phone, and a pair of eyes.
