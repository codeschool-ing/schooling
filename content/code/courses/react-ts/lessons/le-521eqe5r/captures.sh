#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of react-ts, as a script that
# produces them.
#
#   sudo -E bash ../../lab.sh up       # once
#   sudo -E bash captures.sh           # after lesson 2's captures.sh
#
# Starts from ~/planner as lesson 2 left it. What is STAGED rather than typed:
# the files ana wrote, put below and shown in the lesson; the temporary
# instrumentation of "What re-renders", added with sed and taken out the same
# way, each change shown as a line of the transcript; and the page's date,
# which every `look` sets to Wednesday 21 October 2026 with --today.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-be3g2cpw
L='look http://localhost:5173/ --today 2026-10-21'

append src/week.ts <<'TS'

export function today(): string {
  const d = new Date()
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${d.getFullYear()}-${month}-${day}`
}
TS

put src/WeekNav.tsx <<'TSX'
import { addDays } from './week'

type WeekNavProps = {
  monday: string
  onChange: (monday: string) => void
}

export function WeekNav({ monday, onChange }: WeekNavProps) {
  return (
    <nav aria-label="Week">
      <button type="button" onClick={() => onChange(addDays(monday, -7))}>
        Previous week
      </button>
      <button type="button" onClick={() => onChange(addDays(monday, 7))}>
        Next week
      </button>
    </nav>
  )
}
TSX

put src/App.tsx <<'TSX'
import { useState } from 'react'
import { CourseList } from './CourseList'
import { courses, sessions } from './sample'
import { inWeek, mondayOf, today } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

function App() {
  const [monday, setMonday] = useState(() => mondayOf(today()))
  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList courses={courses} sessions={thisWeek} />
    </main>
  )
}

export default App
TSX

serve 5173 npm run dev
block nav
on "$L"
on "$L --do 'click button Next week'"
on "npx tsc -b && echo no errors"

block instrument
put src/rendered.ts <<'TS'
// For lesson 3 only: each component calls this while it renders, and the
// console says who rendered, in order.
export function rendered(name: string) {
  console.log(`render ${name}`)
}
TS
on "sed -i '1i import { rendered } from \"./rendered\"' src/App.tsx src/WeekNav.tsx src/WeekSummary.tsx src/CourseList.tsx src/CourseCard.tsx src/Card.tsx"
on "sed -i 's/^\\(export \\)\\?function \\([A-Za-z]*\\)(\\(.*\\)) {\$/&\\n  rendered('\"'\"'\\2'\"'\"')/' src/App.tsx src/WeekNav.tsx src/WeekSummary.tsx src/CourseList.tsx src/CourseCard.tsx src/Card.tsx"
on 'grep -n "rendered(" src/*.tsx'

block first-render
on "$L --quiet"

block strict
on "sed -i 's/<StrictMode>/<>/; s/<\\/StrictMode>/<\\/>/; /^import { StrictMode }/d' src/main.tsx"
on 'cat src/main.tsx'
on "$L --quiet"

block next-week
on "$L --quiet --do 'click button Next week'"

block mutations
put src/watch.ts <<'TS'
// For lesson 3 only: after each change React makes to the page, say how many
// nodes it touched and what they now read.
const root = document.getElementById('root')!
new MutationObserver((records) => {
  const touched = records.map((r) => `${r.type} "${r.target.textContent}"`)
  console.log(`DOM: ${records.length} change(s)`, touched.join(', '))
}).observe(root, { subtree: true, childList: true, characterData: true, attributes: true })
TS
on "sed -i '1i import \"./watch\"' src/main.tsx"
on "$L --quiet --do 'click button Next week'"

block same-week
on "$L --quiet --do 'click button Next week' --do 'click button Previous week'"

block probe
put src/Probe.tsx <<'TSX'
import { useState } from 'react'

// For lesson 3 only: a button that remembers how often it was pressed.
export function Probe({ name }: { name: string }) {
  const [count, setCount] = useState(0)
  return (
    <button type="button" onClick={() => setCount(count + 1)}>
      {name} pressed {count}
    </button>
  )
}
TSX
on "sed -i '/rendered/d; /watch/d' src/*.tsx src/main.tsx"
on "sed -i 's|^      {children}\$|      {children}\\n      <Probe name={title} />|; 1i import { Probe } from \"./Probe\"' src/Card.tsx"
on 'cat src/Card.tsx'
on "$L --do 'click button Statistics pressed 0' --do 'click button Statistics pressed 1' --do 'click button Next week' 2>&1 | tail -n 12"

block key
on "sed -i 's|<CourseList courses|<CourseList key={monday} courses|' src/App.tsx"
on 'grep -n "<CourseList" src/App.tsx'
on "$L --do 'click button Statistics pressed 0' --do 'click button Statistics pressed 1' --do 'click button Next week' 2>&1 | tail -n 12"

block cleanup
on "sed -i 's| key={monday}||' src/App.tsx"
on "sed -i '/Probe/d' src/Card.tsx"
on 'rm src/Probe.tsx src/rendered.ts src/watch.ts'
on "sed -i 's/^import { createRoot }/import { StrictMode } from '\"'\"'react'\"'\"'\\n&/; s/^  <>\$/  <StrictMode>/; s/^  <\\/>,\$/  <\\/StrictMode>,/' src/main.tsx"
on 'cat src/main.tsx'
on "npx tsc -b && echo no errors"
on "$L"

lab save after-$(basename "$PWD")
finish
