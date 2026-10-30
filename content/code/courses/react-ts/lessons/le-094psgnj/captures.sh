#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 13's captures.sh
#
# Starts from ~/planner as lesson 13 left it. What is STAGED rather than typed:
# the files ana wrote, put below and shown in the lesson; the API server and the
# development server, which ana runs in terminals of their own and the script
# starts in the background; data/planner.json, deleted before each
# demonstration so that each starts from the seed data; and the page's date,
# Wednesday 21 October 2026, set with --today.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-f2jnb3yh
L='look http://localhost:5173/ --today 2026-10-21'
OPEN="--do 'click button Statistics' --do 'click button Plan a session'"
api_start() { lab exec ana 'cd ~/planner && (setsid node server/api.mjs > /tmp/api.out 2>&1 < /dev/null & echo $! > /tmp/api.pid)'; sleep 1; }
api_stop() { lab exec ana 'kill $(cat /tmp/api.pid) 2>/dev/null; pkill -u ana -f server/api.mjs; rm -f /tmp/api.pid' > /dev/null 2>&1; sleep 0.5; }
fresh() { lab exec ana 'rm -f ~/planner/data/planner.json'; }
fresh; api_start

block dialog
put src/Dialog.tsx <<'TSX'
import { useEffect, useId, useRef, type ReactNode } from 'react'

type DialogProps = {
  open: boolean
  title: string
  onClose: () => void
  children: ReactNode
}

export function Dialog({ open, title, onClose, children }: DialogProps) {
  const ref = useRef<HTMLDialogElement>(null)
  const titleId = useId()

  useEffect(() => {
    const dialog = ref.current
    if (!dialog) return
    if (open && !dialog.open) dialog.showModal()
    if (!open && dialog.open) dialog.close()
  }, [open])

  return (
    <dialog ref={ref} aria-labelledby={titleId} onClose={onClose}>
      <h2 id={titleId}>{title}</h2>
      {children}
      <button type="button" onClick={onClose}>
        Close
      </button>
    </dialog>
  )
}
TSX
put src/Field.tsx <<'TSX'
import { useId, type ComponentProps } from 'react'

type FieldProps = ComponentProps<'input'> & {
  label: string
  error?: string
}

export function Field({ label, error, ...input }: FieldProps) {
  const id = useId()
  return (
    <>
      <label htmlFor={id}>{label}</label>
      <input
        id={id}
        aria-invalid={error ? true : undefined}
        aria-describedby={error ? `${id}-error` : undefined}
        {...input}
      />
      {error && <p id={`${id}-error`}>{error}</p>}
    </>
  )
}
TSX
put src/AddSessionForm.tsx <<'TSX'
import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { Field } from './Field'
import { usePlannerContext } from './plannerContext'
import { sessionSchema, type SessionInput } from './sessionSchema'

type AddSessionFormProps = {
  course: string
  onAdded: (session: SessionInput) => void
}

export function AddSessionForm({ course, onAdded }: AddSessionFormProps) {
  const { addSession } = usePlannerContext()
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
    addSession(
      { course, ...values },
      {
        onSuccess: () => {
          reset()
          onAdded(values)
        },
      },
    )
  }

  return (
    <form onSubmit={handleSubmit(submit)} noValidate>
      <Field label="Date" type="date" error={errors.date?.message} {...register('date')} />
      <Field
        label="Minutes"
        type="number"
        error={errors.minutes?.message}
        {...register('minutes', { valueAsNumber: true })}
      />
      <button type="submit">Add session</button>
    </form>
  )
}
TSX
put src/CourseScreen.tsx <<'TSX'
import { useEffect, useRef, useState } from 'react'
import { AddSessionForm } from './AddSessionForm'
import { Dialog } from './Dialog'
import { usePlannerContext } from './plannerContext'
import type { Course } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  onBack: () => void
}

export function CourseScreen({ course, onBack }: CourseScreenProps) {
  const { sessions, toggleDone } = usePlannerContext()
  const [planning, setPlanning] = useState(false)
  const heading = useRef<HTMLHeadingElement>(null)
  useEffect(() => {
    heading.current?.focus()
  }, [])

  const sorted = sessions
    .filter((s) => s.course === course.id)
    .sort((a, b) => a.date.localeCompare(b.date))
  return (
    <>
      <button type="button" onClick={onBack}>
        Back to courses
      </button>
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
        <AddSessionForm course={course.id} onAdded={() => setPlanning(false)} />
      </Dialog>
    </>
  )
}
TSX
on 'npm run lint && npx tsc -b && echo no errors'
serve 5173 npm run dev
block dialog-closed
on "$L --do 'click button Statistics'"
block dialog-open
on "$L $OPEN"
block dialog-escape
on "$L $OPEN --do 'press Escape' | grep -E 'dialog|button'"

block form
fresh
on "$L $OPEN --do 'click button Add session' | sed -n '/dialog/,\$p'"
fresh
on "$L $OPEN --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' | grep -E 'dialog|checkbox'"

block status
put src/StatusMessage.tsx <<'TSX'
import { createPortal } from 'react-dom'

export function StatusMessage({ message }: { message: string }) {
  return createPortal(
    <div role="status" className="status-message">
      {message}
    </div>,
    document.body,
  )
}
TSX
append src/index.css <<'CSS'

.status-message:not(:empty) {
  position: fixed;
  bottom: 1rem;
  left: 1rem;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  background: Canvas;
  border: 1px solid #8888;
}
CSS
put src/CourseScreen.tsx <<'TSX'
import { useEffect, useRef, useState } from 'react'
import { AddSessionForm } from './AddSessionForm'
import { Dialog } from './Dialog'
import { usePlannerContext } from './plannerContext'
import { StatusMessage } from './StatusMessage'
import type { Course } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  onBack: () => void
}

export function CourseScreen({ course, onBack }: CourseScreenProps) {
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
      <button type="button" onClick={onBack}>
        Back to courses
      </button>
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
on 'npm run lint && npx tsc -b && echo no errors'
block status-shown
fresh
on "$L $OPEN --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' --html 'body > [role=status]' | sed -n '/^-- click button Add/,\$p'"
block status-where
fresh
on "$L --do 'click button Statistics' --html 'body' | grep -o '<div role=\"status\"[^>]*>'"
on "$L --do 'click button Statistics' --html '#root' | grep -c 'role=\"status\"'"

api_stop; fresh
stop
lab save after-$(basename "$PWD")
finish
