---
title: A way out when the server does not answer
version: 1
---

**A fallback is worth what it lets the user do next.** Lesson 11 left the planner, when the server did
not answer, on one sentence: *The planner could not be loaded*. True, and a dead end. A failed request
is the case where trying again can work, because the server may be back a moment later, so this is the
place for a button.

The query already knows how to try again: `useQuery` returns `refetch`, which runs the request again,
retries included, and `isFetching`, which is true while it runs. `usePlanner` passes both on, as
`retry` and `retrying`:

```ts
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import type { Course, Session } from './types'

export type NewSession = Pick<Session, 'course' | 'date' | 'minutes'>
type Planner = { courses: Course[]; sessions: Session[] }
type Status = 'loading' | 'ready' | 'failed'

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(path, { ...init, headers: { 'content-type': 'application/json' } })
  if (!response.ok) throw new Error(`HTTP ${response.status} for ${path}`)
  return response.json()
}

export function usePlanner() {
  const queryClient = useQueryClient()
  const planner = useQuery({
    queryKey: ['planner'],
    queryFn: () => request<Planner>('/api/planner'),
  })
  const refresh = () => queryClient.invalidateQueries({ queryKey: ['planner'] })

  const toggle = useMutation({
    mutationFn: (id: string) => {
      const current = queryClient.getQueryData<Planner>(['planner'])
      const session = current?.sessions.find((s) => s.id === id)
      return request(`/api/sessions/${id}`, {
        method: 'PATCH',
        body: JSON.stringify({ done: !session?.done }),
      })
    },
    onSuccess: refresh,
  })
  const add = useMutation({
    mutationFn: (session: NewSession) =>
      request('/api/sessions', { method: 'POST', body: JSON.stringify(session) }),
    onSuccess: refresh,
  })

  const status: Status = planner.isPending ? 'loading' : planner.isError ? 'failed' : 'ready'
  return {
    status,
    retrying: planner.isFetching,
    retry: planner.refetch,
    courses: planner.data?.courses ?? [],
    sessions: planner.data?.sessions ?? [],
    toggleDone: toggle.mutate,
    addSession: add.mutate,
  }
}
```

The screen for the failure is a component of its own, `src/LoadFailed.tsx`:

```tsx
import { usePlannerContext } from './plannerContext'

export function LoadFailed() {
  const { retry, retrying } = usePlannerContext()
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

- The sentence says what happened in words a user can act on. *The server did not answer* tells them
  the problem is not on their side, and it is the only thing this code knows for certain.
- `role="alert"` sits on the message and not on the button, so a screen reader announces the sentence
  when it appears and does not read a button out as part of an announcement.
- While the request runs, the button says *Trying again…* and is disabled, so a second click cannot
  start a second request, and a user can see that something is happening.
- `onClick={() => retry()}` and not `onClick={retry}`: the arrow keeps the click event from being
  passed to `refetch`, which takes an object of options as its argument.

`App.tsx` changes in two places, the import and the line that drew the alert, and two `sed` commands
make both. `head` shows the result:

```
ana@dev:~/planner$ sed -i 's|return <p role="alert">The planner could not be loaded.</p>|return <LoadFailed />|' src/App.tsx && sed -i "3a import { LoadFailed } from './LoadFailed'" src/App.tsx && head -n 18 src/App.tsx
import { useState } from 'react'
import { CourseList } from './CourseList'
import { CourseScreen } from './CourseScreen'
import { LoadFailed } from './LoadFailed'
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
  if (status === 'failed') return <LoadFailed />
```

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 57ms on 20 files with 116 rules using 4 threads.
no errors
```

Stop the API server and open the page:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'wait 9000'
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
-- wait 9000
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
[error] Failed to load resource: the server responded with a status of 502 (Bad Gateway)
- main:
  - heading "Study planner" [level=1]
  - alert:
    - paragraph: The planner could not be loaded. The server did not answer.
  - button "Try again"
```

The four tries from lesson 11, and then the new screen, with the sentence inside the alert and the
button after it. Now the full sequence: the same page, with the API server started again twelve
seconds after the page opened, while the alert is on the screen, and then the button pressed:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network --do 'wait 9000' --do 'wait 4000' --do 'click button Try again' | grep -E 'api|^-- |alert|Try|paragraph'
net  GET /api/planner  502
-- wait 9000
net  GET /api/planner  502
net  GET /api/planner  502
net  GET /api/planner  502
-- wait 4000
-- click button Try again
net  GET /api/planner  200
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
      - paragraph: 2 sessions · 90 min
      - paragraph: "Next: Wed 21 Oct"
      - paragraph: 2 sessions · 60 min
      - paragraph: "Next: Fri 23 Oct"
      - paragraph: 1 session · 45 min
      - paragraph: "Next: Thu 22 Oct"
```

Four `502`s while the server was down, then nothing until the click, then **one `200` and the whole
planner**. The user has not reloaded anything, has lost nothing, and did not have to know what a
reload is.

This failure is not an error boundary's business, and the difference is worth keeping straight. A
request that fails is an expected event: the query reports it as `isError`, and the component that
asked draws the screen for it. A boundary is for what nobody expected, an exception in the middle of a
render. React Query can be told to throw its errors into the nearest boundary, with the
`throwOnError` option, and some projects prefer one place for every failure. But then the boundary's
fallback is the screen that needs a retry button, and it has to be told how to reset the query too.
