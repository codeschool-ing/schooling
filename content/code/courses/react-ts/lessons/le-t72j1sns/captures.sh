#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 6's captures.sh
#
# Starts from ~/planner as lesson 6 left it. What is STAGED rather than typed:
# the files ana wrote, put below and shown in the lesson; the temporary
# re-render button and logging of "useMemo", added with sed and taken out the
# same way; and the page's date, Wednesday 21 October 2026, set with --today.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-2t7tr8rw
L='look http://localhost:5173/ --today 2026-10-21'
serve 5173 npm run dev

block focus-before
on "$L --do 'click button Statistics' --do 'press Tab' --quiet --html ':focus'"

put src/CourseScreen.tsx <<'TSX'
import { useEffect, useRef } from 'react'
import type { Course, Session } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  sessions: Session[]
  onToggle: (id: string) => void
  onBack: () => void
}

export function CourseScreen({ course, sessions, onToggle, onBack }: CourseScreenProps) {
  const heading = useRef<HTMLHeadingElement>(null)
  useEffect(() => {
    heading.current?.focus()
  }, [])

  const sorted = [...sessions].sort((a, b) => a.date.localeCompare(b.date))
  return (
    <>
      <button type="button" onClick={onBack}>
        Back to courses
      </button>
      <h1 ref={heading} tabIndex={-1}>
        {course.name}
      </h1>
      <ul>
        {sorted.map((s) => (
          <li key={s.id}>
            <label>
              <input type="checkbox" checked={s.done} onChange={() => onToggle(s.id)} />
              {formatDay(s.date)} · {s.minutes} min
            </label>
          </li>
        ))}
      </ul>
    </>
  )
}
TSX
block focus-after
on "$L --do 'click button Statistics' --quiet --html ':focus'"
on "$L --do 'click button Statistics' --do 'press Tab' --quiet --html ':focus'"

block ref-box
put src/RenderCount.tsx <<'TSX'
import { useRef } from 'react'

// For lesson 7 only: a ref survives renders and changing it renders nothing.
export function RenderCount() {
  const renders = useRef(0)
  renders.current += 1
  console.log('RenderCount has rendered', renders.current, 'times')
  return null
}
TSX
on "sed -i 's|^      <WeekNav .*|&\\n      <RenderCount />|; 1a import { RenderCount } from \"./RenderCount\"' src/App.tsx"
on "$L --quiet --do 'click button Next week' --do 'click button Next week'"
on "sed -i '/RenderCount/d' src/App.tsx && rm src/RenderCount.tsx"

block memo-before
on 'cp src/App.tsx /tmp/App.tsx; cp src/WeekSummary.tsx /tmp/WeekSummary.tsx'
on "sed -i 's|^  const \\[openId, setOpenId\\] = useState<string \\| null>(null)\$|&\\n  const [, setTick] = useState(0)|; s|^      <WeekNav .*|&\\n      <button type=\"button\" onClick={() => setTick((t) => t + 1)}>Render App again</button>|' src/App.tsx"
on "sed -i 's|^  const done = sessions.filter((s) => s.done)\$|  useEffect(() => console.log('\"'\"'WeekSummary received a new sessions array'\"'\"'), [sessions])\\n&|; 1i import { useEffect } from \"react\"' src/WeekSummary.tsx"
on 'grep -n "setTick\|useEffect" src/App.tsx src/WeekSummary.tsx | grep -v "^src/App.tsx:[0-9]*:  useEffect(() => {$"'
on "$L --quiet --do 'click button Render App again' --do 'click button Render App again'"

block memo-after
on "sed -i 's|^  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))\$|  const thisWeek = useMemo(\\n    () => sessions.filter((s) => inWeek(s.date, monday)),\\n    [sessions, monday],\\n  )|; s|^import { useEffect, useState } from .react.\$|import { useEffect, useMemo, useState } from '\"'\"'react'\"'\"'|' src/App.tsx"
on 'grep -n -A 3 "const thisWeek" src/App.tsx'
on "$L --quiet --do 'click button Render App again' 2>&1 | grep -E '^Uncaught|^\\[error\\] React'"

block memo-moved
# STAGED: the useMemo moved above the two early returns, by this python rather
# than by hand; the lesson shows the lines around it.
quietly_put src/App.tsx < <(python3 - /home/ana/planner/src/App.tsx <<'PY'
import sys
s = open(sys.argv[1]).read()
memo = "  const thisWeek = useMemo(\n    () => sessions.filter((s) => inWeek(s.date, monday)),\n    [sessions, monday],\n  )\n"
s = s.replace(memo, "")
early = "  if (status === 'loading')"
s = s.replace(early, memo + "\n" + early)
sys.stdout.write(s)
PY
)
on 'grep -n -B 1 -A 5 "const thisWeek" src/App.tsx'
on "$L --quiet --do 'click button Render App again' --do 'click button Render App again'"
on "$L --quiet --do 'click button Render App again' --do 'click button Next week'"
on 'cp /tmp/App.tsx src/App.tsx; cp /tmp/WeekSummary.tsx src/WeekSummary.tsx'

block hooks
put src/usePlanner.ts <<'TS'
import { useCallback, useEffect, useState } from 'react'
import type { Course, Session } from './types'

type Status = 'loading' | 'ready' | 'failed'

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

  return { status, courses, sessions, toggleDone }
}
TS
put src/useWeek.ts <<'TS'
import { useEffect, useState } from 'react'
import { addDays, formatWeek, mondayOf, today } from './week'

export function useWeek() {
  const [monday, setMonday] = useState(() => mondayOf(today()))

  useEffect(() => {
    document.title = `Week of ${formatWeek(monday)} · Study planner`
  }, [monday])

  useEffect(() => {
    function onKey(event: KeyboardEvent) {
      if (event.target instanceof HTMLInputElement) return
      if (event.key === 'ArrowLeft') setMonday((m) => addDays(m, -7))
      if (event.key === 'ArrowRight') setMonday((m) => addDays(m, 7))
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  return [monday, setMonday] as const
}
TS
put src/App.tsx <<'TSX'
import { useState } from 'react'
import { CourseList } from './CourseList'
import { CourseScreen } from './CourseScreen'
import { usePlanner } from './usePlanner'
import { useWeek } from './useWeek'
import { inWeek } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

function App() {
  const [monday, setMonday] = useWeek()
  const { status, courses, sessions, toggleDone } = usePlanner()
  const [openId, setOpenId] = useState<string | null>(null)

  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <p role="alert">The planner could not be loaded.</p>

  const open = courses.find((c) => c.id === openId)
  if (open) {
    return (
      <main>
        <CourseScreen
          course={open}
          sessions={sessions.filter((s) => s.course === open.id)}
          onToggle={toggleDone}
          onBack={() => setOpenId(null)}
        />
      </main>
    )
  }

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList courses={courses} sessions={thisWeek} onOpen={setOpenId} />
    </main>
  )
}

export default App
TSX
on 'wc -l src/App.tsx src/usePlanner.ts src/useWeek.ts'
on 'npm run lint && npx tsc -b && echo no errors'
on "$L --do 'press ArrowRight' --do 'click button Previous week' --html title | sed -n 1,2p\;9,11p\;\\\$p"
on "$L --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | grep minutes"

lab save after-$(basename "$PWD")
finish
