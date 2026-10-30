#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of react-ts, as a script that
# produces them.
#
#   sudo -E bash ../../lab.sh up       # once
#   sudo -E bash captures.sh           # after lesson 1's captures.sh
#
# Starts from ~/planner as lesson 1 left it. What is STAGED rather than typed:
# the files ana wrote, put below and shown whole in the lesson; and the
# deliberate mistakes of "Components" and "Props", made with sed and undone the
# same way, each shown as the line it changes.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-1f9bsnn0

block clean
on 'rm -r src/App.css src/assets public/icons.svg'
on 'ls src public'

put src/index.css <<'CSS'
:root {
  font-family: system-ui, sans-serif;
  line-height: 1.5;
  color-scheme: light dark;
}

body {
  margin: 0;
}

main {
  max-width: 36rem;
  margin: 0 auto;
  padding: 1.5rem 1rem;
}

.card {
  border: 1px solid #8888;
  border-radius: 6px;
  padding: 0.5rem 1rem;
  margin: 0.5rem 0;
}

.card h2 {
  font-size: 1.1rem;
  margin: 0;
}

.card p {
  margin: 0.25rem 0 0;
}
CSS

put src/types.ts <<'TS'
export type Course = {
  id: string
  name: string
}

export type Session = {
  id: string
  course: string
  date: string
  minutes: number
  done: boolean
}
TS

put src/sample.ts <<'TS'
import type { Course, Session } from './types'

// The same data as public/courses.json, until lesson 5 fetches that file.
export const courses: Course[] = [
  { id: 'statistics', name: 'Statistics' },
  { id: 'spanish', name: 'Spanish' },
  { id: 'chemistry', name: 'Organic chemistry' },
]

export const sessions: Session[] = [
  { id: 's1', course: 'statistics', date: '2026-10-19', minutes: 50, done: true },
  { id: 's2', course: 'statistics', date: '2026-10-21', minutes: 40, done: false },
  { id: 's3', course: 'spanish', date: '2026-10-20', minutes: 30, done: true },
  { id: 's4', course: 'spanish', date: '2026-10-23', minutes: 30, done: false },
  { id: 's5', course: 'chemistry', date: '2026-10-14', minutes: 60, done: true },
  { id: 's6', course: 'chemistry', date: '2026-10-22', minutes: 45, done: false },
]
TS

put src/week.ts <<'TS'
import type { Session } from './types'

// A day is a 'YYYY-MM-DD' string, and a week starts on Monday. The arithmetic
// is done at noon UTC, so that no time zone can move a date to its neighbour.
const noon = (day: string) => new Date(`${day}T12:00:00Z`)

export function addDays(day: string, n: number): string {
  const d = noon(day)
  d.setUTCDate(d.getUTCDate() + n)
  return d.toISOString().slice(0, 10)
}

export function mondayOf(day: string): string {
  const back = (noon(day).getUTCDay() + 6) % 7
  return addDays(day, -back)
}

export function inWeek(day: string, monday: string): boolean {
  return day >= monday && day <= addDays(monday, 6)
}

export function minutes(sessions: Session[]): number {
  return sessions.reduce((sum, s) => sum + s.minutes, 0)
}

export function formatDay(day: string): string {
  return noon(day).toLocaleDateString('en-GB', {
    weekday: 'short', day: 'numeric', month: 'short', timeZone: 'UTC',
  })
}

export function formatWeek(monday: string): string {
  return noon(monday).toLocaleDateString('en-GB', {
    day: 'numeric', month: 'short', year: 'numeric', timeZone: 'UTC',
  })
}
TS

put src/Card.tsx <<'TSX'
import type { ReactNode } from 'react'

type CardProps = {
  title: string
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
}

export function CourseCard({ course, sessions }: CourseCardProps) {
  const count = sessions.length
  return (
    <Card title={course.name}>
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
}

export function CourseList({ courses, sessions }: CourseListProps) {
  return (
    <section aria-label="Courses">
      {courses.map((course) => (
        <CourseCard
          key={course.id}
          course={course}
          sessions={sessions.filter((s) => s.course === course.id)}
        />
      ))}
    </section>
  )
}
TSX

put src/WeekSummary.tsx <<'TSX'
import type { Session } from './types'
import { formatWeek, minutes } from './week'

type WeekSummaryProps = {
  monday: string
  sessions: Session[]
}

export function WeekSummary({ monday, sessions }: WeekSummaryProps) {
  const done = sessions.filter((s) => s.done)
  return (
    <section aria-label="This week">
      <p>Week of {formatWeek(monday)}</p>
      <p>
        {minutes(done)} of {minutes(sessions)} minutes done
      </p>
    </section>
  )
}
TSX

put src/App.tsx <<'TSX'
import { CourseList } from './CourseList'
import { courses, sessions } from './sample'
import { inWeek } from './week'
import { WeekSummary } from './WeekSummary'

// Until lesson 3 lets you move between weeks, the planner shows this one.
const MONDAY = '2026-10-19'

function App() {
  const thisWeek = sessions.filter((s) => inWeek(s.date, MONDAY))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekSummary monday={MONDAY} sessions={thisWeek} />
      <CourseList courses={courses} sessions={thisWeek} />
    </main>
  )
}

export default App
TSX

block first-screen
serve 5173 npm run dev
on 'look http://localhost:5173/'

block jsx
on 'curl -s http://localhost:5173/src/WeekSummary.tsx | head -n 24'

block lowercase
on "sed -i 's/<CourseCard$/<courseCard/' src/CourseList.tsx"
on 'grep -n courseCard src/CourseList.tsx'
on 'look http://localhost:5173/ 2>&1 | head -n 8'
on "sed -i 's/<courseCard$/<CourseCard/' src/CourseList.tsx"

block mutate
on "sed -i 's/^  const count = sessions.length$/  course.name = course.name.toUpperCase()\n  const count = sessions.length/' src/CourseCard.tsx"
on 'sed -n 10,13p src/CourseCard.tsx'
on 'look http://localhost:5173/'
on 'npx tsc -b'
on "sed -i '/toUpperCase/d' src/CourseCard.tsx"

block types
on "sed -i 's/<WeekSummary monday={MONDAY} sessions={thisWeek} \\/>/<WeekSummary monday={19} sessions={thisWeek} \\/>/' src/App.tsx"
on 'grep -n "<WeekSummary" src/App.tsx'
on 'look http://localhost:5173/ 2>&1 | head -n 5'
on 'npx tsc -b'
on 'npm run build'
on "sed -i 's/monday={19}/monday={MONDAY}/' src/App.tsx"
on 'npx tsc -b && echo no errors'

block weekfns
on "node -e \"import('./src/week.ts').then((w) => console.log(w.mondayOf('2026-10-21'), w.inWeek('2026-10-14', '2026-10-19'), w.formatDay('2026-10-19'), w.formatWeek('2026-10-19')))\""

stop
lab save after-$(basename "$PWD")
finish
