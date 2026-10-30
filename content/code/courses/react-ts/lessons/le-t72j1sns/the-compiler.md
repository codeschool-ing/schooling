---
title: The React Compiler, and why this lesson still matters
version: 1
---

**React Compiler 1.0 does much of what `useMemo` and `useCallback` do, automatically, at build time.**
It reads your components, works out which values can be kept between renders, and inserts the caching
itself. The React team released it as stable in late 2025, and on npm today it is
`babel-plugin-react-compiler` at 1.0.0; the version of `@vitejs/plugin-react` this course pinned in
lesson 1 lists it as an optional companion. Lesson 21 turns it on in the planner and measures what it
changes.

That raises a fair question: why learn the hooks it writes for you?

- **Because it relies on the rules.** The compiler assumes your components are pure and follow the
  rules of hooks. A component that mutates its props or reads a ref while rendering is one it either
  skips or gets wrong, so everything from lessons 2 to 6 is now also what keeps the compiler working.
- **Because existing code is full of them.** Most React code a job will hand you was written before the
  compiler, and `useMemo` and `useCallback` are in it, some needed, some not. Telling which is which is
  this lesson's skill.
- **Because `useRef` is not optional.** The compiler caches values; it does not focus a heading or keep
  a timer's id. Refs and custom hooks are design, not optimisation, and they stay.

So the order of work is the same with or without it: write pure components that follow the rules,
reach for a ref when something must be remembered without being drawn, extract a custom hook when a
component carries two concerns, and memoise only where identity matters or a measurement says so.
In most of those places the compiler then does it for you.
