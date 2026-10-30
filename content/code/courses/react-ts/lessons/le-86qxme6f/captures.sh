#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 11's captures.sh
#
# Starts from ~/planner as lesson 11 left it. What is STAGED rather than typed:
# the files ana wrote, put below and shown in the lesson; the API server, which
# ana keeps running in a terminal of its own and the script starts in the
# background; data/planner.json, deleted before each demonstration so that each
# starts from the seed data; and the page's date, Wednesday 21 October 2026, set
# with --today. In the last demonstration the API is started twelve seconds
# after the page is opened, standing in for ana starting it by hand while the
# alert is on the screen.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-qrh7513t
L='look http://localhost:5173/ --today 2026-10-21'
TICK="--do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses'"
api_start() { lab exec ana 'cd ~/planner && (setsid node server/api.mjs > /tmp/api.out 2>&1 < /dev/null & echo $! > /tmp/api.pid)'; sleep 1; }
api_later() { lab exec ana 'cd ~/planner && (setsid sh -c "sleep 12; exec node server/api.mjs" > /tmp/api.out 2>&1 < /dev/null & echo $! > /tmp/api.pid)'; }
api_stop() { lab exec ana 'kill $(cat /tmp/api.pid) 2>/dev/null; pkill -u ana -f server/api.mjs; rm -f /tmp/api.pid' > /dev/null 2>&1; sleep 0.5; }
fresh() { lab exec ana 'rm -f ~/planner/data/planner.json'; }

block bug
put src/CourseCard.tsx <<'TSX'
import { Card } from './Card'
import type { Course, Session } from './types'
import { formatDay, minutes } from './week'

type CourseCardProps = {
  course: Course
  sessions: Session[]
  onOpen: (id: string) => void
}

export function CourseCard({ course, sessions, onOpen }: CourseCardProps) {
  const count = sessions.length
  const next = sessions.find((s) => !s.done)!
  const title = (
    <button type="button" onClick={() => onOpen(course.id)}>
      {course.name}
    </button>
  )
  return (
    <Card title={title}>
      <p>
        {count} {count === 1 ? 'session' : 'sessions'} · {minutes(sessions)} min
      </p>
      <p>Next: {formatDay(next.date)}</p>
    </Card>
  )
}
TSX
block bug-lint
on 'npm run lint && npx tsc -b && echo no errors'
fresh; api_start
serve 5173 npm run dev
block bug-ok
on "$L"
fresh
block bug-crash
on "$L $TICK --html '#root'"

block boundary
put src/ErrorBoundary.tsx <<'TSX'
import { Component, type ErrorInfo, type ReactNode } from 'react'

type ErrorBoundaryProps = {
  fallback: ReactNode
  children: ReactNode
}

type ErrorBoundaryState = { failed: boolean }

export class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  state: ErrorBoundaryState = { failed: false }

  static getDerivedStateFromError(): ErrorBoundaryState {
    return { failed: true }
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error(`ErrorBoundary: ${error.message}${info.componentStack}`)
  }

  render() {
    return this.state.failed ? this.props.fallback : this.props.children
  }
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
  onOpen: (id: string) => void
}

export function CourseList({ courses, sessions, onOpen }: CourseListProps) {
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
          <CourseCard
            course={course}
            sessions={sessions.filter((s) => s.course === course.id)}
            onOpen={onOpen}
          />
        </ErrorBoundary>
      ))}
    </section>
  )
}
TSX
block boundary-lint
on 'npm run lint && npx tsc -b && echo no errors'
# A fresh dev server, so that the stacks below name files without the ?t=
# timestamps Vite adds to a module it has hot-replaced.
stop; serve 5173 npm run dev
fresh
on "$L $TICK"

block reset
fresh
on "$L --do 'click button Previous week' --quiet | grep -c 'ErrorBoundary:'"
block reset-stuck
on "$L --do 'click button Previous week' --do 'click button Next week' | grep -E 'heading|paragraph'"
put src/App.tsx <<'TSX'
import { useState } from 'react'
import { CourseList } from './CourseList'
import { CourseScreen } from './CourseScreen'
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
  if (status === 'failed') return <p role="alert">The planner could not be loaded.</p>

  const open = courses.find((c) => c.id === openId)
  if (open) {
    return (
      <main>
        <CourseScreen course={open} onBack={() => setOpenId(null)} />
      </main>
    )
  }

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList key={monday} courses={courses} sessions={thisWeek} onOpen={setOpenId} />
    </main>
  )
}

export default App
TSX
block reset-ok
on "$L --do 'click button Previous week' --do 'click button Next week' | grep -E 'heading|paragraph'"

block root
put src/main.tsx <<'TSX'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { ErrorBoundary } from './ErrorBoundary'
import { PlannerProvider } from './PlannerProvider'

const queryClient = new QueryClient()

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
          <App />
        </PlannerProvider>
      </QueryClientProvider>
    </ErrorBoundary>
  </StrictMode>,
)
TSX
on 'npm run lint && npx tsc -b && echo no errors'

block fix
on "sed -i 's/(s) => !s.done)!/(s) => !s.done)/' src/CourseCard.tsx && npx tsc -b"
put src/CourseCard.tsx <<'TSX'
import { Card } from './Card'
import type { Course, Session } from './types'
import { formatDay, minutes } from './week'

type CourseCardProps = {
  course: Course
  sessions: Session[]
  onOpen: (id: string) => void
}

export function CourseCard({ course, sessions, onOpen }: CourseCardProps) {
  const count = sessions.length
  const next = sessions.find((s) => !s.done)
  const title = (
    <button type="button" onClick={() => onOpen(course.id)}>
      {course.name}
    </button>
  )
  return (
    <Card title={title}>
      <p>
        {count} {count === 1 ? 'session' : 'sessions'} · {minutes(sessions)} min
      </p>
      <p>{next ? `Next: ${formatDay(next.date)}` : 'Nothing left this week'}</p>
    </Card>
  )
}
TSX
block fix-lint
on 'npm run lint && npx tsc -b && echo no errors'
fresh
block fix-tick
on "$L $TICK | grep -E 'heading|paragraph'"
block fix-prev
on "$L --do 'click button Previous week' --quiet"

block retry
put src/usePlanner.ts <<'TS'
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
TS
put src/LoadFailed.tsx <<'TSX'
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
TSX
on "sed -i 's|return <p role=\"alert\">The planner could not be loaded.</p>|return <LoadFailed />|' src/App.tsx && sed -i \"3a import { LoadFailed } from './LoadFailed'\" src/App.tsx && head -n 18 src/App.tsx"
block retry-lint
on 'npm run lint && npx tsc -b && echo no errors'
api_stop; fresh
block retry-alert
on "$L --do 'wait 9000'"
api_later
block retry-ok
on "$L --network --do 'wait 9000' --do 'wait 4000' --do 'click button Try again' | grep -E 'api|^-- |alert|Try|paragraph'"

api_stop; fresh
stop
lab save after-$(basename "$PWD")
finish
