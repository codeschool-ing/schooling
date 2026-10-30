---
title: A form whose action runs on the server
version: 1
---

**React 19 lets a form's `action` be a function.** With a Server Function, the form's fields arrive on
the server as a `FormData`, and what the function returns comes back to the page. The planner needs a
way to add a session, and the server is the right place to check one, because a form is not the only
thing that can send it.

The check uses Zod, as lesson 10 did, now installed in this project:

```
ana@dev:~/planner-next$ npm install zod@4.6.7 2>&1 | tail -n 1; grep zod package.json
found 0 vulnerabilities
    "zod": "4.6.7"
ana@dev:~/planner-next$ sed -i 's|      <SessionList sessions={thisWeek} courses={courses} />|&\n      <AddSession courses={courses} />|' app/Planner.tsx && sed -i "4i import { AddSession } from './AddSession'" app/Planner.tsx && sed -n '1,6p;34,36p' app/Planner.tsx
import Link from 'next/link'
import { getPlanner } from '@/lib/planner'
import { addDays, formatWeek, inWeek, minutes, mondayOf, today } from '@/lib/week'
import { AddSession } from './AddSession'
import { SessionList } from './SessionList'
import { WeekKeys } from './WeekKeys'
    </>
  )
}
ana@dev:~/planner-next$ npx tsc --noEmit && echo no errors
no errors
```

The two `sed` commands add the form to `Planner`, below the list, and its import at the top, and
`sed -n` prints both places. The new Server Function is in `app/actions.ts`, under `setDone`:

```ts
'use server'

import { refresh } from 'next/cache'
import { z } from 'zod'

// Server Functions. The browser calls them; they run here, on the server.

export async function setDone(id: string, done: boolean) {
  const response = await fetch(`http://localhost:3001/api/sessions/${id}`, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ done }),
  })
  if (!response.ok) throw new Error(`HTTP ${response.status} from the planner API`)
  refresh()
}

const sessionSchema = z.object({
  course: z.string().min(1, 'Choose a course.'),
  date: z.iso.date({ error: 'Choose the day of the session.' }),
  minutes: z.coerce
    .number({ error: 'Enter how many minutes.' })
    .int('Use whole minutes.')
    .min(5, 'A session is at least 5 minutes.')
    .max(240, 'A session is at most 240 minutes.'),
})

export type AddResult = { error?: string; added?: string }

export async function addSession(_previous: AddResult, form: FormData): Promise<AddResult> {
  const parsed = sessionSchema.safeParse(Object.fromEntries(form))
  if (!parsed.success) return { error: parsed.error.issues[0].message }

  const response = await fetch('http://localhost:3001/api/sessions', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(parsed.data),
  })
  if (!response.ok) return { error: 'The server did not keep the session.' }
  refresh()
  return { added: `Planned ${parsed.data.minutes} min on ${parsed.data.date}.` }
}
```

- **`(_previous, form)` is the shape `useActionState` calls it with**: the result of the last
  submission, and the form's data. The first argument is unused here, which the underscore says.
- **`Object.fromEntries(form)`** turns the fields into an object for Zod. Every field arrives as a
  string, which is why minutes use `z.coerce.number`.
- **It returns its errors instead of throwing them.** A validation failure is an expected answer, and
  the form should show it, not fall over.

The form is a Client Component, `app/AddSession.tsx`, because it shows what the last submission said:

```tsx
'use client'

import { useActionState } from 'react'
import { useFormStatus } from 'react-dom'
import type { Course } from '@/lib/types'
import { addSession } from './actions'

function Submit() {
  const { pending } = useFormStatus()
  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Adding…' : 'Add session'}
    </button>
  )
}

export function AddSession({ courses }: { courses: Course[] }) {
  const [result, action] = useActionState(addSession, {})
  return (
    <form action={action}>
      <h2>Plan a session</h2>
      <label htmlFor="course">Course</label>
      <select id="course" name="course">
        {courses.map((c) => (
          <option key={c.id} value={c.id}>
            {c.name}
          </option>
        ))}
      </select>
      <label htmlFor="date">Date</label>
      <input id="date" name="date" type="date" />
      <label htmlFor="minutes">Minutes</label>
      <input id="minutes" name="minutes" type="number" defaultValue={30} />
      <Submit />
      <p role="status">{result.error ?? result.added}</p>
    </form>
  )
}
```

- **`useActionState(addSession, {})`** returns the latest result, `{}` before the first submission,
  and an `action` to give the form. React calls `addSession` with the previous result and the form's
  data, and renders again with what it returns.
- **`useFormStatus` reads the state of the form it is inside**, which is why `Submit` is a component of
  its own: called in `AddSession`, which renders the form, it would see no form around it. While the
  submission runs, the button is disabled and says *Adding…*.
- **The result is in a `role="status"` region**, which a screen reader announces when its text
  changes, as lesson 14's message was.

Submitted empty:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'click button Add session' | sed -n '/Plan a session/,$p'
  - heading "Plan a session" [level=2]
  - text: Course
  - combobox "Course":
    - option "Statistics" [selected]
    - option "Spanish"
    - option "Organic chemistry"
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
  - status: Choose the day of the session.
- alert
```

The server's answer, in the status line. The course select starts on Statistics. Filled in properly:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' | grep -E 'minutes done|Sat|status|textbox|spinbutton'
    - paragraph: 80 of 240 minutes done
        - button "Sat 24 Oct · Statistics · 45 min"
  - textbox "Date"
  - spinbutton "Minutes": "30"
  - status: Planned 45 min on 2026-10-24.
```

Saturday's 45 minutes are in the list, the week plans 240, and the status says what was planned.
**And the form is empty again**: Date blank, Minutes back to 30. React 19 resets a form's fields when
its action finishes, so that a form that worked is ready for the next entry. It does so whatever the
action answered:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'fill Date=2026-10-24' --do 'fill Minutes=500' --do 'click button Add session' | grep -E 'status|textbox|spinbutton'
  - textbox "Date"
  - spinbutton "Minutes": "30"
  - status: A session is at most 240 minutes.
```

The error is right, and **the 500 and the date the user typed are gone**, so they have to type both
again to fix one of them. The usual cure is to return the submitted values in the result and use them as
the fields' `defaultValue`; lesson 10's React Hook Form, which keeps the values itself, does not have
the problem.
