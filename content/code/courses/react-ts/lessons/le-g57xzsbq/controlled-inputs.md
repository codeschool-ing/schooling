---
title: A controlled form
version: 1
---

**A controlled input shows what React's state says, and asks React to change it on every
keystroke.** Lesson 4's checkboxes were controlled: `checked` came from the data, `onChange` asked
for a change. A text field works the same way with `value`, and that is the first way to write the
form lesson 1's second screen promised: a date, a number of minutes, and a button that adds the
session.

First the planner needs a way to add one. `usePlanner` grows `addSession`; the rest of the file is
lesson 7's:

```typescript
import { useCallback, useEffect, useState } from 'react'
import type { Course, Session } from './types'

type Status = 'loading' | 'ready' | 'failed'
export type NewSession = Pick<Session, 'course' | 'date' | 'minutes'>

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

  const addSession = useCallback((session: NewSession) => {
    setSessions((all) => [...all, { ...session, id: crypto.randomUUID(), done: false }])
  }, [])

  return { status, courses, sessions, toggleDone, addSession }
}
```

`NewSession` is a session without the two fields the planner fills in itself: the id, made by
`crypto.randomUUID()` at the moment the session is created, which lesson 8 said a key needs, and
`done`, which starts false. `Pick` builds that type from `Session`, so it cannot drift from it. The
array is replaced with `[...all, new]`, from lesson 4's table, never pushed to.

The form, `src/AddSessionForm.tsx`, reads `addSession` from the context of lesson 9:

```tsx
import { useState, type FormEvent } from 'react'
import { usePlannerContext } from './plannerContext'

export function AddSessionForm({ course }: { course: string }) {
  const { addSession } = usePlannerContext()
  const [date, setDate] = useState('')
  const [minutes, setMinutes] = useState('30')

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    addSession({ course, date, minutes: Number(minutes) })
    setDate('')
  }

  return (
    <form onSubmit={submit}>
      <h2>Add a session</h2>
      <label>
        Date
        <input type="date" value={date} onChange={(e) => setDate(e.target.value)} />
      </label>
      <label>
        Minutes
        <input type="number" value={minutes} onChange={(e) => setMinutes(e.target.value)} />
      </label>
      <button type="submit">Add session</button>
    </form>
  )
}
```

- **Each field has state and an `onChange`.** The minutes are kept as a string, because that is what
  an input holds; `Number(minutes)` converts once, at submit.
- **`event.preventDefault()`** stops the browser's own submission, which would reload the page and
  throw the whole app away. A `<form>` in React almost always starts with it.
- **A `<label>` wrapping the input** gives it its name: a screen reader announces "Date", and clicking
  the word focuses the field.

`CourseScreen` draws it under the list, and a `sed` adds the two lines:

```
ana@dev:~/planner$ sed -i "s|^import { usePlannerContext } from './plannerContext'$|import { AddSessionForm } from './AddSessionForm'\n&|; s|^    </>$|      <AddSessionForm course={course.id} />\n&|" src/CourseScreen.tsx
ana@dev:~/planner$ grep -n AddSessionForm src/CourseScreen.tsx
2:import { AddSessionForm } from './AddSessionForm'
44:      <AddSessionForm course={course.id} />
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 83ms on 16 files with 116 rules using 4 threads.
no errors
```

Open Statistics, and the form is under the two sessions. Fill in a date and press the button:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' | sed -n '/list:/,$p'
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
  - heading "Add a session" [level=2]
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Date=2026-10-24' --do 'click button Add session' | sed -n '/list:/,/heading "Add/p'
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
    - listitem:
      - checkbox "Sat 24 Oct · 30 min"
      - text: Sat 24 Oct · 30 min
  - heading "Add a session" [level=2]
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Date=2026-10-24' --do 'click button Add session' --do 'click button Back to courses' | grep minutes
    - paragraph: 80 of 225 minutes done
```

A third session, Saturday the 24th, 30 minutes from the field's starting value, sorted into place by
lesson 4's `sort`. Back on the first screen the week plans **225 minutes**: the 195 there were, and 30
more. The list, the totals and the form all read the same `sessions`, so nothing had to be told to
update.

## The form that accepts anything

Press the button without choosing a date:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click button Add session' | sed -n '/list:/,/heading "Add/p'
  - list:
    - listitem:
      - checkbox "Invalid Date · 30 min"
      - text: Invalid Date · 30 min
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
  - heading "Add a session" [level=2]
```

**"Invalid Date · 30 min", at the top of the list.** The form handed `addSession` an empty string,
the planner stored it, and `formatDay('')` made what it could of it; the empty string sorts before
every date. Nothing stopped it, because nothing checked. The next two sections add the checking, one
with the browser's help and one with a library's.
