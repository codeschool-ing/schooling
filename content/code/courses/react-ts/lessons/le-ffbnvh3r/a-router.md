---
title: Screens with addresses
version: 1
---

**The Vite planner has two screens and one address.** Since lesson 4, which screen shows has been a
piece of state, `openId`, so a course cannot be bookmarked, a reload always lands on the week, and the
browser's Back button leaves the planner instead of closing the course. A **router** fixes all three by
making the address the state: each screen has a path, and the router draws whichever one the address
names.

React has no router of its own; **React Router** is the one most React projects use, and the one this
lesson installs:

```
ana@dev:~/planner$ npm install react-router@8.5.0

added 3 packages, and audited 40 packages in 961ms

14 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

Version 8 has one package for the web, `react-router`, with `RouterProvider` in `react-router/dom`.
Older code imports from `react-router-dom`, a package version 8 no longer has. The library has three ways to be
used, and this lesson uses the middle one, **data mode**: the routes are a list of objects, made once,
and each can say what to load before it is drawn.

The router is made in `src/main.tsx`, and it replaces `<App />`:

```tsx
import { QueryClientProvider } from '@tanstack/react-query'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { createBrowserRouter } from 'react-router'
import { RouterProvider } from 'react-router/dom'
import './index.css'
import { courseLoader } from './courseLoader'
import { ErrorBoundary } from './ErrorBoundary'
import { PlannerProvider } from './PlannerProvider'
import { queryClient } from './queryClient'
import { Root } from './Root'
import { RouteError } from './RouteError'
import { WeekScreen } from './WeekScreen'

const router = createBrowserRouter([
  {
    path: '/',
    Component: Root,
    ErrorBoundary: RouteError,
    hydrateFallbackElement: <p>Loading the planner…</p>,
    children: [
      { index: true, Component: WeekScreen },
      {
        path: 'courses/:courseId',
        loader: courseLoader,
        lazy: async () => ({ Component: (await import('./CourseScreen')).CourseScreen }),
      },
    ],
  },
])

const crashed = (
  <main>
    <h1>Study planner</h1>
    <p role="alert">Something went wrong, and the planner stopped. Reload the page to start again.</p>
  </main>
)

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ErrorBoundary fallback={crashed}>
      <QueryClientProvider client={queryClient}>
        <PlannerProvider>
          <RouterProvider router={router} />
        </PlannerProvider>
      </QueryClientProvider>
    </ErrorBoundary>
  </StrictMode>,
)
```

Read the list as a tree. **The route at `/` is a layout**: its `Component`, `Root`, is drawn for every
address under `/`, and its `children` are drawn inside it. The **index route** is the child for `/`
itself, the week. **`courses/:courseId`** is the course screen, and `:courseId` is a parameter: it
matches any one segment, `/courses/spanish` or `/courses/statistics`, and the router hands the value to
the route. The other properties, `loader`, `lazy`, `ErrorBoundary` and `hydrateFallbackElement`, are the
subject of the sections that follow.

`src/Root.tsx`, the layout:

```tsx
import { Outlet } from 'react-router'
import { LoadFailed } from './LoadFailed'
import { usePlannerContext } from './plannerContext'

// Every screen of the planner is drawn inside this one, where <Outlet /> is.
export function Root() {
  const { status } = usePlannerContext()
  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <LoadFailed />
  return (
    <main>
      <Outlet />
    </main>
  )
}
```

**`<Outlet />` is where the matching child is drawn.** The loading and failure screens that `App` had
move here, so that every screen waits for the planner the same way. The week screen is what is left of
`App`, so the file is renamed:

```
ana@dev:~/planner$ mv src/App.tsx src/WeekScreen.tsx
```

and it loses its state for the open course, with the loading screens and the `<main>`:

```tsx
import { CourseList } from './CourseList'
import { usePlannerContext } from './plannerContext'
import { useWeek } from './useWeek'
import { inWeek } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

export function WeekScreen() {
  const [monday, setMonday] = useWeek()
  const { courses, sessions } = usePlannerContext()

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList key={monday} courses={courses} sessions={thisWeek} />
    </>
  )
}
```

The list no longer passes an `onOpen` down, `src/CourseList.tsx`:

```tsx
import { Card } from './Card'
import { CourseCard } from './CourseCard'
import { ErrorBoundary } from './ErrorBoundary'
import type { Course, Session } from './types'

type CourseListProps = {
  courses: Course[]
  sessions: Session[]
}

export function CourseList({ courses, sessions }: CourseListProps) {
  return (
    <section aria-label="Courses">
      {courses.map((course) => (
        <ErrorBoundary
          key={course.id}
          fallback={
            <Card title={course.name}>
              <p>This course could not be shown.</p>
            </Card>
          }
        >
          <CourseCard course={course} sessions={sessions.filter((s) => s.course === course.id)} />
        </ErrorBoundary>
      ))}
    </section>
  )
}
```

and each card's title becomes a **link**, `src/CourseCard.tsx`:

```tsx
import { Link } from 'react-router'
import { Card } from './Card'
import type { Course, Session } from './types'
import { formatDay, minutes } from './week'

type CourseCardProps = {
  course: Course
  sessions: Session[]
}

export function CourseCard({ course, sessions }: CourseCardProps) {
  const count = sessions.length
  const next = sessions.find((s) => !s.done)
  return (
    <Card title={<Link to={`/courses/${course.id}`}>{course.name}</Link>}>
      <p>
        {count} {count === 1 ? 'session' : 'sessions'} · {minutes(sessions)} min
      </p>
      <p>{next ? `Next: ${formatDay(next.date)}` : 'Nothing left this week'}</p>
    </Card>
  )
}
```

`<Link to>` draws an ordinary `<a href>`, so a link can be opened in a new tab, copied or bookmarked like
any other. When it is clicked normally, the router changes the address with the browser's history API
and draws the new screen, without asking the server for a page.

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 82ms on 27 files with 116 rules using 4 threads.
no errors
```

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 | sed -n '/region "Courses"/,$p' | head -n 8
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]:
        - link "Statistics":
          - /url: /courses/statistics
      - paragraph: 2 sessions · 90 min
      - paragraph: "Next: Wed 21 Oct"
    - article:
```

The course name is a link now, `/url: /courses/statistics`. The next section makes that address work
on its own.
