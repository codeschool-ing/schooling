---
title: The version that does not crash
version: 1
---

**The same mistake in a component with one hook does not crash. It loses state, silently.** That is
worse, because nothing tells you. Here is a `WeekSummary` that has learnt something new: a button
that switches the second line between the minutes done and the minutes left. It also returns early
when the week is empty, and its one hook is after that `return`:

```tsx
import { useState } from 'react'
import type { Session } from './types'
import { formatWeek, minutes } from './week'

type WeekSummaryProps = {
  monday: string
  sessions: Session[]
}

// A mistake, on purpose: a hook after an early return.
export function WeekSummary({ monday, sessions }: WeekSummaryProps) {
  if (sessions.length === 0) {
    return <p>Nothing planned in the week of {formatWeek(monday)}.</p>
  }
  const [showLeft, setShowLeft] = useState(false)
  const planned = minutes(sessions)
  const done = minutes(sessions.filter((s) => s.done))
  return (
    <section aria-label="This week">
      <p>Week of {formatWeek(monday)}</p>
      <p>{showLeft ? `${planned - done} minutes left` : `${done} of ${planned} minutes done`}</p>
      <button type="button" onClick={() => setShowLeft(!showLeft)}>
        {showLeft ? 'Show minutes done' : 'Show minutes left'}
      </button>
    </section>
  )
}
```

```
ana@dev:~/planner$ npx tsc -b && echo no errors
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Show minutes left' | sed -n 6,10p
    - button "Next week"
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 115 minutes left
    - button "Show minutes done"
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Next week' | sed -n 6,8p
    - button "Next week"
  - paragraph: Nothing planned in the week of 26 Oct 2026.
  - region "Courses":
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Show minutes left' --do 'click button Next week' --do 'click button Previous week' | grep minutes
-- click button Show minutes left
    - paragraph: 80 of 195 minutes done
    - button "Show minutes left"
```

Every transcript looks fine. The button switches to "115 minutes left", and an empty week draws its
sentence. **The last one is the bug.** Press "Show minutes left", move to the empty week and back, and
the summary has forgotten: "80 of 195 minutes done", with the button offering "Show minutes left"
again.

What happened is the order argument from two sections back, at its edge. In the empty week
`WeekSummary` called no hooks, so React threw its one slot away; back in a full week it called one
hook, and React, seeing a component with no slots, created a fresh one with the initial value,
`false`. No hook was in the wrong place, so there was nothing to detect and no error. A component
with two or more hooks either side of the `return` gets the crash from the last section instead.

The linter is not fooled by either:

```
ana@dev:~/planner$ npm run lint

> planner@0.0.0 lint
> oxlint


  x react-hooks(rules-of-hooks): React Hook "useState" is called conditionally. React Hooks must be called in the exact same order in every component render.
    ,-[src/WeekSummary.tsx:15:35]
 14 |   }
 15 |   const [showLeft, setShowLeft] = useState(false)
    :                                   ^^^^^^^|^^^^^^^
    :                                          `-- This Hook call is not reachable on every render path.
 16 |   const planned = minutes(sessions)
    `----
  help: Move the Hook call before the condition, or call it unconditionally and branch inside the Hook/effect instead.

Found 0 warnings and 1 error.
Finished in 77ms on 11 files with 116 rules using 4 threads.
```

"This Hook call is not reachable on every render path." Moving `useState` above the `if` is the whole
fix, and the order is kept whatever the week:

```tsx
import { useState } from 'react'
import type { Session } from './types'
import { formatWeek, minutes } from './week'

type WeekSummaryProps = {
  monday: string
  sessions: Session[]
}

export function WeekSummary({ monday, sessions }: WeekSummaryProps) {
  const [showLeft, setShowLeft] = useState(false)
  if (sessions.length === 0) {
    return <p>Nothing planned in the week of {formatWeek(monday)}.</p>
  }
  const planned = minutes(sessions)
  const done = minutes(sessions.filter((s) => s.done))
  return (
    <section aria-label="This week">
      <p>Week of {formatWeek(monday)}</p>
      <p>{showLeft ? `${planned - done} minutes left` : `${done} of ${planned} minutes done`}</p>
      <button type="button" onClick={() => setShowLeft(!showLeft)}>
        {showLeft ? 'Show minutes done' : 'Show minutes left'}
      </button>
    </section>
  )
}
```

```
ana@dev:~/planner$ npm run lint

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 28ms on 11 files with 116 rules using 4 threads.
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Next week' | sed -n 6,8p
    - button "Next week"
  - paragraph: Nothing planned in the week of 26 Oct 2026.
  - region "Courses":
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Show minutes left' --do 'click button Next week' --do 'click button Previous week' | grep minutes
-- click button Show minutes left
    - paragraph: 115 minutes left
    - button "Show minutes done"
```

The linter is clean, the empty week still draws its sentence, and the last transcript is the one that
failed before: **"115 minutes left"** after the round trip, because the hook was called in every week
and its slot was never thrown away. This version is not kept either. The planner's screens are
fixed across the four framework courses, and lesson 1 drew this one without the button, so the commands at
the end of the next section put lesson 5's `WeekSummary` back.
