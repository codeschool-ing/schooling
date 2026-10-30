---
title: Frames: a new view around the old one
version: 1
---

**`.frame(width: 200)` does not set a view's width. It puts the view inside a new, invisible view that
is 200 wide, and proposes 200 to the view inside.** The view inside then chooses, as section 02 said
every view does. Apple's documentation for `frame(width:height:alignment:)` describes it in those
terms: it positions this view within an invisible frame with the specified size.

The difference shows the moment the view inside wants less than the frame:

```swift
Text("50 min")
    .frame(width: 200)
    .border(.red)
```

The red border is drawn around the frame, 200 points wide, and the text sits in the middle of it at
the width of its words. **Two views, two sizes**: the frame is 200, the text is not. The `alignment`
argument decides where in the frame the smaller view goes, and the documentation notes that it has no
visible effect when the two sizes happen to match.

## Flexible frames

The second form of `frame` takes minimums, ideals and maximums instead of a fixed size, and its
commonest use is one argument:

```swift
Text("Week of 19 October")
    .frame(maxWidth: .infinity, alignment: .leading)
```

**`maxWidth: .infinity` makes a frame that accepts any width it is offered**, so in a stack it behaves
like a spacer, taking what is left. Apple's documentation for the flexible form spells out the rule:
with no minimum or maximum in a dimension the frame adopts its child's sizing, and with constraints it
clamps the proposal to them. The `alignment: .leading` then puts the text at the left of that wide
frame, which is the usual way to left-align a heading across a screen.

## When the text does not fit

A `Text` offered less than its ideal width wraps onto more lines if it may, and truncates with an
ellipsis if it may not. `.fixedSize()` tells a view to ignore the proposal and take its ideal size,
which Apple's documentation for `fixedSize()` demonstrates with a long string inside a 200-point frame:
with it, the text runs past the frame instead of wrapping. It is the right tool when a short label
must never be cut, and the wrong one for a sentence, which would run off the screen.

Nothing in this section was run for the course. The listings are written from Apple's documentation
for the two `frame` modifiers and `fixedSize()`, read on 30 October 2026, and the course shows no
screenshot of what they draw.
