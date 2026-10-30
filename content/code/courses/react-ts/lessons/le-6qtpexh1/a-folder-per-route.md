---
title: A folder per route
version: 1
---

**In Next.js, the folders under `app/` are the routes.** Lesson 17 wrote React Router's routes as a
list in `main.tsx`; here the list is the file system. `app/page.tsx` is `/`, and a page for each course
goes in `app/courses/[courseId]/page.tsx`: the square brackets make the folder a **dynamic segment**,
the same idea as `:courseId`, and the value arrives in `params`.

```tsx
import Link from 'next/link'
import { notFound } from 'next/navigation'
import { getPlanner } from '@/lib/planner'
import { formatDay, minutes } from '@/lib/week'

export default async function CoursePage({ params }: PageProps<'/courses/[courseId]'>) {
  const { courseId } = await params
  const { courses, sessions } = await getPlanner()
  const course = courses.find((c) => c.id === courseId)
  if (!course) notFound()

  const own = sessions
    .filter((s) => s.course === course.id)
    .sort((a, b) => a.date.localeCompare(b.date))
  const done = own.filter((s) => s.done)
  return (
    <main>
      <Link href="/">Back to the week</Link>
      <h1>{course.name}</h1>
      <p>
        {minutes(done)} of {minutes(own)} minutes done
      </p>
      <ul>
        {own.map((s) => (
          <li key={s.id}>
            {formatDay(s.date)} · {s.minutes} min{s.done && ' · done'}
          </li>
        ))}
      </ul>
    </main>
  )
}
```

- **`params` is a promise**, like `searchParams` in lesson 15, and `PageProps<'/courses/[courseId]'>`
  types it from the folder's name: `courseId` is a string.
- **`notFound()`** stops the page and shows a not-found page instead; the next section gives it one of
  its own.
- It is a Server Component, so it fetches and draws on the server, as `Planner` does.

```
ana@dev:~/planner-next$ look http://localhost:3000/courses/chemistry --today 2026-10-21 | grep -v '^$'
[HMR] connected
[error] Error: Route "/courses/[courseId]": Next.js encountered uncached data during prerendering.
`fetch(...)` or `connection()` accessed outside of `<Suspense>` prevents the route from being prerendered, blocking the page load and leading to a slower user experience.
Ways to fix this:
  - [stream] Provide a placeholder with `<Suspense fallback={...}>` around the data access
  - [cache] Cache the data access with `"use cache"` (does not apply to `connection()`)
  - [block] Set `export const instant = false` to allow a blocking route
Learn more: https://nextjs.org/docs/messages/blocking-prerender-dynamic
    at getPlanner (about://React/Server/file:///home/ana/planner-next/.next/dev/server/chunks/ssr/%255Broot-of-the-server%255D__0flwiz7kep8nq._.js?20:299:28)
    at CoursePage (about://React/Server/file:///home/ana/planner-next/.next/dev/server/chunks/ssr/%5Broot-of-the-server%5D__0he2qxgnwk032._.js?21:23:170)
    at resolveErrorDev (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2029:105)
    at getOutlinedModel (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:1568:28)
    at parseModelString (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:1688:50)
    at reviveModel (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2634:66)
    at reviveModel (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2637:61)
    at reviveModel (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2716:112)
    at parseModel (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2629:16)
    at initializeModelChunk (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:1141:25)
    at resolveModelChunk (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:1039:43)
    at processFullStringRow (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2585:371)
    at processFullBinaryRow (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2507:9)
    at processBinaryChunk (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2614:221)
    at progress (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2801:13)
- main:
  - link "Back to the week":
    - /url: /
  - heading "Organic chemistry" [level=1]
  - paragraph: 60 of 105 minutes done
  - list:
    - listitem: Wed 14 Oct · 60 min · done
    - listitem: Thu 22 Oct · 45 min
- alert
```

The page drew, with chemistry's 60 of 105 minutes, and Cache Components objected again, as in lesson
15: the `fetch` has nothing to show while it waits. Lesson 15 wrapped the planner in `Suspense` by
hand. In a route folder there is a file for that, **`loading.tsx`**:

```tsx
export default function Loading() {
  return <p>Loading the course…</p>
}
```

Next.js wraps the folder's page in a `Suspense` whose fallback is this component, so it is shown
while the page's data arrives, and on a navigation to the page while the next one is fetched.

```
ana@dev:~/planner-next$ look http://localhost:3000/courses/chemistry --today 2026-10-21 | grep -v '^$'
[HMR] connected
- main:
  - link "Back to the week":
    - /url: /
  - heading "Organic chemistry" [level=1]
  - paragraph: 60 of 105 minutes done
  - list:
    - listitem: Wed 14 Oct · 60 min · done
    - listitem: Thu 22 Oct · 45 min
- alert
```

No complaint now. The week links to each course, from a new list in `app/Planner.tsx`:

```tsx
import Link from 'next/link'
import { getPlanner } from '@/lib/planner'
import { addDays, formatWeek, inWeek, minutes, mondayOf, today } from '@/lib/week'
import { AddSession } from './AddSession'
import { SessionList } from './SessionList'
import { WeekKeys } from './WeekKeys'

type PlannerProps = {
  searchParams: PageProps<'/'>['searchParams']
}

export async function Planner({ searchParams }: PlannerProps) {
  const { week } = await searchParams
  const monday = mondayOf(typeof week === 'string' ? week : today())
  const { courses, sessions } = await getPlanner()

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  const done = thisWeek.filter((s) => s.done)
  return (
    <>
      <nav aria-label="Week">
        <Link href={`/?week=${addDays(monday, -7)}`}>Previous week</Link>{' '}
        <Link href={`/?week=${addDays(monday, 7)}`}>Next week</Link>
      </nav>
      <WeekKeys monday={monday} />
      <section aria-label="This week">
        <p>Week of {formatWeek(monday)}</p>
        <p>
          {minutes(done)} of {minutes(thisWeek)} minutes done
        </p>
      </section>
      <nav aria-label="Courses">
        <ul>
          {courses.map((c) => (
            <li key={c.id}>
              <Link href={`/courses/${c.id}`}>{c.name}</Link>
            </li>
          ))}
        </ul>
      </nav>
      <SessionList sessions={thisWeek} courses={courses} />
      <AddSession courses={courses} />
    </>
  )
}
```

```
ana@dev:~/planner-next$ look 'http://localhost:3000/?week=2026-10-19' --today 2026-10-21 --network --do 'click link Spanish' | grep -E 'GET /courses|_rsc|^-- |heading|paragraph'
-- click link Spanish
net  GET /courses/spanish?_rsc=bDxByZpqNar9PdVL  200
  - heading "Spanish" [level=1]
  - paragraph: 30 of 60 minutes done
```

`next/link` did what React Router's `Link` did: the click fetched `/courses/spanish` as Server
Component data, the `_rsc` request from lesson 15, and drew the course without loading a page.

**The special files** of a route folder, each of which Next.js wires up by its name:

| file | what it is |
|---|---|
| `page.tsx` | the route's screen; a folder without one is not a route |
| `layout.tsx` | drawn around the pages below it, and kept across navigations between them |
| `loading.tsx` | the fallback of a `Suspense` around the page |
| `not-found.tsx` | what `notFound()` shows |
| `error.tsx` | an error boundary around the page |
