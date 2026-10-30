---
title: Drawing one thing or another
version: 1
---

**JSX has no `if`, because braces hold expressions, and lesson 2 said why.** A component chooses
what to draw with the four tools JavaScript gives it, and the planner already uses all four:

| tool | what it means | in the planner |
|---|---|---|
| an early `return` | draw this instead of everything below | `App`'s loading and failure screens, and the course screen |
| a ternary, `a ? <A /> : <B />` | one of two | "session" or "sessions" in `CourseCard` |
| `&&`, `cond && <A />` | this, or nothing | none yet: the next section shows why it needs care |
| a variable | build the element first, use it below | the button `CourseCard` passes to `Card` as `title` |

**An early `return` is for whole screens; a ternary or `&&` is for a part of one.** `App` returns early
because a loading planner has no week to show at all, and lesson 6 said where those returns go: below
every hook. Inside a screen, a ternary keeps both branches next to each other where the reader can
compare them.

`null`, `undefined`, `false` and `true` render nothing, which is what makes `&&` work: when the
condition is false, the expression is `false`, and nothing is drawn. **Numbers and strings render as
text**, including `0` and `''` — but only `0` turns up on the screen — and that difference between
`false` and `0` is the next section's bug.

A component may also return `null` itself, as lesson 7's `RenderCount` did, to draw nothing at all
while still being a component with state and effects. That is different from not rendering it: a
component that returns `null` keeps its state, a component the parent stops rendering loses it.
