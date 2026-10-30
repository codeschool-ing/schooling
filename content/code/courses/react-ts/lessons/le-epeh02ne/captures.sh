#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 15's captures.sh
#
# Starts from ~/planner and ~/planner-next as lesson 15 left them. What is
# STAGED rather than typed: the files ana wrote, put below and shown in the
# lesson; the API server and the Next.js development server, which ana runs in
# terminals of their own and the script starts in the background (the API with
# DELAY=2000, or stopped, where the lesson says so); data/planner.json, deleted
# before each demonstration so that each starts from the seed data; and the
# page's date, Wednesday 21 October 2026, set with --today.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-6hqp8bdv
CWD=planner-next
N='look http://localhost:3000/?week=2026-10-19 --today 2026-10-21'
api_start() { lab exec ana "cd ~/planner && (DELAY=${1:-0} setsid node server/api.mjs > /tmp/api.out 2>&1 < /dev/null & echo \$! > /tmp/api.pid)"; sleep 1; }
api_stop() { lab exec ana 'kill $(cat /tmp/api.pid) 2>/dev/null; pkill -u ana -f server/api.mjs; rm -f /tmp/api.pid' > /dev/null 2>&1; sleep 0.5; }
fresh() { lab exec ana 'rm -f ~/planner/data/planner.json'; }
# A Server Function the page started keeps running on the server after look
# closes the page; with DELAY=2000 it lands seconds later. Wait for it before
# the next demonstration starts from the seed data.
settle() { sleep 6; }
fresh; api_start

block server-fn
put app/actions.ts <<'TS'
'use server'

import { refresh } from 'next/cache'

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
TS
put app/SessionList.tsx <<'TSX'
import type { Course, Session } from '@/lib/types'
import { formatDay } from '@/lib/week'
import { setDone } from './actions'

type SessionListProps = {
  sessions: Session[]
  courses: Course[]
}

export function SessionList({ sessions, courses }: SessionListProps) {
  const name = (id: string) => courses.find((c) => c.id === id)?.name ?? id
  const sorted = [...sessions].sort((a, b) => a.date.localeCompare(b.date))
  return (
    <section aria-labelledby="sessions-heading">
      <h2 id="sessions-heading">Sessions this week</h2>
      <ul>
        {sorted.map((s) => (
          <li key={s.id}>
            <form action={setDone.bind(null, s.id, !s.done)}>
              <button type="submit" aria-pressed={s.done}>
                {formatDay(s.date)} · {name(s.course)} · {s.minutes} min
              </button>
            </form>
          </li>
        ))}
      </ul>
    </section>
  )
}
TSX
put app/Planner.tsx <<'TSX'
import Link from 'next/link'
import { getPlanner } from '@/lib/planner'
import { addDays, formatWeek, inWeek, minutes, mondayOf, today } from '@/lib/week'
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
      <SessionList sessions={thisWeek} courses={courses} />
    </>
  )
}
TSX
on 'npx tsc --noEmit && echo no errors'
serve 3000 npm run dev
block server-fn-look
on "$N | sed -n '/This week/,\$p'"
block server-fn-click
on "$N --network --do 'click button Wed 21 Oct · Statistics · 40 min' | grep -E 'POST|minutes done|Statistics'"
block server-fn-api
echo '----- the API terminal'
lab exec ana 'cat /tmp/api.out'

block add
lab exec ana 'cd ~/planner-next && npm install zod@4.6.7' > /dev/null 2>&1
on 'npm install zod@4.6.7 2>&1 | tail -n 1; grep zod package.json'
put app/actions.ts <<'TS'
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
TS
put app/AddSession.tsx <<'TSX'
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
TSX
on "sed -i 's|      <SessionList sessions={thisWeek} courses={courses} />|&\\n      <AddSession courses={courses} />|' app/Planner.tsx && sed -i \"4i import { AddSession } from './AddSession'\" app/Planner.tsx && sed -n '1,6p;34,36p' app/Planner.tsx"
on 'npx tsc --noEmit && echo no errors'
block add-empty
fresh
on "$N --do 'click button Add session' | sed -n '/Plan a session/,\$p'"
block add-ok
fresh
on "$N --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' | grep -E 'minutes done|Sat|status|textbox|spinbutton'"
block add-bad
fresh
on "$N --do 'fill Date=2026-10-24' --do 'fill Minutes=500' --do 'click button Add session' | grep -E 'status|textbox|spinbutton'"

block slow
stop
api_stop; fresh; api_start 2000
serve 3000 npm run dev
run "curl -s -o /dev/null 'http://localhost:3000/?week=2026-10-19'"
on "$N --do 'click button Wed 21 Oct · Statistics · 40 min' | grep -E 'minutes done|Statistics'"
settle

block toggle
put app/SessionToggle.tsx <<'TSX'
'use client'

import { useOptimistic, useTransition } from 'react'
import { setDone } from './actions'

type SessionToggleProps = {
  id: string
  done: boolean
  label: string
}

export function SessionToggle({ id, done, label }: SessionToggleProps) {
  const [shownDone, setShownDone] = useOptimistic(done)
  const [saving, startTransition] = useTransition()

  function toggle() {
    startTransition(async () => {
      setShownDone(!shownDone)
      await setDone(id, !shownDone)
    })
  }

  return (
    <button type="button" aria-pressed={shownDone} onClick={toggle}>
      {label}
      {saving && ' · saving…'}
    </button>
  )
}
TSX
put app/SessionList.tsx <<'TSX'
import type { Course, Session } from '@/lib/types'
import { formatDay } from '@/lib/week'
import { SessionToggle } from './SessionToggle'

type SessionListProps = {
  sessions: Session[]
  courses: Course[]
}

export function SessionList({ sessions, courses }: SessionListProps) {
  const name = (id: string) => courses.find((c) => c.id === id)?.name ?? id
  const sorted = [...sessions].sort((a, b) => a.date.localeCompare(b.date))
  return (
    <section aria-labelledby="sessions-heading">
      <h2 id="sessions-heading">Sessions this week</h2>
      <ul>
        {sorted.map((s) => (
          <li key={s.id}>
            <SessionToggle
              id={s.id}
              done={s.done}
              label={`${formatDay(s.date)} · ${name(s.course)} · ${s.minutes} min`}
            />
          </li>
        ))}
      </ul>
    </section>
  )
}
TSX
on 'npx tsc --noEmit && echo no errors'
block toggle-during
fresh
run "curl -s -o /dev/null 'http://localhost:3000/?week=2026-10-19'"
on "$N --do 'click button Wed 21 Oct · Statistics · 40 min' | grep -E 'minutes done|Statistics'"
settle
block toggle-after
fresh
on "$N --do 'click button Wed 21 Oct · Statistics · 40 min' --do 'wait 6000' | grep -E 'minutes done|Statistics'"
settle

block toggle-fails
fresh
(sleep 3; lab exec ana 'pkill -f server/api.mjs' > /dev/null 2>&1) &
on "$N --do 'wait 4000' --do 'click button Wed 21 Oct · Statistics · 40 min' --do 'wait 1000' | grep -E 'error|minutes done|Statistics|heading'"
wait

block answer
put app/actions.ts <<'TS'
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
TS
put app/SessionToggle.tsx <<'TSX'
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
TSX
on 'npx tsc --noEmit && echo no errors'
api_start 2000
block answer-fails
fresh
(sleep 3; lab exec ana 'pkill -f server/api.mjs' > /dev/null 2>&1) &
on "$N --do 'wait 4000' --do 'click button Wed 21 Oct · Statistics · 40 min' --do 'wait 1000' | grep -E 'alert|minutes done|Statistics'"
wait
stop

api_stop; fresh
lab save after-$(basename "$(pwd)")
finish
