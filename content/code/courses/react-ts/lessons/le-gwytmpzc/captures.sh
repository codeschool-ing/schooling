#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 3's captures.sh
#
# Starts from ~/planner as lesson 3 left it. What is STAGED rather than typed:
# the files ana wrote, put below and shown in the lesson; two deliberate
# mistakes, each put with quietly_put because the lesson shows only the lines
# that differ from the file it already showed whole, and then put back; and
# the page's date, Wednesday 21 October 2026, set with --today.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-521eqe5r
L='look http://localhost:5173/ --today 2026-10-21'
serve 5173 npm run dev

block snapshot
put src/TwoWeeks.tsx <<'TSX'
import type { Dispatch, SetStateAction } from 'react'
import { addDays } from './week'

type TwoWeeksProps = {
  monday: string
  setMonday: Dispatch<SetStateAction<string>>
}

// For lesson 4 only: one click, two calls to the setter.
export function TwoWeeks({ monday, setMonday }: TwoWeeksProps) {
  function jump() {
    setMonday(addDays(monday, 7))
    setMonday(addDays(monday, 7))
    console.log('after both calls, monday is', monday)
  }
  return (
    <button type="button" onClick={jump}>
      Two weeks on
    </button>
  )
}
TSX
on "sed -i 's|^      <WeekNav .*|&\\n      <TwoWeeks monday={monday} setMonday={setMonday} />|; 1a import { TwoWeeks } from \"./TwoWeeks\"' src/App.tsx"
on 'grep -n TwoWeeks src/App.tsx'
on "$L --do 'click button Two weeks on' | head -n 11"

block updater
on "sed -i 's|setMonday(addDays(monday, 7))|setMonday((m) => addDays(m, 7))|' src/TwoWeeks.tsx"
on 'sed -n 12,16p src/TwoWeeks.tsx'
on "$L --do 'click button Two weeks on' | head -n 11"
on "sed -i '/TwoWeeks/d' src/App.tsx && rm src/TwoWeeks.tsx"

block derived-bug
on 'cp src/WeekSummary.tsx /tmp/WeekSummary.tsx'
put src/WeekSummary.tsx <<'TSX'
import { useState } from 'react'
import type { Session } from './types'
import { formatWeek, minutes } from './week'

type WeekSummaryProps = {
  monday: string
  sessions: Session[]
}

// A mistake, on purpose: the totals copied into state.
export function WeekSummary({ monday, sessions }: WeekSummaryProps) {
  const [planned] = useState(minutes(sessions))
  const [done] = useState(minutes(sessions.filter((s) => s.done)))
  return (
    <section aria-label="This week">
      <p>Week of {formatWeek(monday)}</p>
      <p>
        {done} of {planned} minutes done
      </p>
    </section>
  )
}
TSX
on "$L --do 'click button Next week' | sed -n 6,9p"
on 'cp /tmp/WeekSummary.tsx src/WeekSummary.tsx'
on "$L --do 'click button Next week' | sed -n 6,9p"

block second-screen
put src/Card.tsx <<'TSX'
import type { ReactNode } from 'react'

type CardProps = {
  title: ReactNode
  children: ReactNode
}

export function Card({ title, children }: CardProps) {
  return (
    <article className="card">
      <h2>{title}</h2>
      {children}
    </article>
  )
}
TSX
put src/CourseCard.tsx <<'TSX'
import { Card } from './Card'
import type { Course, Session } from './types'
import { minutes } from './week'

type CourseCardProps = {
  course: Course
  sessions: Session[]
  onOpen: (id: string) => void
}

export function CourseCard({ course, sessions, onOpen }: CourseCardProps) {
  const count = sessions.length
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
    </Card>
  )
}
TSX
put src/CourseList.tsx <<'TSX'
import { CourseCard } from './CourseCard'
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
        <CourseCard
          key={course.id}
          course={course}
          sessions={sessions.filter((s) => s.course === course.id)}
          onOpen={onOpen}
        />
      ))}
    </section>
  )
}
TSX
put src/CourseScreen.tsx <<'TSX'
import type { Course, Session } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  sessions: Session[]
  onToggle: (id: string) => void
  onBack: () => void
}

export function CourseScreen({ course, sessions, onToggle, onBack }: CourseScreenProps) {
  const sorted = [...sessions].sort((a, b) => a.date.localeCompare(b.date))
  return (
    <>
      <button type="button" onClick={onBack}>
        Back to courses
      </button>
      <h1>{course.name}</h1>
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
put src/App.tsx <<'TSX'
import { useState } from 'react'
import { CourseList } from './CourseList'
import { CourseScreen } from './CourseScreen'
import { courses, sessions as initialSessions } from './sample'
import { inWeek, mondayOf, today } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

function App() {
  const [monday, setMonday] = useState(() => mondayOf(today()))
  const [sessions, setSessions] = useState(initialSessions)
  const [openId, setOpenId] = useState<string | null>(null)

  function toggleDone(id: string) {
    setSessions((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }

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
on 'npx tsc -b && echo no errors'
on "$L | sed -n 9,13p"
on "$L --do 'click button Statistics'"
on "$L --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | sed -n 6,13p"

block mutate-bug
on 'cp src/App.tsx /tmp/App.tsx'
quietly_put src/App.tsx < <(sed 's|^    setSessions((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))$|    setSessions((all) => {\n      const session = all.find((s) => s.id === id)!\n      session.done = !session.done\n      return all\n    })|' /home/ana/planner/src/App.tsx)
on 'sed -n 14,20p src/App.tsx'
on "$L --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min'"
on "$L --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | sed -n 9,11p"
on 'cp src/main.tsx /tmp/main.tsx'
on "sed -i 's/<StrictMode>/<>/; s/<\\/StrictMode>/<\\/>/; /^import { StrictMode }/d' src/main.tsx"
on "$L --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' | tail -n 3"
on "$L --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | sed -n 9,11p"
on 'cp /tmp/App.tsx src/App.tsx && cp /tmp/main.tsx src/main.tsx'

lab save after-$(basename "$PWD")
finish
