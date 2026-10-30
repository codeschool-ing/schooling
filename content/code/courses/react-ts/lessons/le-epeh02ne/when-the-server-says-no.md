---
title: When the server says no
version: 1
---

**The optimistic copy is only half of the promise; the other half is what happens when the server
refuses.** Here the API is stopped while the page is open, the way a server goes down while somebody
is using it, and the button is pressed after that:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'wait 4000' --do 'click button Wed 21 Oct · Statistics · 40 min' --do 'wait 1000' | grep -E 'error|minutes done|Statistics|heading'
-- click button Wed 21 Oct · Statistics · 40 min
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
- heading "This page couldn’t load" [level=1]
- paragraph: A server error occurred. Reload to try again.
```

**The whole page is gone.** `setDone` called `fetch`, which failed with nobody listening on port 3001,
so the function threw. **An error thrown inside an Action is thrown into the component tree**, as an
error during rendering would be, and it travels up to the nearest error boundary. This project has none
of its own yet, so Next.js's own took the whole page, as the planner's root boundary would have in
lesson 12.

A boundary would contain it, but a server that does not answer is not an exception in the sense lesson
12 meant: it is a known answer to a request, and the button should say so where it is. So `setDone`
stops throwing and starts answering, in `app/actions.ts`:

```ts
'use server'

import { refresh } from 'next/cache'
import { z } from 'zod'

// Server Functions. The browser calls them; they run here, on the server.

// Answers null when the change was kept, or a sentence saying why it was not.
export async function setDone(id: string, done: boolean): Promise<string | null> {
  try {
    const response = await fetch(`http://localhost:3001/api/sessions/${id}`, {
      method: 'PATCH',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ done }),
    })
    if (!response.ok) return `The server refused the change (HTTP ${response.status}).`
  } catch {
    return 'The server did not answer, so nothing was saved.'
  }
  refresh()
  return null
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

`null` when the change was kept, a sentence when it was not: a refusal from the API, with its status,
or no answer at all, caught. Only a kept change asks for `refresh()`. The toggle shows the sentence,
`app/SessionToggle.tsx`:

```tsx
'use client'

import { useOptimistic, useState, useTransition } from 'react'
import { setDone } from './actions'

type SessionToggleProps = {
  id: string
  done: boolean
  label: string
}

export function SessionToggle({ id, done, label }: SessionToggleProps) {
  const [shownDone, setShownDone] = useOptimistic(done)
  const [saving, startTransition] = useTransition()
  const [problem, setProblem] = useState<string | null>(null)

  function toggle() {
    startTransition(async () => {
      setShownDone(!shownDone)
      setProblem(await setDone(id, !shownDone))
    })
  }

  return (
    <>
      <button type="button" aria-pressed={shownDone} onClick={toggle}>
        {label}
        {saving && ' · saving…'}
      </button>
      {problem && <p role="alert">{problem}</p>}
    </>
  )
}
```

```
ana@dev:~/planner-next$ npx tsc --noEmit && echo no errors
no errors
```

The same failure again:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'wait 4000' --do 'click button Wed 21 Oct · Statistics · 40 min' --do 'wait 1000' | grep -E 'alert|minutes done|Statistics'
-- click button Wed 21 Oct · Statistics · 40 min
    - paragraph: 80 of 195 minutes done
        - button "Mon 19 Oct · Statistics · 50 min" [pressed]
        - button "Wed 21 Oct · Statistics · 40 min"
        - alert: The server did not answer, so nothing was saved.
    - option "Statistics" [selected]
- alert
```

**The page stayed, the button is not pressed, and an alert says why.** During the Action the button
showed *pressed*; when the Action finished with nothing saved, `useOptimistic` dropped its copy and
showed the real value, still not done. That is the half of the promise that makes optimism safe: **the
screen goes back to the truth on its own**, and the code only has to say what happened.

The alert sits next to the button rather than inside it, so it is announced once, when it appears, and
does not become part of the button's name.
