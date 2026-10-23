---
title: Fetching the planner's data
version: 1
---

**Since lesson 2 the planner has read its data from `sample.ts`, a copy of `public/courses.json`.
Now it fetches the file itself**, the way it will fetch from a real server in lesson 11. That means
the data is not there on the first render, which means a screen for "not yet", and a screen for "it
did not work". This is the new `src/App.tsx` in full, with the three effects of this lesson:

```tsx
import { useEffect, useState } from 'react'
import { CourseList } from './CourseList'
import { CourseScreen } from './CourseScreen'
import type { Course, Session } from './types'
import { addDays, formatWeek, inWeek, mondayOf, today } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

type Status = 'loading' | 'ready' | 'failed'

function App() {
  const [monday, setMonday] = useState(() => mondayOf(today()))
  const [courses, setCourses] = useState<Course[]>([])
  const [sessions, setSessions] = useState<Session[]>([])
  const [status, setStatus] = useState<Status>('loading')
  const [openId, setOpenId] = useState<string | null>(null)

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

  function toggleDone(id: string) {
    setSessions((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }

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

The first effect is the one that matters here. Read it from the top:

- **`useState<Course[]>([])`** and its neighbour start empty, and `status` starts at `'loading'`, a
  union of three strings that says which of three screens to draw. Lesson 19 calls this kind of type
  a discriminated union, and lesson 11 replaces the whole arrangement with a library.
- **`fetch('/courses.json')`** asks the development server for the file in `public/`. A response
  arrives whatever the status, so `response.ok` is checked by hand, and anything but a 2xx becomes an
  error.
- **The `.then` that sets state** runs when the JSON has been parsed, which is after the render that
  started it; React renders again with the data.
- **`ignore`** is the cleanup. If the component goes away, or the effect is cleaned up for any other
  reason, before the response arrives, `ignore` becomes true and the late answer is dropped instead
  of written into state that nobody should see. The section after next shows when that happens.
- **`[]`** says the effect depends on nothing, so it runs once after the component first appears.

`sample.ts` goes, and the type check agrees nothing else needed it:

```
ana@dev:~/planner$ rm src/sample.ts
ana@dev:~/planner$ npx tsc -b && echo no errors
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network | grep -v 'GET /[@sn]'
net  GET /  200
net  GET /courses.json  200
net  GET /courses.json  200
- main:
  - heading "Study planner" [level=1]
  - navigation "Week":
    - button "Previous week"
    - button "Next week"
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]:
        - button "Statistics"
      - paragraph: 2 sessions · 90 min
    - article:
      - heading "Spanish" [level=2]:
        - button "Spanish"
      - paragraph: 2 sessions · 60 min
    - article:
      - heading "Organic chemistry" [level=2]:
        - button "Organic chemistry"
      - paragraph: 1 session · 45 min
```

`--network` lists the requests the page made, and the ones Vite makes for each module are filtered
out by `grep`, leaving the page itself and the data. **`/courses.json` was fetched twice.** That is
strict mode again: in development it runs every effect, cleans it up, and runs it again, so the first
request's `ignore` became true and its answer was thrown away. The second request's answer drew the
screen. In the build you publish, the effect runs once.

That double request is the reason the cleanup exists. Without `ignore`, both answers would set state,
which is harmless here because they are identical. It stops being harmless the moment two requests can
answer differently: the user picks one course, then another, and the answer for the first arrives
last.
