#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 7's captures.sh
#
# Starts from ~/planner as lesson 7 left it. What is STAGED rather than typed:
# the files ana wrote, put below and shown in the lesson (two of them are
# temporary, for one demonstration each, and are taken out again); a fourth
# course added to public/courses.json for one transcript, by a node one-liner
# the lesson shows, and the file put back afterwards; and the page's date,
# Wednesday 21 October 2026, set with --today.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-t72j1sns
L='look http://localhost:5173/ --today 2026-10-21'
serve 5173 npm run dev
lab exec ana 'cp ~/planner/src/CourseScreen.tsx /tmp/CourseScreen.tsx; cp ~/planner/src/CourseCard.tsx /tmp/CourseCard.tsx; cp ~/planner/public/courses.json /tmp/courses.json'

block nokey
on "sed -i '/^          key={course.id}\$/d' src/CourseList.tsx"
on "$L --quiet"
on 'npm run lint 2>&1 | grep -A 1 "jsx-key"'
on "sed -i 's|^          course={course}\$|          key={course.id}\\n&|' src/CourseList.tsx"
on 'grep -n "key=" src/CourseList.tsx'

block index-key
put src/CourseScreen.tsx <<'TSX'
import { useEffect, useRef, useState } from 'react'
import type { Course, Session } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  sessions: Session[]
  onToggle: (id: string) => void
  onBack: () => void
}

// For lesson 8 only: a note beside each session, and a button that reverses
// the order. The key is the session's position, which is the mistake.
export function CourseScreen({ course, sessions, onToggle, onBack }: CourseScreenProps) {
  const heading = useRef<HTMLHeadingElement>(null)
  useEffect(() => {
    heading.current?.focus()
  }, [])
  const [newestFirst, setNewestFirst] = useState(false)

  const sorted = [...sessions].sort((a, b) => a.date.localeCompare(b.date))
  if (newestFirst) sorted.reverse()
  return (
    <>
      <button type="button" onClick={onBack}>
        Back to courses
      </button>
      <h1 ref={heading} tabIndex={-1}>
        {course.name}
      </h1>
      <button type="button" onClick={() => setNewestFirst(!newestFirst)}>
        Reverse the order
      </button>
      <ul>
        {sorted.map((s, index) => (
          <li key={index}>
            <label>
              <input type="checkbox" checked={s.done} onChange={() => onToggle(s.id)} />
              {formatDay(s.date)} · {s.minutes} min
            </label>
            <input aria-label={`Note for ${formatDay(s.date)}`} />
          </li>
        ))}
      </ul>
    </>
  )
}
TSX
on "$L --do 'click button Statistics' --do 'fill Note for Mon 19 Oct=read chapter 3' | sed -n '/list:/,\$p'"
on "$L --do 'click button Statistics' --do 'fill Note for Mon 19 Oct=read chapter 3' --do 'click button Reverse the order' | sed -n '/list:/,\$p'"

block id-key
on "sed -i 's|<li key={index}>|<li key={s.id}>|; s|sorted.map((s, index) =>|sorted.map((s) =>|' src/CourseScreen.tsx"
on 'grep -n "<li key" src/CourseScreen.tsx'
on "$L --do 'click button Statistics' --do 'fill Note for Mon 19 Oct=read chapter 3' --do 'click button Reverse the order' | sed -n '/list:/,\$p'"
on 'cp /tmp/CourseScreen.tsx src/CourseScreen.tsx'

block zero
put src/CourseCard.tsx <<'TSX'
import { Card } from './Card'
import type { Course, Session } from './types'
import { minutes } from './week'

type CourseCardProps = {
  course: Course
  sessions: Session[]
  onOpen: (id: string) => void
}

// For lesson 8 only: the line is drawn only when there are sessions.
export function CourseCard({ course, sessions, onOpen }: CourseCardProps) {
  const count = sessions.length
  const title = (
    <button type="button" onClick={() => onOpen(course.id)}>
      {course.name}
    </button>
  )
  return (
    <Card title={title}>
      {count && (
        <p>
          {count} {count === 1 ? 'session' : 'sessions'} · {minutes(sessions)} min
        </p>
      )}
    </Card>
  )
}
TSX
on "$L --do 'click button Next week' | sed -n '/region \"Courses\"/,\$p'"
on "sed -i 's|^      {count && (\$|      {count > 0 \\&\\& (|' src/CourseCard.tsx"
on 'grep -n "count > 0" src/CourseCard.tsx'
on "$L --do 'click button Next week' | sed -n '/region \"Courses\"/,\$p'"
on 'cp /tmp/CourseCard.tsx src/CourseCard.tsx'

block empty
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
      {sorted.length === 0 ? (
        <p>No sessions planned for this course yet.</p>
      ) : (
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
      )}
    </>
  )
}
TSX
on "node -e \"const f='public/courses.json', d=JSON.parse(require('fs').readFileSync(f)); d.courses.push({id:'latin', name:'Latin'}); require('fs').writeFileSync(f, JSON.stringify(d, null, 2))\""
on "$L --do 'click button Latin'"
on 'cp /tmp/courses.json public/courses.json'
on 'npm run lint && npx tsc -b && echo no errors'

lab save after-$(basename "$PWD")
finish
