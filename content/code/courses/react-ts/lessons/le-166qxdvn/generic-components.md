---
title: A component that takes anything
version: 1
---

**A generic is a type with a parameter**, filled in where it is used. `useState<string | null>`, for the open
course, was one in lesson 4, and `useLoaderData<typeof courseLoader>` in lesson 17. A component can have one too, and the
classic case is a list: the code that draws a list does not care what is in it, but the code that
draws each item does.

`src/List.tsx`:

```tsx
import type { ReactNode } from 'react'

type ListProps<T> = {
  items: T[]
  keyOf: (item: T) => string
  render: (item: T) => ReactNode
  empty: ReactNode
}

// A list of anything: the caller says how to key an item and how to draw one.
export function List<T>({ items, keyOf, render, empty }: ListProps<T>) {
  if (items.length === 0) return <p>{empty}</p>
  return (
    <ul>
      {items.map((item) => (
        <li key={keyOf(item)}>{render(item)}</li>
      ))}
    </ul>
  )
}
```

- **`<T>` after the name** declares the parameter. `ListProps<T>` uses it: `items` is a `T[]`, and
  `keyOf` and `render` each receive a `T`.
- **The component never looks inside a `T`.** It asks the caller for the key and for the drawing, which
  is what lets it take anything.
- **An empty list draws a sentence**, so a list drawn with it gets lesson 8's empty state without
  repeating it.

The course screen's list uses it, `src/CourseScreen.tsx`:

```tsx
import { useEffect, useRef, useState } from 'react'
import { Link, useLoaderData } from 'react-router'
import { AddSessionForm } from './AddSessionForm'
import type { courseLoader } from './courseLoader'
import { Dialog } from './Dialog'
import { List } from './List'
import { useReadyPlanner } from './plannerContext'
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
        render={(s) => (
          <label>
            <input type="checkbox" checked={s.done} onChange={() => toggleDone(s.id)} />
            {formatDay(s.date)} · {s.minutes} min
          </label>
        )}
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

No `<Session>` is written anywhere. **TypeScript infers `T` from `items`**: `sorted` is a `Session[]`,
so `T` is `Session`, and the `s` in `keyOf` and `render` is a `Session` without a word said.

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 82ms on 28 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 | sed -n '/list/,/Plan a session/p'
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
  - button "Plan a session"
```

The list is drawn as before, with its two checkboxes. To see that the inference is real, ask for a
field a session does not have:

```
ana@dev:~/planner$ sed -i 's/{formatDay(s.date)} · {s.minutes} min/{s.title}/' src/CourseScreen.tsx && npx tsc -b
src/CourseScreen.tsx(36,16): error TS2339: Property 'title' does not exist on type 'Session'.
ana@dev:~/planner$ sed -i 's/{s.title}/{formatDay(s.date)} · {s.minutes} min/' src/CourseScreen.tsx && npx tsc -b && echo no errors
no errors
```

**`Property 'title' does not exist on type 'Session'`**, about a parameter whose type was never
written. The second command put the line back.

Generic components earn their place where the same shape of UI is drawn for different data: lists,
tables, selects, autocompletes. They are not worth it for a component used once, and a type parameter
that nobody fills in differently is one more thing to read.
