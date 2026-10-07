---
title: Transitions: from one state to another
version: 1
---

When a property changes, because of `:hover`, `:focus` or a class, the new value applies at once. A **transition** spreads the change over time:

```css
.button {
  background-color: #2f6f4e;
  transition: background-color 200ms ease-out;
}
.button:hover { background-color: #1e4a33; }
```

The shorthand takes the **property** to animate, the **duration**, the **timing function** of section 06, and optionally a **delay**. The transition goes on the element in its normal state, not in `:hover`, so that it runs both ways: towards the hover colour when the pointer arrives, and back when it leaves.

The step **`at MS`** pauses every animation and transition on the page at that many milliseconds from its start, so the middle of one can be read:

```
ana@laptop:~/site$ probe transition.html style .button background-color hover .button at 100 style .button background-color at 200 style .button background-color
button.button  background-color: rgb(47, 111, 78)
button.button  background-color: rgb(35, 86, 60)
button.button  background-color: rgb(30, 74, 51)
```

Before the hover, the background is `rgb(47, 111, 78)`. **100 ms** into the transition it is `rgb(35, 86, 60)`, between the two. At **200 ms**, the end, it is `rgb(30, 74, 51)`, which is `#1e4a33`. Halfway in time is not halfway in colour: each channel is already about two thirds of the way, red from 47 down to 35 on its way to 30, because `ease-out` spends its time that way.

## A few rules of thumb

**List the properties.** `transition: all 200ms` animates everything that changes, including properties you did not mean to, such as a `padding` changed by a media query at the moment the window is resized. Name the ones you want, separated by commas: `transition: background-color 200ms, scale 200ms`.

**Keep it short.** Interface feedback, a hover, a press, a focus ring, wants **100 to 300 ms**. Longer feels sluggish, because the reader has to wait for the interface to catch up with them.

**Transition `:focus-visible` too.** Whatever a hover reveals or changes, a keyboard user needs the same, lesson 5 section 05, and the same transition can serve both selectors.

**Not everything can be transitioned.** A property is animated by interpolating between two values, so it needs values in between: colours, lengths, numbers, transforms. `display: none` to `block` has nothing in between, and section 10 is about what to do instead.
