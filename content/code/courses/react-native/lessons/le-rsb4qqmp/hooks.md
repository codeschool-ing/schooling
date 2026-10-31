---
title: Hooks, and the two rules they keep
version: 1
---

**A hook is a function whose name starts with `use` and which keeps something for a component between
renders.** `useState` keeps a value. `useEffect` runs code after a render. `useTheme` in lesson 5 and
`useSafeAreaInsets` in lesson 6 are hooks built from other hooks. A component function runs from the top
on every render; hooks are how anything survives from one run to the next.

## The two rules

React finds each hook's stored value by **the order in which the hooks are called**: the first `useState`
of a component is always the first, the second always the second. That is why there are two rules, and
why breaking either produces wrong values rather than a clear error:

1. **Call hooks at the top level of a component or of another hook.** Never inside a condition, a loop or
   a callback. A hook skipped on one render shifts every hook after it onto the wrong stored value.
2. **Call hooks only from components and from other hooks.** A plain function called from an event
   handler has no render to belong to.

The planner's `CourseScreen` follows the first rule in a way that is easy to miss: it calls `useTheme`,
`usePlan` and `useLayoutEffect` **before** the early `return` for a missing course. Moving the
`useLayoutEffect` below that `return` would call it on some renders and not on others.

## useEffect, for what happens after drawing

`useEffect(fn, deps)` runs `fn` after React has put a render on the screen, and again whenever a value in
`deps` changes. It is for **synchronising with something outside React**: a subscription, a timer, the
navigation header, a request. What it returns is the clean-up, run before the next effect and when the
component goes:

```tsx
useEffect(() => {
  const id = setInterval(() => setNow(Date.now()), 60_000); // a clock that ticks each minute
  return () => clearInterval(id); // stop it when the screen goes
}, []);
```

An empty `deps` runs the effect once. **A value used inside and left out of `deps` is a stale value**:
the effect keeps seeing what it saw the first time. React's lint rule for hooks flags it, and the habit of
listing every value the effect reads saves a class of bug that only appears after the state changes.

What an effect is **not** for is computing something from props or state. The week's total is
calculated during render, from the plan, every time; storing it in state and updating it in an effect
would be a second copy that is wrong for one render each time the plan changes.

## useTransition, briefly

Lesson 1 said the new architecture lets React interrupt a render. `useTransition` is how you ask for that.
`startTransition(() => setFilter(text))` marks an update as **not urgent**: React renders it in the
background and abandons it if something more urgent, the next keystroke, arrives first. A search over
thousands of sessions stays responsive to typing that way. The planner's lists are too short to need it,
and lesson 19 is where a measurement would say otherwise.
