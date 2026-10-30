#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 16's captures.sh
#
# Starts from ~/planner as lesson 16 left it (lessons 15 and 16 changed only
# ~/planner-next). What is STAGED rather than typed: the files ana wrote, put
# below and shown in the lesson; the API server and Vite's servers, which ana
# runs in terminals of their own and the script starts in the background;
# data/planner.json, deleted before each demonstration so that each starts from
# the seed data; and the page's date, Wednesday 21 October 2026, set with
# --today.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-epeh02ne
U=http://localhost:5173
T='--today 2026-10-21'
api_start() { lab exec ana "cd ~/planner && (DELAY=${1:-0} setsid node server/api.mjs > /tmp/api.out 2>&1 < /dev/null & echo \$! > /tmp/api.pid)"; sleep 1; }
api_stop() { lab exec ana 'kill $(cat /tmp/api.pid) 2>/dev/null; pkill -u ana -f server/api.mjs; rm -f /tmp/api.pid' > /dev/null 2>&1; sleep 0.5; }
fresh() { lab exec ana 'rm -f ~/planner/data/planner.json'; }
fresh; api_start

block install
on 'npm install react-router@8.5.0'

block router
put src/queryClient.ts <<'TS'
import { QueryClient } from '@tanstack/react-query'

// The one cache, shared by the components and by the router's loaders.
export const queryClient = new QueryClient()
TS
put src/usePlanner.ts <<'TS'
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
TS
put src/Root.tsx <<'TSX'
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
TSX
on 'mv src/App.tsx src/WeekScreen.tsx'
put src/WeekScreen.tsx <<'TSX'
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
TSX
put src/CourseList.tsx <<'TSX'
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
TSX
put src/CourseCard.tsx <<'TSX'
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
TSX
put src/courseLoader.ts <<'TS'
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
TS
put src/RouteError.tsx <<'TSX'
import { isRouteErrorResponse, Link, useRouteError } from 'react-router'

export function RouteError() {
  const error = useRouteError()
  const message = isRouteErrorResponse(error)
    ? `${error.status}: ${error.data}`
    : error instanceof Error
      ? error.message
      : 'Something went wrong.'
  return (
    <main>
      <h1>Study planner</h1>
      <p role="alert">{message}</p>
      <Link to="/">Back to this week</Link>
    </main>
  )
}
TSX
put src/main.tsx <<'TSX'
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
TSX
put src/CourseScreen.tsx <<'TSX'
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
TSX
block router-check
on 'npm run lint && npx tsc -b && echo no errors'
serve 5173 npm run dev
block home
on "look $U/ $T | sed -n '/region \"Courses\"/,\$p' | head -n 8"
block deep
on "look $U/courses/spanish $T"
block click
on "look $U/ $T --network --do 'click link Statistics' | grep -E 'CourseScreen|api|^-- |heading'"
block back
on "look $U/courses/statistics $T --do 'click link Back to courses' | grep -E 'heading'"
block week-before
on "look '$U/?week=2026-10-12' $T | grep -E 'Week of|minutes done'"

block week-hook
put src/useWeek.ts <<'TS'
import { useCallback, useEffect } from 'react'
import { useSearchParams } from 'react-router'
import { addDays, formatWeek, mondayOf, today } from './week'

const DAY = /^\d{4}-\d\d-\d\d$/

// The week on screen lives in the address, as ?week=YYYY-MM-DD, so that a link,
// a bookmark or a reload shows the same week.
export function useWeek() {
  const [params, setParams] = useSearchParams()
  const asked = params.get('week')
  const monday = mondayOf(asked && DAY.test(asked) ? asked : today())
  const setMonday = useCallback((m: string) => setParams({ week: m }), [setParams])

  useEffect(() => {
    document.title = `Week of ${formatWeek(monday)} · Study planner`
  }, [monday])

  useEffect(() => {
    function onKey(event: KeyboardEvent) {
      if (event.target instanceof HTMLInputElement) return
      if (event.key === 'ArrowLeft') setMonday(addDays(monday, -7))
      if (event.key === 'ArrowRight') setMonday(addDays(monday, 7))
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [monday, setMonday])

  return [monday, setMonday] as const
}
TS
on 'npm run lint && npx tsc -b && echo no errors'
block week-url
on "look '$U/?week=2026-10-12' $T | grep -E 'Week of|minutes done'"
on "look $U/ $T --do 'press ArrowLeft' | grep -E 'Week of|minutes done'"

block guard
on "look $U/courses/latin $T"
on "look $U/no/such/page $T"

block split
stop
on 'npm run build | grep -E "assets|built"'
serve 4173 npm run preview
on "look http://localhost:4173/ $T --network --do 'click link Organic chemistry' | grep -E 'assets|api|^-- |heading'"
stop

api_stop; fresh
lab save after-$(basename "$PWD")
finish
