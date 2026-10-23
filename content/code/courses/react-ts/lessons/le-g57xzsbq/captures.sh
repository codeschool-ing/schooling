#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 9's captures.sh
#
# Starts from ~/planner as lesson 9 left it. What is STAGED rather than typed:
# the files ana wrote, put below and shown in the lesson, one form replacing
# the last; and the page's date, Wednesday 21 October 2026, set with --today.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-epvwj20r
L='look http://localhost:5173/ --today 2026-10-21'
OPEN="--do 'click button Statistics'"
LIST="sed -n '/list:/,/listitem/!d; /list:/,\$p'"

put src/usePlanner.ts <<'TS'
import { useCallback, useEffect, useState } from 'react'
import type { Course, Session } from './types'

type Status = 'loading' | 'ready' | 'failed'
export type NewSession = Pick<Session, 'course' | 'date' | 'minutes'>

export function usePlanner() {
  const [courses, setCourses] = useState<Course[]>([])
  const [sessions, setSessions] = useState<Session[]>([])
  const [status, setStatus] = useState<Status>('loading')

  useEffect(() => {
    let ignore = false
    fetch('/courses.json')
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.json()
      })
      .then((data: { courses: Course[]; sessions: Session[] }) => {
        if (ignore) return
        setCourses(data.courses)
        setSessions(data.sessions)
        setStatus('ready')
      })
      .catch((error) => {
        if (ignore) return
        console.error('could not load the planner:', error.message)
        setStatus('failed')
      })
    return () => {
      ignore = true
    }
  }, [])

  const toggleDone = useCallback((id: string) => {
    setSessions((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }, [])

  const addSession = useCallback((session: NewSession) => {
    setSessions((all) => [...all, { ...session, id: crypto.randomUUID(), done: false }])
  }, [])

  return { status, courses, sessions, toggleDone, addSession }
}
TS
put src/AddSessionForm.tsx <<'TSX'
import { useState, type FormEvent } from 'react'
import { usePlannerContext } from './plannerContext'

export function AddSessionForm({ course }: { course: string }) {
  const { addSession } = usePlannerContext()
  const [date, setDate] = useState('')
  const [minutes, setMinutes] = useState('30')

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    addSession({ course, date, minutes: Number(minutes) })
    setDate('')
  }

  return (
    <form onSubmit={submit}>
      <h2>Add a session</h2>
      <label>
        Date
        <input type="date" value={date} onChange={(e) => setDate(e.target.value)} />
      </label>
      <label>
        Minutes
        <input type="number" value={minutes} onChange={(e) => setMinutes(e.target.value)} />
      </label>
      <button type="submit">Add session</button>
    </form>
  )
}
TSX
on "sed -i \"s|^import { usePlannerContext } from './plannerContext'\$|import { AddSessionForm } from './AddSessionForm'\\n&|; s|^    </>\$|      <AddSessionForm course={course.id} />\\n&|\" src/CourseScreen.tsx"
on 'grep -n AddSessionForm src/CourseScreen.tsx'
on 'npm run lint && npx tsc -b && echo no errors'
serve 5173 npm run dev

block controlled
on "$L $OPEN | sed -n '/list:/,\$p'"
on "$L $OPEN --do 'fill Date=2026-10-24' --do 'click button Add session' | sed -n '/list:/,/heading \"Add/p'"
on "$L $OPEN --do 'fill Date=2026-10-24' --do 'click button Add session' --do 'click button Back to courses' | grep minutes"

block empty-date
on "$L $OPEN --do 'click button Add session' | sed -n '/list:/,/heading \"Add/p'"

block uncontrolled
put src/AddSessionForm.tsx <<'TSX'
import type { FormEvent } from 'react'
import { usePlannerContext } from './plannerContext'

export function AddSessionForm({ course }: { course: string }) {
  const { addSession } = usePlannerContext()

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const form = new FormData(event.currentTarget)
    addSession({ course, date: String(form.get('date')), minutes: Number(form.get('minutes')) })
    event.currentTarget.reset()
  }

  return (
    <form onSubmit={submit}>
      <h2>Add a session</h2>
      <label>
        Date
        <input name="date" type="date" required />
      </label>
      <label>
        Minutes
        <input name="minutes" type="number" defaultValue={30} min={5} max={240} required />
      </label>
      <button type="submit">Add session</button>
    </form>
  )
}
TSX
on "$L $OPEN --do 'click button Add session' --quiet --html 'input:invalid'"
on "$L $OPEN --do 'fill Date=2026-10-24' --do 'fill Minutes=500' --do 'click button Add session' --quiet --html 'input:invalid'"
on "$L $OPEN --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' | sed -n '/list:/,/heading \"Add/p'"

block install
on 'npm install react-hook-form@7.91.0 zod@4.6.7 @hookform/resolvers@6.0.0'
on 'npm view react-hook-form dist-tags.latest'

block rhf
put src/sessionSchema.ts <<'TS'
import { z } from 'zod'

export const sessionSchema = z.object({
  date: z.iso.date({ error: 'Choose the day of the session.' }),
  minutes: z
    .number({ error: 'Enter how many minutes.' })
    .int('Use whole minutes.')
    .min(5, 'A session is at least 5 minutes.')
    .max(240, 'A session is at most 240 minutes.'),
})

export type SessionInput = z.infer<typeof sessionSchema>
TS
put src/AddSessionForm.tsx <<'TSX'
import { zodResolver } from '@hookform/resolvers/zod'
import { useId } from 'react'
import { useForm } from 'react-hook-form'
import { usePlannerContext } from './plannerContext'
import { sessionSchema, type SessionInput } from './sessionSchema'

export function AddSessionForm({ course }: { course: string }) {
  const { addSession } = usePlannerContext()
  const id = useId()
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<SessionInput>({
    resolver: zodResolver(sessionSchema),
    defaultValues: { date: '', minutes: 30 },
  })

  function submit(values: SessionInput) {
    addSession({ course, ...values })
    reset()
  }

  return (
    <form onSubmit={handleSubmit(submit)} noValidate>
      <h2>Add a session</h2>
      <label htmlFor={`${id}-date`}>Date</label>
      <input
        id={`${id}-date`}
        type="date"
        aria-invalid={errors.date ? true : undefined}
        aria-describedby={errors.date ? `${id}-date-error` : undefined}
        {...register('date')}
      />
      {errors.date && <p id={`${id}-date-error`}>{errors.date.message}</p>}
      <label htmlFor={`${id}-minutes`}>Minutes</label>
      <input
        id={`${id}-minutes`}
        type="number"
        aria-invalid={errors.minutes ? true : undefined}
        aria-describedby={errors.minutes ? `${id}-minutes-error` : undefined}
        {...register('minutes', { valueAsNumber: true })}
      />
      {errors.minutes && <p id={`${id}-minutes-error`}>{errors.minutes.message}</p>}
      <button type="submit">Add session</button>
    </form>
  )
}
TSX
on 'npm run lint && npx tsc -b && echo no errors'
on "$L $OPEN --do 'fill Minutes=500' --do 'click button Add session' | sed -n '/heading \"Add/,\$p'"
on "$L $OPEN --do 'fill Minutes=500' --do 'click button Add session' --quiet --html ':focus'"
on "$L $OPEN --do 'fill Minutes=500' --do 'click button Add session' --quiet --html 'input[aria-invalid]'"

block rhf-fixed
on "$L $OPEN --do 'fill Minutes=500' --do 'click button Add session' --do 'fill Date=2026-10-24' --do 'fill Minutes=45' | sed -n '/heading \"Add/,\$p'"
on "$L $OPEN --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' | sed -n '/list:/,\$p'"
on "$L $OPEN --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' --do 'click button Back to courses' | grep minutes"

lab save after-$(basename "$PWD")
finish
