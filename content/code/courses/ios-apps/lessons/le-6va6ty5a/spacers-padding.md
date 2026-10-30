---
title: Spacers and padding: space you ask for, and space around you
version: 1
---

**A `Spacer` is a view whose whole job is to take space, and `padding` is a modifier that adds space
around a view.** They are often confused because both make gaps, and they answer different questions:
a spacer pushes siblings apart in a stack, padding keeps a view's own content off its edges.

## Spacer

Apple's documentation for `Spacer` says it expands along the major axis of its stack as much as the
stack allows, moving sibling views out of the way, and on both axes when it is not in a stack. It adds
a sentence worth reading twice: **a stack with no spacer is only as wide as the ideal widths of its
children**. So `HStack { Text("SQL Databases"); Text("50 min") }` hugs its two texts, and the list
centres that small stack in the row; add a `Spacer()` between them and the stack takes the whole
width, with the minutes at the far edge.

`Spacer(minLength: 0)` lets a spacer shrink to nothing when space runs out. Without the argument the
minimum is a default the system chooses, which keeps two labels from touching. The model in section
08 uses a spacer with no minimum, and says so, so that its arithmetic needs no number it cannot know.

## Padding

```swift
WeekView()
    .padding()
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
```

`.padding()` with no arguments adds what Apple's documentation for `padding(_:_:)` calls a
platform-specific default amount on every edge; `.padding(.horizontal, 16)` adds 16 points on the
left and right only. **Padding is a new view around the old one**, exactly as a frame was in section
04: it proposes to its child the size it was offered, minus the padding, and reports the child's size
plus the padding.

That is why the order above matters, and why lesson 5 begins with it. The background comes after the
padding, so it is drawn around the padded view and the rounded rectangle has room inside it. Swap the
two lines and the background hugs the content while the padding adds empty space outside it.

Nothing in this section was run for the course; it is written from Apple's documentation for `Spacer`
and `padding(_:_:)`, read on 30 October 2026.
