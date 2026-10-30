---
title: Loading it before it is needed
version: 1
---

**Waiting for the click is the latest moment to fetch the code; it does not have to be the
earliest.** Once the planner is on the screen, the network is idle while the student reads their
week, and that is time the course screen's file could be travelling. Fetching it then is
**preloading**.

The function that imports the module gets a name, so that `lazy` and an effect can both call it:

```tsx
import { lazy, Suspense, useEffect, useState } from 'react'
import { CourseList } from './CourseList'
import { LoadFailed } from './LoadFailed'
import { usePlannerContext } from './plannerContext'
import { useWeek } from './useWeek'
import { inWeek } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

const loadCourseScreen = () => import('./CourseScreen')
const CourseScreen = lazy(() =>
  loadCourseScreen().then((module) => ({ default: module.CourseScreen })),
)

function App() {
  const [monday, setMonday] = useWeek()
  const { status, courses, sessions } = usePlannerContext()
  const [openId, setOpenId] = useState<string | null>(null)

  // Once the planner is on the screen, fetch the course screen's code in the
  // background, so that opening a course does not wait for it.
  useEffect(() => {
    if (status === 'ready') void loadCourseScreen()
  }, [status])

  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <LoadFailed />

  const open = courses.find((c) => c.id === openId)
  if (open) {
    return (
      <main>
        <Suspense fallback={<p>Loading the course…</p>}>
          <CourseScreen course={open} onBack={() => setOpenId(null)} />
        </Suspense>
      </main>
    )
  }

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList key={monday} courses={courses} sessions={thisWeek} onOpen={setOpenId} />
    </main>
  )
}

export default App
```

- `loadCourseScreen` is the same dynamic import as before. **Calling it twice fetches the file once**:
  the browser keeps each module it has loaded, and a second `import()` of it resolves at once.
- The effect runs when `status` becomes `ready`, after the first screen is drawn, so the preload never
  competes with what the student came to see.
- `void` says that the promise is deliberately not awaited: nothing here needs its result, and `lazy`
  will get the module when the component renders.

```
ana@dev:~/planner$ npm run lint && npm run build | grep -E "assets|built"

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 71ms on 20 files with 116 rules using 4 threads.
dist/assets/index-C0qAAZg_.css          0.43 kB │ gzip:  0.25 kB
dist/assets/CourseScreen-BpXtaa6Z.js  111.03 kB │ gzip: 34.52 kB
dist/assets/index-Ckv6Cg16.js         261.57 kB │ gzip: 81.56 kB
✓ built in 634ms
ana@dev:~/planner$ look http://localhost:4173/ --today 2026-10-21 --network | grep -E 'assets|api'
net  GET /assets/index-C0qAAZg_.css  200
net  GET /assets/index-Ckv6Cg16.js  200
net  GET /api/planner  200
net  GET /assets/CourseScreen-BpXtaa6Z.js  200
ana@dev:~/planner$ look http://localhost:4173/ --today 2026-10-21 --do 'wait 5000' --do 'click button Statistics' | grep -E 'heading|alert|error'
  - heading "Statistics" [level=1]
  - heading "Add a session" [level=2]
```

The main file's name changed with the code; the course screen's changed too, because it imports from
the main file. Then two pages. The first shows the order: the planner's data, and then, with no click,
`CourseScreen-BpXtaa6Z.js`. The second repeats the deploy from the last section, the server stopped
three seconds in, and **the course opens anyway**, heading and form, because its code had arrived long
before the server went away.

That second result is a side effect, not the reason to preload: a page left open over a deploy for
longer than the preload took would have the code already, and one opened later still needs the old
files to be kept. The reason is the first result, a click that does not wait.

Preloading spends something, too: **every visitor now downloads the course screen**, 34.5 kB
compressed, including the ones who never open a course. The split still helps them, because the first
screen no longer waits for it, but the bytes are spent. For a screen that most users open, preloading
after the first render is a good trade; for a part few people reach, such as an admin page, keep it
on demand. A middle way is to start the import when the pointer moves over the button or the button
takes focus, a few hundred milliseconds before a likely click.
