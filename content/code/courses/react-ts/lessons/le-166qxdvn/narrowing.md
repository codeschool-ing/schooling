---
title: Narrowing, once and in one place
version: 1
---

**Checking the discriminant narrows the type.** Inside `if (planner.status === 'ready')`, TypeScript
knows the planner is the ready shape, and `planner.courses` is a `Course[]`. The question is where the
check goes, and the answer the planner already had is `Root`: it draws the screens only when the
planner is ready. So the check goes once in `Root`, and once more in a small hook for the screens it
draws, `src/plannerContext.ts`:

```ts
import { createContext, use } from 'react'
import type { usePlanner } from './usePlanner'

export type Planner = ReturnType<typeof usePlanner>

export const PlannerContext = createContext<Planner | null>(null)

export function usePlannerContext(): Planner {
  const planner = use(PlannerContext)
  if (planner === null) {
    throw new Error('usePlannerContext must be called inside <PlannerProvider>')
  }
  return planner
}

// For the screens Root draws, which it draws only once the planner is ready.
export function useReadyPlanner() {
  const planner = usePlannerContext()
  if (planner.status !== 'ready') {
    throw new Error(`useReadyPlanner was called while the planner is ${planner.status}`)
  }
  return planner
}
```

**`useReadyPlanner` narrows by throwing.** After the `if`, the only shape left is `'ready'`, so what it
returns has `courses` and `sessions`, typed. If a screen ever called it before `Root` had checked, the
error would say so at once, instead of a screen quietly drawing an empty week.

`LoadFailed` stops reading the context and takes what it needs as props, `src/LoadFailed.tsx`:

```tsx
type LoadFailedProps = {
  retry: () => void
  retrying: boolean
}

export function LoadFailed({ retry, retrying }: LoadFailedProps) {
  return (
    <main>
      <h1>Study planner</h1>
      <div role="alert">
        <p>The planner could not be loaded. The server did not answer.</p>
      </div>
      <button type="button" onClick={() => retry()} disabled={retrying}>
        {retrying ? 'Trying again…' : 'Try again'}
      </button>
    </main>
  )
}
```

and `Root` switches on the status, `src/Root.tsx`:

```tsx
import { Outlet } from 'react-router'
import { LoadFailed } from './LoadFailed'
import { usePlannerContext } from './plannerContext'

// Every screen of the planner is drawn inside this one, where <Outlet /> is.
export function Root() {
  const planner = usePlannerContext()
  switch (planner.status) {
    case 'loading':
      return <p>Loading the planner…</p>
    case 'failed':
      return <LoadFailed retry={planner.retry} retrying={planner.retrying} />
    case 'ready':
      return (
        <main>
          <Outlet />
        </main>
      )
    default: {
      const unhandled: never = planner
      return unhandled
    }
  }
}
```

In each `case`, the planner has that case's shape: `planner.retry` compiles under `'failed'` and would
not under `'loading'`. The `default` is the subject of the next section. The screens change their
import and their call:

```
ana@dev:~/planner$ sed -i 's/usePlannerContext/useReadyPlanner/g' src/WeekScreen.tsx src/CourseScreen.tsx && grep -n 'ReadyPlanner' src/WeekScreen.tsx src/CourseScreen.tsx
src/WeekScreen.tsx:2:import { useReadyPlanner } from './plannerContext'
src/WeekScreen.tsx:10:  const { courses, sessions } = useReadyPlanner()
src/CourseScreen.tsx:6:import { useReadyPlanner } from './plannerContext'
src/CourseScreen.tsx:12:  const { sessions, toggleDone } = useReadyPlanner()
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 75ms on 27 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 | grep -E 'Week of|minutes done'
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'wait 9000' | grep -E 'alert|paragraph|button'
  - alert:
    - paragraph: The planner could not be loaded. The server did not answer.
  - button "Try again"
```

The compiler is satisfied, the lint too, and the planner behaves as before: the week with its 80 of
195 minutes, and with the API stopped, the alert and its button, now drawn from props.
