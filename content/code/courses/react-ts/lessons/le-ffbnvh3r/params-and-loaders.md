---
title: A parameter, and the data it needs
version: 1
---

**A route with a parameter needs to turn the value into something to draw.** For `/courses/spanish`,
that means finding the course called `spanish`, and the route can do it before the screen is drawn, in a
**loader**: a function the router calls with the parameters, whose result the screen reads.

The loader needs the planner's data, and the data lives in React Query's cache. A loader runs outside
React, so it cannot call a hook; it needs the cache itself, which moves to a module of its own,
`src/queryClient.ts`:

```ts
import { QueryClient } from '@tanstack/react-query'

// The one cache, shared by the components and by the router's loaders.
export const queryClient = new QueryClient()
```

`main.tsx` imports it from there. The query itself is given a name in `src/usePlanner.ts`, so that the
hook and the loader ask for exactly the same thing:

```ts
import { queryOptions, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import type { Course, Session } from './types'

export type NewSession = Pick<Session, 'course' | 'date' | 'minutes'>
type Planner = { courses: Course[]; sessions: Session[] }
type Status = 'loading' | 'ready' | 'failed'

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(path, { ...init, headers: { 'content-type': 'application/json' } })
  if (!response.ok) throw new Error(`HTTP ${response.status} for ${path}`)
  return response.json()
}

export const plannerQuery = queryOptions({
  queryKey: ['planner'],
  queryFn: () => request<Planner>('/api/planner'),
})

export function usePlanner() {
  const queryClient = useQueryClient()
  const planner = useQuery(plannerQuery)
  const refresh = () => queryClient.invalidateQueries({ queryKey: ['planner'] })

  const toggle = useMutation({
    mutationFn: (id: string) => {
      const current = queryClient.getQueryData(plannerQuery.queryKey)
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

`queryOptions` bundles the key and the function, and **`plannerQuery` is now the one place they are
written**: `useQuery(plannerQuery)` in the hook, and `getQueryData(plannerQuery.queryKey)`, which knows
the type of the data as a bonus. Then the loader, `src/courseLoader.ts`:

```ts
import { data, type LoaderFunctionArgs } from 'react-router'
import { queryClient } from './queryClient'
import { plannerQuery } from './usePlanner'

// Runs before the course screen is drawn: the course named in the address has
// to exist, or the screen is never drawn at all.
export async function courseLoader({ params }: LoaderFunctionArgs) {
  const planner = await queryClient.ensureQueryData(plannerQuery)
  const course = planner.courses.find((c) => c.id === params.courseId)
  if (!course) throw data(`There is no course called “${params.courseId}”.`, { status: 404 })
  return course
}
```

- **`params.courseId`** is the `:courseId` of the route's path, as a string.
- **`ensureQueryData`** returns the cached planner if there is one, and fetches it if there is not, so
  coming from the week costs no request and opening the address directly costs one.
- **What it returns is what the screen gets**: the course. What it throws is the subject of a later
  section.

The course screen, `src/CourseScreen.tsx`, takes no props any more:

```tsx
import { useEffect, useRef, useState } from 'react'
import { Link, useLoaderData } from 'react-router'
import { AddSessionForm } from './AddSessionForm'
import type { courseLoader } from './courseLoader'
import { Dialog } from './Dialog'
import { usePlannerContext } from './plannerContext'
import { StatusMessage } from './StatusMessage'
import { formatDay } from './week'

export function CourseScreen() {
  const course = useLoaderData<typeof courseLoader>()
  const { sessions, toggleDone } = usePlannerContext()
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

`useLoaderData<typeof courseLoader>()` returns the loader's result with the loader's type, a `Course`.
*Back to courses* is a link to `/` instead of a button with a callback. Now open a course by its address,
without going through the week first:

```
ana@dev:~/planner$ look http://localhost:5173/courses/spanish --today 2026-10-21
- main:
  - link "Back to courses":
    - /url: /
  - heading "Spanish" [level=1]
  - list:
    - listitem:
      - checkbox "Tue 20 Oct · 30 min" [checked]
      - text: Tue 20 Oct · 30 min
    - listitem:
      - checkbox "Fri 23 Oct · 30 min"
      - text: Fri 23 Oct · 30 min
  - button "Plan a session"
- status
```

**Spanish, straight away.** On a first load the loader has to finish before anything can be drawn, and
**`hydrateFallbackElement`** in `main.tsx` is what shows meanwhile; without one, React Router warns in
the console that it had nothing to show. From the week, by the link:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network --do 'click link Statistics' | grep -E 'CourseScreen|api|^-- |heading'
net  GET /api/planner  200
-- click link Statistics
net  GET /src/CourseScreen.tsx  200
  - heading "Statistics" [level=1]
```

After the click, **no request for a page and none to the API**: the router changed the address itself,
the loader found the planner already in the cache, and the only thing fetched was the course screen's
code, which the next-but-one section explains. Back again:

```
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --do 'click link Back to courses' | grep -E 'heading'
  - heading "Study planner" [level=1]
      - heading "Statistics" [level=2]:
      - heading "Spanish" [level=2]:
      - heading "Organic chemistry" [level=2]:
```

The week, with its three cards. In a browser, the Back button does the same, because each screen now
has a place in the history.

```schooling-figure
{"svg": "<svg data-fig=\"routes\" viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"The route tree. The route at slash draws Root, with an ErrorBoundary, RouteError. Inside Root's Outlet go its children: the index route, WeekScreen, for slash itself, and courses slash colon courseId, whose loader, courseLoader, runs first and whose component, CourseScreen, is loaded lazily. Below, three addresses and what each draws: slash draws Root and WeekScreen; slash courses slash spanish draws Root and CourseScreen; slash courses slash latin draws RouteError.\"><rect x=\"250\" y=\"14\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">path: '/'</text><text x=\"360.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Root · ErrorBoundary</text><rect x=\"60\" y=\"100\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">index</text><text x=\"170.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">WeekScreen</text><rect x=\"400\" y=\"100\" width=\"280\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">courses/:courseId</text><text x=\"540.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">courseLoader → lazy CourseScreen</text><line x1=\"360\" y1=\"58\" x2=\"170\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"360\" y1=\"58\" x2=\"540\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;Outlet /&gt;</text><text x=\"60\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/</text><text x=\"240\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">→</text><text x=\"270\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Root + WeekScreen</text><text x=\"60\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/courses/spanish</text><text x=\"240\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">→</text><text x=\"270\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Root + CourseScreen</text><text x=\"60\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/courses/latin</text><text x=\"240\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">→</text><text x=\"270\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the loader throws 404 → RouteError</text></svg>", "caption": "The address picks a branch; the loader can refuse it before anything is drawn."}
```
