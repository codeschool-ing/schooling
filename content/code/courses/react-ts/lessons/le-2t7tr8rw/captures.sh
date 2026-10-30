#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 5's captures.sh
#
# Starts from ~/planner as lesson 5 left it. Nothing this lesson writes stays:
# every file is a deliberate mistake, put below and shown in the lesson, then
# taken back out, so the planner ends the lesson as lesson 5 left it. The
# page's date is Wednesday 21 October 2026, set with --today.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-4gmt62vq
L='look http://localhost:5173/ --today 2026-10-21'
serve 5173 npm run dev
lab exec ana 'cp ~/planner/src/WeekSummary.tsx /tmp/WeekSummary.tsx; cp ~/planner/src/App.tsx /tmp/App.tsx'

block app-early
# STAGED: the two `if (status …) return` lines moved above the title effect,
# by this python rather than by hand; the lesson shows the lines around them.
quietly_put src/App.tsx < <(python3 - /home/ana/planner/src/App.tsx <<'PY'
import sys
s = open(sys.argv[1]).read()
early = "  if (status === 'loading') return <p>Loading the planner…</p>\n  if (status === 'failed') return <p role=\"alert\">The planner could not be loaded.</p>\n"
s = s.replace(early + "\n", "")
title = "  useEffect(() => {\n    document.title"
s = s.replace(title, early + "\n" + title)
sys.stdout.write(s)
PY
)
on 'sed -n 38,45p src/App.tsx'
on 'npx tsc -b && echo no errors'
on "$L"
on 'npm run lint 2>&1 | grep -c rules-of-hooks'
on 'cp /tmp/App.tsx src/App.tsx'

block early-return
put src/WeekSummary.tsx <<'TSX'
import { useState } from 'react'
import type { Session } from './types'
import { formatWeek, minutes } from './week'

type WeekSummaryProps = {
  monday: string
  sessions: Session[]
}

// A mistake, on purpose: a hook after an early return.
export function WeekSummary({ monday, sessions }: WeekSummaryProps) {
  if (sessions.length === 0) {
    return <p>Nothing planned in the week of {formatWeek(monday)}.</p>
  }
  const [showLeft, setShowLeft] = useState(false)
  const planned = minutes(sessions)
  const done = minutes(sessions.filter((s) => s.done))
  return (
    <section aria-label="This week">
      <p>Week of {formatWeek(monday)}</p>
      <p>{showLeft ? `${planned - done} minutes left` : `${done} of ${planned} minutes done`}</p>
      <button type="button" onClick={() => setShowLeft(!showLeft)}>
        {showLeft ? 'Show minutes done' : 'Show minutes left'}
      </button>
    </section>
  )
}
TSX
on 'npx tsc -b && echo no errors'
on "$L --do 'click button Show minutes left' | sed -n 6,10p"
on "$L --do 'click button Next week' | sed -n 6,8p"
on "$L --do 'click button Show minutes left' --do 'click button Next week' --do 'click button Previous week' | grep minutes"

block lint
on 'npm run lint'

block fixed
put src/WeekSummary.tsx <<'TSX'
import { useState } from 'react'
import type { Session } from './types'
import { formatWeek, minutes } from './week'

type WeekSummaryProps = {
  monday: string
  sessions: Session[]
}

export function WeekSummary({ monday, sessions }: WeekSummaryProps) {
  const [showLeft, setShowLeft] = useState(false)
  if (sessions.length === 0) {
    return <p>Nothing planned in the week of {formatWeek(monday)}.</p>
  }
  const planned = minutes(sessions)
  const done = minutes(sessions.filter((s) => s.done))
  return (
    <section aria-label="This week">
      <p>Week of {formatWeek(monday)}</p>
      <p>{showLeft ? `${planned - done} minutes left` : `${done} of ${planned} minutes done`}</p>
      <button type="button" onClick={() => setShowLeft(!showLeft)}>
        {showLeft ? 'Show minutes done' : 'Show minutes left'}
      </button>
    </section>
  )
}
TSX
on 'npm run lint'
on "$L --do 'click button Next week' | sed -n 6,8p"
on "$L --do 'click button Show minutes left' --do 'click button Next week' --do 'click button Previous week' | grep minutes"

block conditional
on "sed -i 's|^  const \\[showLeft, setShowLeft\\] = useState(false)\$|  const [showLeft, setShowLeft] = sessions.length > 0 ? useState(false) : [false, () => {}]|' src/WeekSummary.tsx"
on 'sed -n 10,12p src/WeekSummary.tsx'
on 'npm run lint 2>&1 | head -n 12'
on 'cp /tmp/WeekSummary.tsx src/WeekSummary.tsx'

block stale
append src/App.tsx <<'TSX'

// A mistake, on purpose: an interval that reads state, with an empty array.
export function useWeekLogger(monday: string) {
  useEffect(() => {
    const id = setInterval(() => console.log('the interval sees', monday), 1000)
    return () => clearInterval(id)
  }, [])
}
TSX
on "sed -i 's|^  const \\[openId, setOpenId\\] = useState<string \\| null>(null)\$|&\\n  useWeekLogger(monday)|' src/App.tsx"
on 'grep -n "useWeekLogger" src/App.tsx'
on "$L --quiet --do 'wait 2200' --do 'click button Next week' --do 'wait 2200' | uniq -c"
on 'npm run lint 2>&1 | grep -A 2 exhaustive'

block stale-fixed
on "sed -i 's|^  }, \\[\\])\$|  }, [monday])|' src/App.tsx"
on 'tail -n 3 src/App.tsx'
on "$L --quiet --do 'wait 2200' --do 'click button Next week' --do 'wait 2200' | uniq -c"
on 'cp /tmp/App.tsx src/App.tsx'
on 'npm run lint && npx tsc -b && echo no errors'

lab save after-$(basename "$PWD")
finish
