---
title: The state you should not store
version: 1
---

**If a value can be computed from props or state you already have, compute it. Do not store it.**
State is a copy, and a copy has to be kept in step with what it was copied from. Nobody keeps it in
step, so it goes stale. This is the most common state mistake in React, and this section commits it
on purpose. The planner's `WeekSummary` adds up minutes on every render; here is a version that adds
them up once, into state:

```tsx
import { useState } from 'react'
import type { Session } from './types'
import { formatWeek, minutes } from './week'

type WeekSummaryProps = {
  monday: string
  sessions: Session[]
}

// A mistake, on purpose: the totals copied into state.
export function WeekSummary({ monday, sessions }: WeekSummaryProps) {
  const [planned] = useState(minutes(sessions))
  const [done] = useState(minutes(sessions.filter((s) => s.done)))
  return (
    <section aria-label="This week">
      <p>Week of {formatWeek(monday)}</p>
      <p>
        {done} of {planned} minutes done
      </p>
    </section>
  )
}
```

After "Next week":

```
ana@dev:~/planner$ cp src/WeekSummary.tsx /tmp/WeekSummary.tsx
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Next week' | sed -n 6,9p
    - button "Next week"
  - region "This week":
    - paragraph: Week of 26 Oct 2026
    - paragraph: 80 of 195 minutes done
ana@dev:~/planner$ cp /tmp/WeekSummary.tsx src/WeekSummary.tsx
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Next week' | sed -n 6,9p
    - button "Next week"
  - region "This week":
    - paragraph: Week of 26 Oct 2026
    - paragraph: 0 of 0 minutes done
```

**"Week of 26 Oct 2026" and "80 of 195 minutes done"**, side by side, both on screen at once. The week
line comes from the prop, which is new. The totals come from state, whose initial value was computed
on the first render and then never again, because an initial value is used once. The second `look`
puts the original `WeekSummary` back, and the totals follow the week: 0 of 0.

The planner already holds three pieces of state, and every number on the first screen is computed from
them while rendering:

| stored, because nothing else knows it | computed, because something else does |
|---|---|
| `monday`, which week the user chose | the week's sessions: a filter of `sessions` by `monday` |
| `sessions`, the planner's data | the minutes planned and done: sums over the week's sessions |
| `openId`, which course is open | the open course: `courses.find` by `openId` |

**The test for a piece of state is to ask what would set it.** If the answer is "the user, or the
server", it is state. If the answer is "it has to be recalculated whenever this other thing changes",
it is a calculation, and the right place for a calculation is the render. Lesson 7 shows what to do
when a calculation is expensive enough to matter, which a filter over six sessions is not.
