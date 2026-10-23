---
title: useMemo keeps a calculation between renders
version: 1
---

**`useMemo(fn, deps)` calls `fn` on the first render, keeps what it returned, and hands back that same
value on later renders until something in `deps` changes.** Two reasons to use it, and the second is
the one that matters more often: a calculation slow enough to notice, and a value whose identity
other code depends on.

The planner computes `thisWeek` on every render with `sessions.filter(…)`, and `filter` always returns
a new array, even when its contents are the same. To see what that does, two temporary changes: a
button in `App` that does nothing but render `App` again, and an effect in `WeekSummary` that logs
whenever its `sessions` prop is a different array:

```
ana@dev:~/planner$ cp src/App.tsx /tmp/App.tsx; cp src/WeekSummary.tsx /tmp/WeekSummary.tsx
ana@dev:~/planner$ sed -i 's|^  const \[openId, setOpenId\] = useState<string \| null>(null)$|&\n  const [, setTick] = useState(0)|; s|^      <WeekNav .*|&\n      <button type="button" onClick={() => setTick((t) => t + 1)}>Render App again</button>|' src/App.tsx
ana@dev:~/planner$ sed -i 's|^  const done = sessions.filter((s) => s.done)$|  useEffect(() => console.log('"'"'WeekSummary received a new sessions array'"'"'), [sessions])\n&|; 1i import { useEffect } from "react"' src/WeekSummary.tsx
ana@dev:~/planner$ grep -n "setTick\|useEffect" src/App.tsx src/WeekSummary.tsx | grep -v "^src/App.tsx:[0-9]*:  useEffect(() => {$"
src/App.tsx:1:import { useEffect, useState } from 'react'
src/App.tsx:17:  const [, setTick] = useState(0)
src/App.tsx:82:      <button type="button" onClick={() => setTick((t) => t + 1)}>Render App again</button>
src/WeekSummary.tsx:1:import { useEffect } from "react"
src/WeekSummary.tsx:11:  useEffect(() => console.log('WeekSummary received a new sessions array'), [sessions])
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Render App again' --do 'click button Render App again'
WeekSummary received a new sessions array
WeekSummary received a new sessions array
-- click button Render App again
WeekSummary received a new sessions array
-- click button Render App again
WeekSummary received a new sessions array
```

The two lines on load are strict mode's double effect, as in lesson 5. **Then each press of "Render
App again" logs again**: nothing about the week changed, but `App` rendered, `filter` made a new
array, and to `Object.is` a new array is a different value. For this effect that is a wasted log; for
an effect that fetches, or subscribes, or for lesson 21's `memo`, it is real work done for nothing.

## The first attempt

Wrapping the calculation in `useMemo` is one change, and done where the calculation already is, it
fails:

```
ana@dev:~/planner$ sed -i 's|^  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))$|  const thisWeek = useMemo(\n    () => sessions.filter((s) => inWeek(s.date, monday)),\n    [sessions, monday],\n  )|; s|^import { useEffect, useState } from .react.$|import { useEffect, useMemo, useState } from '"'"'react'"'"'|' src/App.tsx
ana@dev:~/planner$ grep -n -A 3 "const thisWeek" src/App.tsx
77:  const thisWeek = useMemo(
78-    () => sessions.filter((s) => inWeek(s.date, monday)),
79-    [sessions, monday],
80-  )
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Render App again' 2>&1 | grep -E '^Uncaught|^\[error\] React'
[error] React has detected a change in the order of Hooks called by %s. This will lead to bugs and errors if not fixed. For more information, read the Rules of Hooks: https://react.dev/link/rules-of-hooks
Uncaught Error: Rendered more hooks than during the previous render.
```

**Lesson 6's crash, exactly.** `thisWeek` was computed below the two early returns, so the new hook is
called only once the data has arrived: nine hooks while loading, ten when ready. `useMemo` is a hook
like any other, and turning a plain calculation into a hook is precisely the moment it has to move
above every `return`.

## Above the returns

```
ana@dev:~/planner$ grep -n -B 1 -A 5 "const thisWeek" src/App.tsx
59-
60:  const thisWeek = useMemo(
61-    () => sessions.filter((s) => inWeek(s.date, monday)),
62-    [sessions, monday],
63-  )
64-
65-  if (status === 'loading') return <p>Loading the planner…</p>
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Render App again' --do 'click button Render App again'
WeekSummary received a new sessions array
WeekSummary received a new sessions array
-- click button Render App again
-- click button Render App again
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Render App again' --do 'click button Next week'
WeekSummary received a new sessions array
WeekSummary received a new sessions array
-- click button Render App again
-- click button Next week
WeekSummary received a new sessions array
ana@dev:~/planner$ cp /tmp/App.tsx src/App.tsx; cp /tmp/WeekSummary.tsx src/WeekSummary.tsx
```

Now pressing "Render App again" logs nothing: `sessions` and `monday` were the same, so `useMemo`
returned the array it already had, and the effect saw the same value. "Next week" changed `monday`,
`useMemo` ran the filter again, and the effect logged once. **That is the contract: the same inputs
give the same object.**

Both temporary changes came out with the `cp` at the end, and so did `useMemo`. The planner's filter
over six sessions is not slow, and nothing in it depends on the array's identity yet; lesson 21 brings
`useMemo` back where `memo` makes identity matter, and measures whether it helps. **Do not wrap
calculations in `useMemo` by reflex.** It costs a hook, a dependency array that has to stay right,
and a rule of hooks to respect, as the first attempt showed, and it buys nothing for a calculation
that was already cheap.
