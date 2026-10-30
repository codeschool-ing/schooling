---
title: When describing is not enough
version: 1
---

**Almost everything in React is a description**: you say what the screen should look like, and React
changes the DOM to match. A few things the browser does not let you describe. It only does them when
asked, at a particular moment, by calling a method on a particular element:

| what you want | what the browser needs | why a description cannot say it |
|---|---|---|
| move the keyboard focus | `element.focus()` | focus is an event in time, not a property of the page |
| open a dialog as modal | `dialog.showModal()` | the `open` attribute opens it, but not as modal |
| bring something into view | `element.scrollIntoView()` | scrolling is an action |
| know how big something came out | `element.getBoundingClientRect()` | only the browser knows, after layout |
| hand a node to code that is not React | a map, a chart, an editor | that code wants the element itself |

For each of these you need the element, and **a ref is how React gives it to you**. Lesson 7 used one
to focus the course screen's heading: `useRef` makes the box, `ref={heading}` asks React to put the
`<h1>` in it, and an effect calls `heading.current?.focus()`.

Three rules keep this safe, and they come from how React works rather than from taste:

- **Use the element in an effect or an event handler, never while rendering.** During the first
  render the element does not exist yet, so `ref.current` is still `null`; and a render has to be
  pure, so it must not change anything in the browser, focus included.
- **Ask, do not rearrange.** Calling `focus()` or `showModal()` asks the browser to do something it
  owns. Adding or removing children of an element React renders, or changing text React put there,
  edits what React believes it owns, and the next update can overwrite your change or fail on a node
  that is no longer where React left it.
- **Prefer the platform's own element** when there is one. The browser already knows how a modal
  dialog should behave: where the focus goes, what Escape does, what a screen reader is allowed to
  reach. Code that rebuilds that from `<div>`s has to get every one of those right by hand.

The planner needs the second row of that table. The form that adds a session sits at the foot of the
course screen, always visible, and it is going to move into a dialog that opens when you ask for it.
