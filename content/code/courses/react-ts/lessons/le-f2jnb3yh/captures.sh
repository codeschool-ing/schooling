#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 12's captures.sh
#
# Starts from ~/planner as lesson 12 left it. What is STAGED rather than typed:
# the files ana wrote, put below and shown in the lesson; the API server and the
# preview server, which ana runs in terminals of their own and the script starts
# in the background; data/planner.json, deleted before each demonstration so that
# each starts from the seed data; and the page's date, Wednesday 21 October 2026,
# set with --today. In "when the file is gone" the preview server is stopped
# three seconds after the page opened, standing in for a deploy that removed the
# old files while the page was open.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-86qxme6f
P='look http://localhost:4173/ --today 2026-10-21'
api_start() { lab exec ana 'cd ~/planner && (setsid node server/api.mjs > /tmp/api.out 2>&1 < /dev/null & echo $! > /tmp/api.pid)'; sleep 1; }
api_stop() { lab exec ana 'kill $(cat /tmp/api.pid) 2>/dev/null; pkill -u ana -f server/api.mjs; rm -f /tmp/api.pid' > /dev/null 2>&1; sleep 0.5; }
fresh() { lab exec ana 'rm -f ~/planner/data/planner.json'; }
fresh; api_start

block build-before
on 'npm run build'

block lazy
put src/App.tsx <<'TSX'
import { lazy, Suspense, useState } from 'react'
import { CourseList } from './CourseList'
import { LoadFailed } from './LoadFailed'
import { usePlannerContext } from './plannerContext'
import { useWeek } from './useWeek'
import { inWeek } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

const CourseScreen = lazy(() =>
  import('./CourseScreen').then((module) => ({ default: module.CourseScreen })),
)

function App() {
  const [monday, setMonday] = useWeek()
  const { status, courses, sessions } = usePlannerContext()
  const [openId, setOpenId] = useState<string | null>(null)

  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <LoadFailed />

  const open = courses.find((c) => c.id === openId)
  if (open) {
    return (
      <main>
        <Suspense fallback={<p>Loading the course…</p>}>
          <CourseScreen course={open} onBack={() => setOpenId(null)} />
        </Suspense>
      </main>
    )
  }

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList key={monday} courses={courses} sessions={thisWeek} onOpen={setOpenId} />
    </main>
  )
}

export default App
TSX
on 'npm run lint'

block build-after
on 'npm run build'

block preview
serve 4173 npm run preview
served
block preview-net
on "$P --network | grep -E 'assets|api'"
fresh
on "$P --network --do 'click button Statistics' | grep -E 'assets|api|^-- |heading'"

block gone
fresh
(sleep 3; lab stop) &
on "$P --do 'wait 5000' --do 'click button Statistics'"
wait

block early
put src/App.tsx <<'TSX'
import { lazy, Suspense, useEffect, useState } from 'react'
import { CourseList } from './CourseList'
import { LoadFailed } from './LoadFailed'
import { usePlannerContext } from './plannerContext'
import { useWeek } from './useWeek'
import { inWeek } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

const loadCourseScreen = () => import('./CourseScreen')
const CourseScreen = lazy(() =>
  loadCourseScreen().then((module) => ({ default: module.CourseScreen })),
)

function App() {
  const [monday, setMonday] = useWeek()
  const { status, courses, sessions } = usePlannerContext()
  const [openId, setOpenId] = useState<string | null>(null)

  // Once the planner is on the screen, fetch the course screen's code in the
  // background, so that opening a course does not wait for it.
  useEffect(() => {
    if (status === 'ready') void loadCourseScreen()
  }, [status])

  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <LoadFailed />

  const open = courses.find((c) => c.id === openId)
  if (open) {
    return (
      <main>
        <Suspense fallback={<p>Loading the course…</p>}>
          <CourseScreen course={open} onBack={() => setOpenId(null)} />
        </Suspense>
      </main>
    )
  }

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList key={monday} courses={courses} sessions={thisWeek} onOpen={setOpenId} />
    </main>
  )
}

export default App
TSX
on 'npm run lint && npm run build | grep -E "assets|built"'
serve 4173 npm run preview
fresh
on "$P --network | grep -E 'assets|api'"
fresh
(sleep 3; lab stop) &
on "$P --do 'wait 5000' --do 'click button Statistics' | grep -E 'heading|alert|error'"
wait

api_stop; fresh
stop
lab save after-$(basename "$PWD")
finish
