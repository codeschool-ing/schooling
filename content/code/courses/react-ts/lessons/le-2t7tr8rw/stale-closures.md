---
title: Stale closures
version: 1
---

**A function created during a render sees that render's values, for as long as the function lives.**
That is what `javascript` lesson 6 called a closure, and in a component it means that a callback kept
by something outside React (an interval, a listener, a promise) keeps reading the state of the render
that created it. This breaks no rule of hooks, and it is the commonest hook bug there is.

Here is a small custom hook, added to the end of `App.tsx` for this section: every second, it logs
which week it sees. The empty array says the effect reads nothing, which is false:

```tsx

// A mistake, on purpose: an interval that reads state, with an empty array.
export function useWeekLogger(monday: string) {
  useEffect(() => {
    const id = setInterval(() => console.log('the interval sees', monday), 1000)
    return () => clearInterval(id)
  }, [])
}
```

`App` calls it with `monday`. `look` waits a little over two seconds, presses "Next week", and waits
again; `uniq -c` folds identical lines into a count:

```
ana@dev:~/planner$ sed -i 's|^  const \[openId, setOpenId\] = useState<string \| null>(null)$|&\n  useWeekLogger(monday)|' src/App.tsx
ana@dev:~/planner$ grep -n "useWeekLogger" src/App.tsx
17:  useWeekLogger(monday)
91:export function useWeekLogger(monday: string) {
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'wait 2200' --do 'click button Next week' --do 'wait 2200' | uniq -c
      1 -- wait 2200
      2 the interval sees 2026-10-19
      1 -- click button Next week
      1 -- wait 2200
      3 the interval sees 2026-10-19
ana@dev:~/planner$ npm run lint 2>&1 | grep -A 2 exhaustive
  ! react-hooks(exhaustive-deps): React Hook useEffect has a missing dependency: 'monday'
    ,-[src/App.tsx:95:6]
 92 |   useEffect(() => {
```

**After "Next week", the interval still sees 19 October.** It was created in the first render's
effect, it closed over the first render's `monday`, and because the array was empty the effect never
ran again to replace it. The screen moved on; the interval did not. Oxlint said so before anything
ran, with the same warning as lesson 5.

```schooling-figure
{"svg": "<svg data-fig=\"closure\" viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Render 1 has monday 19 Oct and creates an interval that closes over it. Render 2 has monday 26 Oct. With an empty array the interval from render 1 keeps running and keeps printing 19 Oct. With monday in the array, render 2's effect clears the old interval and starts one that prints 26 Oct.\"><rect x=\"20\" y=\"30\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">render 1</text><text x=\"120.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">monday = 19 Oct</text><rect x=\"20\" y=\"120\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">render 2</text><text x=\"120.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">monday = 26 Oct</text><rect x=\"300\" y=\"30\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">interval A</text><text x=\"390.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">logs 19 Oct</text><line x1=\"222\" y1=\"52\" x2=\"298\" y2=\"52\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,52.0 290.5,55.2 290.5,48.8\" fill=\"var(--amber)\"></polygon><text x=\"590\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">with []: A runs forever</text><line x1=\"480\" y1=\"52\" x2=\"510\" y2=\"52\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"510.0,52.0 502.5,55.2 502.5,48.8\" fill=\"var(--amber)\"></polygon><rect x=\"300\" y=\"120\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">interval B</text><text x=\"390.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">logs 26 Oct</text><line x1=\"222\" y1=\"142\" x2=\"298\" y2=\"142\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,142.0 290.5,145.2 290.5,138.8\" fill=\"var(--phosphor)\"></polygon><text x=\"590\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">with [monday]: A cleared, B runs</text></svg>", "caption": "A callback sees the render that made it. Re-run the effect, and a new callback sees the new render."}
```

With `[monday]`, the effect is cleaned up and run again whenever the week changes, so the old
interval is cleared and a new one, closed over the new `monday`, takes its place:

```
ana@dev:~/planner$ sed -i 's|^  }, \[\])$|  }, [monday])|' src/App.tsx
ana@dev:~/planner$ tail -n 3 src/App.tsx
    return () => clearInterval(id)
  }, [monday])
}
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'wait 2200' --do 'click button Next week' --do 'wait 2200' | uniq -c
      1 -- wait 2200
      2 the interval sees 2026-10-19
      1 -- click button Next week
      1 -- wait 2200
      2 the interval sees 2026-10-26
ana@dev:~/planner$ cp /tmp/App.tsx src/App.tsx
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 37ms on 11 files with 116 rules using 4 threads.
no errors
```

The interval sees 26 October after the click. The last commands put the planner back as lesson 5 left
it, and the linter and the type checker agree that it is clean.

There were two ways out of this, and lesson 5 used the other one for the keyboard: **read the value
inside a function React calls with the latest one**, which for state is the updater form,
`setMonday((m) => …)`. Re-running the effect is right when the effect's work depends on the value,
as a timer that logs it does. The updater is right when the effect only needs to change the value, as
the keyboard does, and re-adding a listener on every week would be work for nothing.
