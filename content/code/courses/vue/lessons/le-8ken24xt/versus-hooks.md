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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two halves. On the left, React: state is found by position. On render 1 three hooks are called, the first inside an if, in positions 1, 2 and 3. On render 2 the condition has changed and the hook inside the if is not called, so the next hook takes position 1 and the one after takes position 2: each later hook reads the state of the one before it. On the right, Vue: setup runs once, the composable useWeek is called inside it, inside an if if need be, and the component holds the objects it returns, monday, a ref, and sunday, a computed. The state is the object itself, not its place in a list.\"><text x=\"180\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">React: state by position</text><text x=\"105\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">render 1</text><text x=\"265\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">render 2: the if is false</text><text x=\"22\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"40\" y=\"58\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hook inside the if</text><rect x=\"200\" y=\"58\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">next hook</text><line x1=\"172\" y1=\"75\" x2=\"196\" y2=\"75\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><polygon points=\"196.0,75.0 188.6,78.1 188.6,71.9\" fill=\"var(--amber)\"></polygon><text x=\"22\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"40\" y=\"104\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">next hook</text><rect x=\"200\" y=\"104\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the one after</text><line x1=\"172\" y1=\"121\" x2=\"196\" y2=\"121\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><polygon points=\"196.0,121.0 188.6,124.1 188.6,117.9\" fill=\"var(--amber)\"></polygon><text x=\"22\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"40\" y=\"150\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the one after</text><rect x=\"200\" y=\"150\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"180\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">each later hook reads the state of the one before it</text><line x1=\"360\" y1=\"14\" x2=\"360\" y2=\"236\" stroke=\"var(--scan)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></line><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Vue: state by the object</text><rect x=\"390\" y=\"50\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">setup()</text><text x=\"460\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">runs once</text><line x1=\"460\" y1=\"96\" x2=\"460\" y2=\"124\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"460.0,124.0 456.9,116.6 463.1,116.6\" fill=\"var(--phosphor)\"></polygon><rect x=\"390\" y=\"126\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">useWeek()</text><text x=\"460\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">inside an if: allowed</text><rect x=\"565\" y=\"70\" width=\"135\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"632\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">monday: ref</text><line x1=\"532\" y1=\"148\" x2=\"561\" y2=\"87\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"561.0,87.0 560.6,95.0 555.0,92.3\" fill=\"var(--phosphor)\"></polygon><rect x=\"565\" y=\"130\" width=\"135\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"632\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sunday: computed</text><line x1=\"532\" y1=\"148\" x2=\"561\" y2=\"147\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"561.0,147.0 553.7,150.4 553.5,144.1\" fill=\"var(--phosphor)\"></polygon><text x=\"540\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the component holds the same objects for its whole life</text></svg>", "caption": "React finds a hook's state by the order of the calls; Vue by the ref the composable made."}
```

## What carries over

The habit of extracting logic into a function named for what it gives, and the discipline of having it
clean up after itself, are the same in both, and in Svelte's and Angular's equivalents too (lesson 22).
What does not carry over is the reflex of a React developer to wrap every derived value in a memo and
every function in a callback for fear of re-renders. In a composable, there is no re-render to fear.
