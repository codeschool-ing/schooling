---
title: ScrollView, because a screen does not scroll by itself
version: 1
---

**A web page scrolls when its content is taller than the window. A phone screen does not.** Content
that runs past the bottom of a `View` is simply cut off, with no scrollbar and no gesture to reach it.
Scrolling is a component, `ScrollView`, and anything that may grow taller than the screen goes
inside one.

## What it does

`ScrollView` is a `View` whose contents can be taller (or, with `horizontal`, wider) than itself. It
becomes a native scroll view, so the momentum, the bounce at the edges on iOS and the overscroll glow on
Android are the platform's own, without any code of yours.

Two style props, and the difference between them confuses everybody once:

| prop | applies to | use it for |
|---|---|---|
| `style` | the scroll view itself, the window you look through | its size and background |
| `contentContainerStyle` | the inner view holding the children, which is what moves | padding, gaps and alignment of the content |

Padding set in `style` is padding around the window, and the content scrolls under it. Padding set in
`contentContainerStyle` is padding around the content, and it scrolls with it, which is nearly always
what was meant. The planner's screen uses the second.

## What it costs

**A ScrollView renders every child, all at once**, whether it is on the screen or two thousand pixels
below it. For a screen of a few dozen elements, that is exactly right: everything is ready, and
scrolling never has to wait. For a list of hundreds of items, it is not, because every one of them is
created as a native view before the screen first appears. Lesson 7 is about the component made for
that, `FlatList`, which creates only what is near the screen; the planner's three courses do not need
it yet.

## The keyboard and the scroll

A text field near the bottom of a `ScrollView` is covered by the keyboard when it opens, which is the
subject of lesson 11. `keyboardShouldPersistTaps="handled"` belongs on any `ScrollView` that holds a
form: without it, the first tap on a button while the keyboard is open only closes the keyboard, and
the button has to be pressed twice. It is one of those defaults that is right for reading and wrong
for forms.
