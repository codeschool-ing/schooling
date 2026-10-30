#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 4's captures.sh
#
# Starts from ~/planner as lesson 4 left it. What is STAGED rather than typed:
# the files ana wrote, put below and shown in the lesson; the deliberate
# mistakes (a wrong address, a missing cleanup), each made with sed and undone
# the same way; and the page's date, Wednesday 21 October 2026, set with
# --today.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-gwytmpzc
L='look http://localhost:5173/ --today 2026-10-21'
serve 5173 npm run dev

put src/App.tsx <<'TSX'
import { useEffect, useState } from 'react'
import { CourseList } from './CourseList'
import { CourseScreen } from './CourseScreen'
import type { Course, Session } from './types'
import { addDays, formatWeek, inWeek, mondayOf, today } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

type Status = 'loading' | 'ready' | 'failed'

function App() {
  const [monday, setMonday] = useState(() => mondayOf(today()))
  const [courses, setCourses] = useState<Course[]>([])
  const [sessions, setSessions] = useState<Session[]>([])
  const [status, setStatus] = useState<Status>('loading')
  const [openId, setOpenId] = useState<string | null>(null)

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

  function toggleDone(id: string) {
    setSessions((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }

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

block fetched
on 'rm src/sample.ts'
on 'npx tsc -b && echo no errors'
on "$L --network | grep -v 'GET /[@sn]'"

block strict-fetch
on "$L --network --quiet | grep courses"

block title
on "$L --quiet --html title"
on "$L --quiet --do 'click button Next week' --html title"

block keys
on "$L --do 'press ArrowRight' | grep 'Week of'"

block leak
on "sed -i '/return () => window.removeEventListener/d' src/App.tsx"
on 'grep -n "addEventListener\|removeEventListener" src/App.tsx'
on "$L --do 'press ArrowRight' | grep 'Week of'"
on "sed -i 's|^    window.addEventListener(.keydown., onKey)\$|&\\n    return () => window.removeEventListener('\"'\"'keydown'\"'\"', onKey)|' src/App.tsx"
on 'grep -n "addEventListener\|removeEventListener" src/App.tsx'
on "$L --do 'press ArrowRight' | grep 'Week of'"

block wrong-address
on "sed -i \"s|fetch('/courses.json')|fetch('/course.json')|\" src/App.tsx"
on "$L --network | grep -v 'GET /[@sn]'"
on 'curl -s -i http://localhost:5173/course.json | head -n 4'
on "sed -i \"s|fetch('/course.json')|fetch('/courses.json')|\" src/App.tsx"

block deps-wrong
on "sed -i 's|^  }, \\[monday\\])\$|  }, [])|' src/App.tsx"
on 'grep -n "}, \[" src/App.tsx'
on "$L --quiet --do 'click button Next week' --html title"
on 'npm run lint'
on "sed -i '0,/^  }, \\[\\])\$/!{0,/^  }, \\[\\])\$/s//  }, [monday])/}' src/App.tsx"
on 'grep -n "}, \[" src/App.tsx'

lab save after-$(basename "$PWD")
finish
