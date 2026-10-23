---
title: Context: a value any component below can read
version: 1
---

**Context lets a component make a value available to everything below it in the tree, without
passing it through the components in between.** Three pieces: a context object, a provider that puts
a value in it for a subtree, and a hook that reads the nearest provider's value. React 19 made two of
them shorter than older tutorials show.

The context and the hook go in a file with no components in it, `src/plannerContext.ts`:

```typescript
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
```

- **`createContext<Planner | null>(null)`** makes the context object. The argument is the value a
  component reads when there is no provider above it, and `null` here means "no planner", which the
  hook turns into an error.
- **`ReturnType<typeof usePlanner>`** names the type of whatever `usePlanner` returns, so the context's
  type follows the hook's without being written twice. `import type` is enough, because only the type
  is used.
- **`use(PlannerContext)`** reads it. `use` is React 19's; `useContext(PlannerContext)` does the same
  and is what most code written before 2025 says.

The provider is a component, so it gets a file of its own, `src/PlannerProvider.tsx`:

```tsx
import type { ReactNode } from 'react'
import { PlannerContext } from './plannerContext'
import { usePlanner } from './usePlanner'

export function PlannerProvider({ children }: { children: ReactNode }) {
  const planner = usePlanner()
  return <PlannerContext value={planner}>{children}</PlannerContext>
}
```

**`<PlannerContext value={…}>` is the provider**; before React 19 it was written
`<PlannerContext.Provider value={…}>`, which still works. `PlannerProvider` calls `usePlanner` once and
puts what it returns in the context for everything inside. It goes around `App`, in `src/main.tsx`:

```tsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { PlannerProvider } from './PlannerProvider'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <PlannerProvider>
      <App />
    </PlannerProvider>
  </StrictMode>,
)
```

Two files instead of one, because the linter's `only-export-components` rule warns about a file that
exports a component and anything else: Vite's fast refresh, which replaces an edited component in the
running page, can only do that for a file that exports nothing but components. One file per kind keeps
the warning away and fast refresh working.

## Reading it

`CourseScreen` stops receiving the sessions and `onToggle`, and reads both from the context; it filters
its own course's sessions now that nobody hands them over:

```tsx
import { useEffect, useRef } from 'react'
import { usePlannerContext } from './plannerContext'
import type { Course } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  onBack: () => void
}

export function CourseScreen({ course, onBack }: CourseScreenProps) {
  const { sessions, toggleDone } = usePlannerContext()
  const heading = useRef<HTMLHeadingElement>(null)
  useEffect(() => {
    heading.current?.focus()
  }, [])

  const sorted = sessions
    .filter((s) => s.course === course.id)
    .sort((a, b) => a.date.localeCompare(b.date))
  return (
    <>
      <button type="button" onClick={onBack}>
        Back to courses
      </button>
      <h1 ref={heading} tabIndex={-1}>
        {course.name}
      </h1>
      {sorted.length === 0 ? (
        <p>No sessions planned for this course yet.</p>
      ) : (
        <ul>
          {sorted.map((s) => (
            <li key={s.id}>
              <label>
                <input type="checkbox" checked={s.done} onChange={() => toggleDone(s.id)} />
                {formatDay(s.date)} · {s.minutes} min
              </label>
            </li>
          ))}
        </ul>
      )}
    </>
  )
}
```

And `App` reads the planner the same way, so `usePlanner` is called in exactly one place, the provider:

```tsx
import { useState } from 'react'
import { CourseList } from './CourseList'
import { CourseScreen } from './CourseScreen'
import { usePlannerContext } from './plannerContext'
import { useWeek } from './useWeek'
import { inWeek } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

function App() {
  const [monday, setMonday] = useWeek()
  const { status, courses, sessions } = usePlannerContext()
  const [openId, setOpenId] = useState<string | null>(null)

  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <p role="alert">The planner could not be loaded.</p>

  const open = courses.find((c) => c.id === openId)
  if (open) {
    return (
      <main>
        <CourseScreen course={open} onBack={() => setOpenId(null)} />
      </main>
    )
  }

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList courses={courses} sessions={thisWeek} onOpen={setOpenId} />
    </main>
  )
}

export default App
```

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 68ms on 15 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | grep minutes
    - paragraph: 120 of 195 minutes done
```

Clean, and the planner behaves as it did. The hook's error is the reason it checks for `null`: render
`App` without the provider, which the `sed` does by deleting the two lines that open and close it, and
the hook says exactly what is wrong instead of failing later on `undefined`:

```
ana@dev:~/planner$ cp src/main.tsx /tmp/main.tsx
ana@dev:~/planner$ sed -i '/PlannerProvider>$/d' src/main.tsx
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 2>&1 | grep -m 1 '^Uncaught'
Uncaught Error: usePlannerContext must be called inside <PlannerProvider>
ana@dev:~/planner$ cp /tmp/main.tsx src/main.tsx
```
