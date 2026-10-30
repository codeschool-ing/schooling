#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 18's captures.sh
#
# Works in ~/planner as lesson 17 left it (lesson 18 changed only
# ~/planner-next). What is STAGED rather than typed: the files ana wrote, put
# below and shown in the lesson; the API server and Vite's development server,
# which ana runs in terminals of their own and the script starts in the
# background; data/planner.json, deleted before each demonstration so that each
# starts from the seed data; and the page's date, Wednesday 21 October 2026, set
# with --today. The mistakes made on purpose are made with sed, typed, and
# undone the same way.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-6qtpexh1
U=http://localhost:5173
T='--today 2026-10-21'
api_start() { lab exec ana "cd ~/planner && (DELAY=${1:-0} setsid node server/api.mjs > /tmp/api.out 2>&1 < /dev/null & echo \$! > /tmp/api.pid)"; sleep 1; }
api_stop() { lab exec ana 'kill $(cat /tmp/api.pid) 2>/dev/null; pkill -u ana -f server/api.mjs; rm -f /tmp/api.pid' > /dev/null 2>&1; sleep 0.5; }
fresh() { lab exec ana 'rm -f ~/planner/data/planner.json'; }
fresh; api_start

block props
on "sed -i 's/<WeekNav monday={monday}/<WeekNav monday={19}/' src/WeekScreen.tsx && npx tsc -b"
on "sed -i 's/<WeekNav monday={19}/<WeekNav monday={monday}/' src/WeekScreen.tsx && sed -i 's/<WeekNav monday={monday} onChange={setMonday} \\/>/<WeekNav monday={monday} \\/>/' src/WeekScreen.tsx && npx tsc -b"
on "sed -i 's/<WeekNav monday={monday} \\/>/<WeekNav monday={monday} onChange={setMonday} \\/>/' src/WeekScreen.tsx && npx tsc -b && echo no errors"

block union
put src/usePlanner.ts <<'TS'
import {
  queryOptions,
  useMutation,
  useQuery,
  useQueryClient,
  type UseQueryResult,
} from '@tanstack/react-query'
import type { Course, Session } from './types'

export type NewSession = Pick<Session, 'course' | 'date' | 'minutes'>
type Planner = { courses: Course[]; sessions: Session[] }

// What the planner can be, one shape per status: there are courses only when
// it is ready, and a way to retry only when it failed.
export type PlannerState =
  | { status: 'loading' }
  | { status: 'failed'; retry: () => void; retrying: boolean }
  | { status: 'ready'; courses: Course[]; sessions: Session[] }

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(path, { ...init, headers: { 'content-type': 'application/json' } })
  if (!response.ok) throw new Error(`HTTP ${response.status} for ${path}`)
  return response.json()
}

export const plannerQuery = queryOptions({
  queryKey: ['planner'],
  queryFn: () => request<Planner>('/api/planner'),
})

function stateOf(planner: UseQueryResult<Planner>): PlannerState {
  if (planner.isPending) return { status: 'loading' }
  if (planner.isError) {
    return { status: 'failed', retry: planner.refetch, retrying: planner.isFetching }
  }
  return { status: 'ready', courses: planner.data.courses, sessions: planner.data.sessions }
}

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

  return { ...stateOf(planner), toggleDone: toggle.mutate, addSession: add.mutate }
}
TS
on 'npx tsc -b'

block narrow
put src/plannerContext.ts <<'TS'
import { createContext, use } from 'react'
import type { usePlanner } from './usePlanner'

export type Planner = ReturnType<typeof usePlanner>

export const PlannerContext = createContext<Planner | null>(null)

export function usePlannerContext(): Planner {
  const planner = use(PlannerContext)
  if (planner === null) {
    throw new Error('usePlannerContext must be called inside <PlannerProvider>')
  }
  return planner
}

// For the screens Root draws, which it draws only once the planner is ready.
export function useReadyPlanner() {
  const planner = usePlannerContext()
  if (planner.status !== 'ready') {
    throw new Error(`useReadyPlanner was called while the planner is ${planner.status}`)
  }
  return planner
}
TS
put src/LoadFailed.tsx <<'TSX'
type LoadFailedProps = {
  retry: () => void
  retrying: boolean
}

export function LoadFailed({ retry, retrying }: LoadFailedProps) {
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
put src/Root.tsx <<'TSX'
import { Outlet } from 'react-router'
import { LoadFailed } from './LoadFailed'
import { usePlannerContext } from './plannerContext'

// Every screen of the planner is drawn inside this one, where <Outlet /> is.
export function Root() {
  const planner = usePlannerContext()
  switch (planner.status) {
    case 'loading':
      return <p>Loading the planner…</p>
    case 'failed':
      return <LoadFailed retry={planner.retry} retrying={planner.retrying} />
    case 'ready':
      return (
        <main>
          <Outlet />
        </main>
      )
    default: {
      const unhandled: never = planner
      return unhandled
    }
  }
}
TSX
on "sed -i 's/usePlannerContext/useReadyPlanner/g' src/WeekScreen.tsx src/CourseScreen.tsx && grep -n 'ReadyPlanner' src/WeekScreen.tsx src/CourseScreen.tsx"
on 'npm run lint && npx tsc -b && echo no errors'
serve 5173 npm run dev
on "look $U/ $T | grep -E 'Week of|minutes done'"
api_stop
on "look $U/ $T --do 'wait 9000' | grep -E 'alert|paragraph|button'"
api_start

block never
on "sed -i \"s/  | { status: 'loading' }/  | { status: 'loading' }\\\\n  | { status: 'offline' }/\" src/usePlanner.ts && npx tsc -b"
on "sed -i \"/  | { status: 'offline' }/d\" src/usePlanner.ts && npx tsc -b && echo no errors"

block generic
put src/List.tsx <<'TSX'
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
TSX
put src/CourseScreen.tsx <<'TSX'
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
TSX
on 'npm run lint && npx tsc -b && echo no errors'
on "look $U/courses/statistics $T | sed -n '/list/,/Plan a session/p'"
block generic-wrong
on "sed -i 's/{formatDay(s.date)} · {s.minutes} min/{s.title}/' src/CourseScreen.tsx && npx tsc -b"
on "sed -i 's/{s.title}/{formatDay(s.date)} · {s.minutes} min/' src/CourseScreen.tsx && npx tsc -b && echo no errors"
stop

api_stop; fresh
lab save after-$(basename "$PWD")
finish
