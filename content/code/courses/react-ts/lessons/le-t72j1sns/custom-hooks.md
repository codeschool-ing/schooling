---
title: Writing a custom hook
version: 1
---

**A custom hook is a function whose name starts with `use` and which calls other hooks.** That is the
whole mechanism. It lets a component hand a piece of its logic, state and effects included, to a
function with a name, and lets two components share that logic without sharing state: each component
that calls the hook gets its own.

`App` has been growing two separate concerns since lesson 5: loading the planner's data, and keeping
the week, with its title and its keyboard shortcut. Each becomes a hook. `src/usePlanner.ts` owns the
data:

```typescript
import { useCallback, useEffect, useState } from 'react'
import type { Course, Session } from './types'

type Status = 'loading' | 'ready' | 'failed'

export function usePlanner() {
  const [courses, setCourses] = useState<Course[]>([])
  const [sessions, setSessions] = useState<Session[]>([])
  const [status, setStatus] = useState<Status>('loading')

  useEffect(() => {
    let ignore = false
    fetch('/courses.json')
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.json()
      })
      .then((data: { courses: Course[]; sessions: Session[] }) => {
        if (ignore) return
        setCourses(data.courses)
        setSessions(data.sessions)
        setStatus('ready')
      })
      .catch((error) => {
        if (ignore) return
        console.error('could not load the planner:', error.message)
        setStatus('failed')
      })
    return () => {
      ignore = true
    }
  }, [])

  const toggleDone = useCallback((id: string) => {
    setSessions((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }, [])

  return { status, courses, sessions, toggleDone }
}
```

It is lesson 5's fetch, word for word, with `toggleDone` from the last section, and it returns the four
things a caller needs as an object. `src/useWeek.ts` owns the week:

```typescript
import { useEffect, useState } from 'react'
import { addDays, formatWeek, mondayOf, today } from './week'

export function useWeek() {
  const [monday, setMonday] = useState(() => mondayOf(today()))

  useEffect(() => {
    document.title = `Week of ${formatWeek(monday)} · Study planner`
  }, [monday])

  useEffect(() => {
    function onKey(event: KeyboardEvent) {
      if (event.target instanceof HTMLInputElement) return
      if (event.key === 'ArrowLeft') setMonday((m) => addDays(m, -7))
      if (event.key === 'ArrowRight') setMonday((m) => addDays(m, 7))
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  return [monday, setMonday] as const
}
```

It returns a pair, like `useState` does, and `as const` tells TypeScript that the pair is exactly a
string and a setter, in that order, rather than an array of either. And `App` is left with what is
actually its job, deciding which screen to draw:

```tsx
import { useState } from 'react'
import { CourseList } from './CourseList'
import { CourseScreen } from './CourseScreen'
import { usePlanner } from './usePlanner'
import { useWeek } from './useWeek'
import { inWeek } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

function App() {
  const [monday, setMonday] = useWeek()
  const { status, courses, sessions, toggleDone } = usePlanner()
  const [openId, setOpenId] = useState<string | null>(null)

  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <p role="alert">The planner could not be loaded.</p>

  const open = courses.find((c) => c.id === openId)
  if (open) {
    return (
      <main>
        <CourseScreen
          course={open}
          sessions={sessions.filter((s) => s.course === open.id)}
          onToggle={toggleDone}
          onBack={() => setOpenId(null)}
        />
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
ana@dev:~/planner$ wc -l src/App.tsx src/usePlanner.ts src/useWeek.ts
  43 src/App.tsx
  39 src/usePlanner.ts
  22 src/useWeek.ts
 104 total
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 74ms on 13 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'press ArrowRight' --do 'click button Previous week' --html title | sed -n 1,2p\;9,11p\;\$p
-- press ArrowRight
-- click button Previous week
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Courses":
<title>Week of 19 Oct 2026 · Study planner</title>
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | grep minutes
    - paragraph: 120 of 195 minutes done
```

`App` went from 87 lines to 43, the linter and the type check are clean, and the planner behaves as it
did: the arrow key moved a week and the button moved it back, the title followed, and ticking a session
still adds 40 minutes. Nothing the user can see changed. **A custom hook moves code; it does not change
what the code does**, and every hook inside it keeps its place in `App`'s order, because calling
`useWeek()` calls its hooks, in order, at the top of `App`.

```schooling-figure
{"svg": "<svg data-fig=\"custom-hook\" viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"On the left, App's code calls useWeek, usePlanner and useState. On the right, the hooks React actually records for App, in order: useWeek's useState and two useEffects, then usePlanner's three useStates, its fetch useEffect and its useCallback, then App's own useState for openId. A custom hook's hooks are App's hooks, in the place it is called.\"><text x=\"140\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what App's code says</text><text x=\"520\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what React records for App</text><rect x=\"30\" y=\"34\" width=\"220\" height=\"68\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">useWeek()</text><line x1=\"252\" y1=\"68.0\" x2=\"368\" y2=\"68.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"368.0,68.0 360.5,71.2 360.5,64.8\" fill=\"var(--phosphor)\"></polygon><text x=\"386\" y=\"44\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"392\" y=\"34\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useState  monday</text><text x=\"386\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"392\" y=\"58\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useEffect title</text><text x=\"386\" y=\"92\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"392\" y=\"82\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useEffect keyboard</text><rect x=\"30\" y=\"106\" width=\"220\" height=\"116\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">usePlanner()</text><line x1=\"252\" y1=\"164.0\" x2=\"368\" y2=\"164.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"368.0,164.0 360.5,167.2 360.5,160.8\" fill=\"var(--amber)\"></polygon><text x=\"386\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4</text><rect x=\"392\" y=\"106\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useState  courses</text><text x=\"386\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">5</text><rect x=\"392\" y=\"130\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useState  sessions</text><text x=\"386\" y=\"164\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">6</text><rect x=\"392\" y=\"154\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useState  status</text><text x=\"386\" y=\"188\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">7</text><rect x=\"392\" y=\"178\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useEffect fetch</text><text x=\"386\" y=\"212\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">8</text><rect x=\"392\" y=\"202\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useCallback toggleDone</text><rect x=\"30\" y=\"226\" width=\"220\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">useState(null)</text><line x1=\"252\" y1=\"236.0\" x2=\"368\" y2=\"236.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"368.0,236.0 360.5,239.2 360.5,232.8\" fill=\"var(--wire)\"></polygon><text x=\"386\" y=\"236\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">9</text><rect x=\"392\" y=\"226\" width=\"260\" height=\"20\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">useState  openId</text><text x=\"520\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nine slots, in the order of the calls</text></svg>", "caption": "A custom hook adds its hooks to the caller's list, where it is called."}
```

Two rules for writing one, both already familiar. **The name starts with `use`**, which is how the
linter knows to check the rules of hooks inside it and at the places it is called. **It returns what
callers need and nothing more**: `usePlanner` does not hand out `setCourses`, because nothing outside
should replace the course list, and lesson 11 replaces the whole inside of it with a library without
changing a line of `App`.
