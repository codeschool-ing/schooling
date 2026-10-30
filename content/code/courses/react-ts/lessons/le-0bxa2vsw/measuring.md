---
title: Measuring before changing anything
version: 1
---

**Lesson 3 left a question open: React calls a component again whenever its parent renders, and
whether that is cheap was for later.** This lesson answers it the only honest way, by measuring
first. React has a component for that, **`<Profiler>`**: it wraps part of the tree and calls a
function each time that part is committed, with the reason and the time it took.

The function, `src/logRender.ts`, prints one line per commit:

```ts
import type { ProfilerOnRenderCallback } from 'react'

// For a <Profiler>: one line in the console each time what it wraps is drawn.
export const logRender: ProfilerOnRenderCallback = (id, phase) => {
  console.log(`drawn: ${id} (${phase})`)
}
```

`phase` is `'mount'` the first time and `'update'` after that. The callback also receives how long
the render took, `actualDuration`, and what it would take with nothing skipped, `baseDuration`; the
transcripts leave those out because they change from run to run, but they are what you read when the
question is speed.

The course screen's rows move into a component of their own, `src/SessionRow.tsx`, each wrapped in a
profiler named after its session:

```tsx
import { Profiler } from 'react'
import { logRender } from './logRender'
import type { Session } from './types'
import { formatDay } from './week'

type SessionRowProps = {
  session: Session
  onToggle: (id: string) => void
}

export function SessionRow({ session, onToggle }: SessionRowProps) {
  return (
    <Profiler id={`row ${session.id}`} onRender={logRender}>
      <label>
        <input type="checkbox" checked={session.done} onChange={() => onToggle(session.id)} />
        {formatDay(session.date)} · {session.minutes} min
      </label>
    </Profiler>
  )
}
```

and the screen draws them, `src/CourseScreen.tsx`:

```tsx
import { useEffect, useRef, useState } from 'react'
import { Link, useLoaderData } from 'react-router'
import { AddSessionForm } from './AddSessionForm'
import type { courseLoader } from './courseLoader'
import { Dialog } from './Dialog'
import { List } from './List'
import { useReadyPlanner } from './plannerContext'
import { SessionRow } from './SessionRow'
import { StatusMessage } from './StatusMessage'
import { formatDay } from './week'

export function CourseScreen() {
  const course = useLoaderData<typeof courseLoader>()
  const { sessions, toggleDone } = useReadyPlanner()
  const [planning, setPlanning] = useState(false)
  const [message, setMessage] = useState('')
  const heading = useRef<HTMLHeadingElement>(null)
  useEffect(() => {
    heading.current?.focus()
  }, [])

  const sorted = sessions
    .filter((s) => s.course === course.id)
    .sort((a, b) => a.date.localeCompare(b.date))
  return (
    <>
      <Link to="/">Back to courses</Link>
      <h1 ref={heading} tabIndex={-1}>
        {course.name}
      </h1>
      <List
        items={sorted}
        keyOf={(s) => s.id}
        render={(s) => <SessionRow session={s} onToggle={toggleDone} />}
        empty="No sessions planned for this course yet."
      />
      <button type="button" onClick={() => setPlanning(true)}>
        Plan a session
      </button>
      <Dialog open={planning} title="Plan a session" onClose={() => setPlanning(false)}>
        <AddSessionForm
          course={course.id}
          onAdded={(s) => {
            setPlanning(false)
            setMessage(`Planned ${formatDay(s.date)} · ${s.minutes} min.`)
          }}
        />
      </Dialog>
      <StatusMessage message={message} />
    </>
  )
}
```

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 88ms on 31 files with 116 rules using 4 threads.
no errors
```

`--quiet` keeps only the console, which is all this lesson needs. Opening statistics:

```
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet
drawn: row s1 (mount)
drawn: row s2 (mount)
```

Two rows mounted, as expected. Now open the dialog, which changes nothing about either session:

```
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet --do 'click button Plan a session'
drawn: row s1 (mount)
drawn: row s2 (mount)
-- click button Plan a session
drawn: row s1 (update)
drawn: row s2 (update)
```

**Both rows drawn again.** `setPlanning(true)` re-rendered `CourseScreen`, which rendered `List`,
which rendered both rows, with the same sessions as before. That is **the re-render nobody asked
for**. Tick Wednesday's session:

```
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet --do 'click checkbox Wed 21 Oct · 40 min'
drawn: row s1 (mount)
drawn: row s2 (mount)
-- click checkbox Wed 21 Oct · 40 min
drawn: row s1 (update)
drawn: row s2 (update)
drawn: row s1 (update)
drawn: row s2 (update)
```

**Each row was drawn twice**: the planner's state changed twice while the change went to the server
and came back, and each change re-rendered the whole screen. Monday's row was drawn twice although
nothing about Monday changed.

None of this is wrong, and on this screen none of it is slow: two rows are nothing. The same shape
on a list of five hundred rows, or rows that each draw a chart, is where it starts to matter, and the
profiler is how you would know which case you are in.
