---
title: useCallback is useMemo for a function
version: 1
---

**A function written inside a component is a new function on every render**, for the same reason
`filter` returned a new array: the code that creates it runs again. `useCallback(fn, deps)` keeps the
first one and hands it back until a dependency changes. It is exactly `useMemo(() => fn, deps)`, with
the extra arrow written for you.

The planner has a function that is passed down a long way: `toggleDone`, from `App` through
`CourseScreen` to every checkbox. The next section moves it into a custom hook, and there it is
written like this:

```tsx
const toggleDone = useCallback((id: string) => {
  setSessions((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
}, [])
```

The array is empty, and correctly so: the function reads nothing from the render, because the updater
form receives the sessions from React. That is the same move that kept lesson 5's keyboard effect
fresh with `[]`, paying off a second time. **A function that only calls setters with updater forms
can be created once and never go stale.**

Why bother, when the last section said not to memoise by reflex? Because this function leaves the
hook. Whoever calls `usePlanner` receives it, and a hook's caller should be able to put what it
returns in a dependency array, or pass it to a `memo` component, without the hook's internals deciding
that it changes on every render. **Inside one component, memoise when you measure a reason. In what a
custom hook returns, keep identities stable**, because the hook cannot know how it will be used.

Three things `useCallback` does not do, because each is a common belief:

- **It does not make the function faster.** The function does the same work; only its identity is kept.
- **It does not stop the component from rendering.** The component still renders; the callback is
  simply the same object as last time.
- **It does not fix a stale closure.** A callback memoised with the wrong dependencies is a stale
  closure kept on purpose, and the linter's `exhaustive-deps` checks `useCallback`'s array as it checks
  an effect's.
