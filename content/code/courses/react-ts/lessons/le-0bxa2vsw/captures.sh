#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 20's captures.sh
#
# Works in ~/planner as lesson 20 left it. What is STAGED rather than typed: the
# files ana wrote, put below and shown in the lesson; the API server and Vite's
# development server, which ana runs in terminals of their own and the script
# starts in the background; data/planner.json, deleted before each
# demonstration so that each starts from the seed data; and the page's date,
# Wednesday 21 October 2026, set with --today.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-7ecjw0q2
C='look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet'
api_start() { lab exec ana "cd ~/planner && (DELAY=${1:-0} setsid node server/api.mjs > /tmp/api.out 2>&1 < /dev/null & echo \$! > /tmp/api.pid)"; sleep 1; }
api_stop() { lab exec ana 'kill $(cat /tmp/api.pid) 2>/dev/null; pkill -u ana -f server/api.mjs; rm -f /tmp/api.pid' > /dev/null 2>&1; sleep 0.5; }
fresh() { lab exec ana 'rm -f ~/planner/data/planner.json'; }
fresh; api_start

block profiler
put src/logRender.ts <<'TS'
import type { ProfilerOnRenderCallback } from 'react'

// For a <Profiler>: one line in the console each time what it wraps is drawn.
export const logRender: ProfilerOnRenderCallback = (id, phase) => {
  console.log(`drawn: ${id} (${phase})`)
}
TS
put src/SessionRow.tsx <<'TSX'
import { Profiler } from 'react'
import { logRender } from './logRender'
import type { Session } from './types'
import { formatDay } from './week'

type SessionRowProps = {
  session: Session
  onToggle: (id: string) => void
}

export function SessionRow({ session, onToggle }: SessionRowProps) {
  return (
    <Profiler id={`row ${session.id}`} onRender={logRender}>
      <label>
        <input type="checkbox" checked={session.done} onChange={() => onToggle(session.id)} />
        {formatDay(session.date)} · {session.minutes} min
      </label>
    </Profiler>
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
import { SessionRow } from './SessionRow'
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
        render={(s) => <SessionRow session={s} onToggle={toggleDone} />}
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
serve 5173 npm run dev
block profile-open
fresh
on "$C"
block profile-dialog
fresh
on "$C --do 'click button Plan a session'"
block profile-tick
fresh
on "$C --do 'click checkbox Wed 21 Oct · 40 min'"

block memo
on "sed -i 's/^export function SessionRow(/export const SessionRow = memo(function SessionRow(/; s/^import { Profiler } from .react./import { memo, Profiler } from '\\''react'\\''/' src/SessionRow.tsx && sed -i '\$s/^}\$/})/' src/SessionRow.tsx && cat src/SessionRow.tsx"
on 'npm run lint && npx tsc -b && echo no errors'
block memo-dialog
fresh
on "$C --do 'click button Plan a session'"
block memo-tick
fresh
on "$C --do 'click checkbox Wed 21 Oct · 40 min'"
block memo-broken
on "sed -i 's|onToggle={toggleDone} />}|onToggle={(id) => toggleDone(id)} />}|' src/CourseScreen.tsx && grep -n 'onToggle=' src/CourseScreen.tsx"
fresh
on "$C --do 'click button Plan a session'"
on "sed -i 's|onToggle={(id) => toggleDone(id)} />}|onToggle={toggleDone} />}|' src/CourseScreen.tsx && grep -n 'onToggle=' src/CourseScreen.tsx"
stop

block compiler
on "sed -i 's/^export const SessionRow = memo(function SessionRow(/export function SessionRow(/; s/^import { memo, Profiler } from .react./import { Profiler } from '\\''react'\\''/' src/SessionRow.tsx && sed -i '\$s/^})\$/}/' src/SessionRow.tsx && grep -c memo src/SessionRow.tsx"
on 'npm install --save-dev @rolldown/plugin-babel@0.2.4 @babel/core@8.0.7 babel-plugin-react-compiler@1.0.0'
put vite.config.ts <<'TS'
import babel from '@rolldown/plugin-babel'
import react, { reactCompilerPreset } from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), babel({ presets: [reactCompilerPreset()] })],
  server: {
    proxy: {
      '/api': 'http://localhost:3001',
    },
  },
})
TS
block compiler-check
on 'npm run lint && npx tsc -b && echo no errors'
serve 5173 npm run dev
block compiled
on "curl -s http://localhost:5173/src/SessionRow.tsx | grep -o 'react_compiler-runtime\\.js\\|_c([0-9]*)' | sort -u"
block compiler-dialog
fresh
on "$C --do 'click button Plan a session'"
block compiler-tick
fresh
on "$C --do 'click checkbox Wed 21 Oct · 40 min'"
block compiler-arrow
on "sed -i 's|onToggle={toggleDone} />}|onToggle={(id) => toggleDone(id)} />}|' src/CourseScreen.tsx && grep -n 'onToggle=' src/CourseScreen.tsx"
fresh
on "$C --do 'click button Plan a session'"
on "sed -i 's|onToggle={(id) => toggleDone(id)} />}|onToggle={toggleDone} />}|' src/CourseScreen.tsx && grep -n 'onToggle=' src/CourseScreen.tsx"
stop

api_stop; fresh
lab save after-$(basename "$PWD")
finish
