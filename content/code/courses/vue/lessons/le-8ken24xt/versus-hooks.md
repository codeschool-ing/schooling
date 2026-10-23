---
title: Composables and React's custom hooks
version: 1
---

**A composable and a React custom hook solve the same problem, sharing stateful logic between
components, and they look alike: both are functions named `use…`.** They behave differently because the
components that call them do, and that difference is lesson 2's: a React component runs on every render,
a Vue component's setup runs once.

The same piece of logic, the week, as a React hook. It is shown for comparison and is not part of this
course's project:

```jsx
// React: called on every render of the component that uses it.
function useWeek(start) {
  const [monday, setMonday] = useState(start)
  const sunday = useMemo(() => addDays(monday, 6), [monday])
  const next = useCallback(() => setMonday((m) => addDays(m, 7)), [])
  return { monday, sunday, next }
}
```

| | React custom hook | Vue composable |
|---|---|---|
| how often it runs | on every render of the caller | once, during the caller's setup |
| what it returns | plain values, fresh on each render | refs, which stay the same objects and change their `.value` |
| derived values | `useMemo` with a list of dependencies, written by hand | `computed`, which finds its own |
| functions it returns | recreated on each render, unless wrapped in `useCallback` | created once |
| the rule about calling it | always, in the same order, on every render: never inside a condition or a loop | during setup, never from a callback that runs later; inside a condition is allowed |

## Why the rules differ

**React identifies each hook's state by its position** in the sequence of hook calls on each render. Call
`useState` inside an `if`, and on the render where the condition changes, every later hook reads the
state of the one before it. Hence the rule: same hooks, same order, every time.

**Vue identifies state by the ref object itself.** The composable runs once, the refs it makes are
ordinary objects held by the component, and nothing about them depends on order. A composable called
inside an `if` in setup is fine, as long as setup is still running: what Vue needs is only to know which
component is being set up, for the hooks and watchers to attach to.

## What carries over

The habit of extracting logic into a function named for what it gives, and the discipline of having it
clean up after itself, are the same in both, and in Svelte's and Angular's equivalents too (lesson 22).
What does not carry over is the reflex of a React developer to wrap every derived value in a memo and
every function in a callback for fear of re-renders. In a composable, there is no re-render to fear.
