---
title: A number before, and a number after
version: 1
---

**Performance work starts with a measurement, and it is not finished until a second one.** Without the
first, you optimise what you suspect, which is rarely what is slow. Without the second, you cannot tell a
change that helped from one that only added code, and a change that adds code and helps nothing is a
cost.

Four places an app built like the planner gets slow, and what measures each:

| what | what it feels like | what measures it |
|---|---|---|
| **renders** | a press that takes a moment to answer, typing that lags | React DevTools' Profiler; React's `<Profiler>` component; a count in a test |
| **lists** | blank rows while scrolling fast, a stutter at the end of a page | the Performance Monitor's frame rate on a phone; how many rows exist at once |
| **images** | an app the system closes in the background, slow scrolling past photos | decoded size: width × height × 4 bytes |
| **the bundle** | a slow first start, a slow first page on the web | the bundle's size, per package, from its source map |

The first and the last can be measured on a computer, and this lesson does; images can be reasoned about
exactly, and the reasoning checked in a browser. **What a phone's frame rate does was not measured for this
course**, which has no phone. Lesson 12 measured an animation in a browser for the same reason, and the same
honesty applies here: a computer is much faster than a cheap phone, so a phone has to confirm anything a
browser suggests.

**And measure a release build.** Lesson 18 showed what development adds: warnings, checks, no
minification. A development build is slower everywhere, by design, so a profile of one finds problems that
are not there and hides the proportions of the ones that are.
