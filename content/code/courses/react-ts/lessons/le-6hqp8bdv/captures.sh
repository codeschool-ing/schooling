#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 14's captures.sh
#
# Starts from ~/planner as lesson 14 left it, and creates ~/planner-next beside
# it. What is STAGED rather than typed: the files ana wrote, put below and shown
# in the lesson; npx's cache, emptied first so that create-next-app is fetched as
# it is on a machine that never ran it; the API server and the Next.js server,
# which ana runs in terminals of their own and the script starts in the
# background (the API with DELAY=2000 in the last part, which the lesson says);
# data/planner.json, deleted before each demonstration so that each starts from
# the seed data; and the page's date, Wednesday 21 October 2026, set with
# --today. Next.js's telemetry is turned off in the lab's environment
# (NEXT_TELEMETRY_DISABLED=1), so the notice it prints on a first run is not in
# these transcripts; the lesson says how to turn it off.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-094psgnj
N='look http://localhost:3000/?week=2026-10-19 --today 2026-10-21'
api_start() { lab exec ana "cd ~/planner && (DELAY=${1:-0} setsid node server/api.mjs > /tmp/api.out 2>&1 < /dev/null & echo \$! > /tmp/api.pid)"; sleep 1; }
api_stop() { lab exec ana 'kill $(cat /tmp/api.pid) 2>/dev/null; pkill -u ana -f server/api.mjs; rm -f /tmp/api.pid' > /dev/null 2>&1; sleep 0.5; }
fresh() { lab exec ana 'rm -f ~/planner/data/planner.json'; }
fresh; api_start
lab exec ana 'rm -rf ~/.npm/_npx'

block create
CWD=
on 'npx create-next-app@16.4.3 planner-next --ts --app --empty --no-tailwind --no-eslint --no-biome --no-react-compiler --no-src-dir --no-rspack --no-agents-md --import-alias "@/*" --use-npm --disable-git --no-agent-feedback'
CWD=planner-next
block create-look
on 'cat package.json next.config.ts && ls app'
block pin
on "printf 'save-exact=true\\n' > .npmrc && npm install --save-dev @types/node@22.20.5 @types/react@19.3.0 @types/react-dom@19.3.0 typescript@6.0.3"
on "grep -A 5 devDependencies package.json"
block dev
serve 3000 npm run dev
# What the terminal says once the server is up, before any page is asked for:
# serve's own probe of the port is a request ana did not make.
served | grep -v '^ GET /'
block hello
on 'look http://localhost:3000/'

block copy
on 'mkdir lib && cp ../planner/src/types.ts ../planner/src/week.ts lib/ && cp ../planner/src/index.css app/globals.css && ls lib app'
put lib/planner.ts <<'TS'
import type { Course, Session } from './types'

export type Planner = { courses: Course[]; sessions: Session[] }

// Asks the planner's API, from lesson 11, for everything it holds.
export async function getPlanner(): Promise<Planner> {
  const response = await fetch('http://localhost:3001/api/planner')
  if (!response.ok) throw new Error(`HTTP ${response.status} from the planner API`)
  return response.json()
}
TS
put app/layout.tsx <<'TSX'
import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Study planner',
}

export default function RootLayout({ children }: LayoutProps<'/'>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
TSX
put app/Planner.tsx <<'TSX'
import { getPlanner } from '@/lib/planner'
import { formatWeek, inWeek, minutes, mondayOf, today } from '@/lib/week'

type PlannerProps = {
  searchParams: PageProps<'/'>['searchParams']
}

export async function Planner({ searchParams }: PlannerProps) {
  const { week } = await searchParams
  const monday = mondayOf(typeof week === 'string' ? week : today())
  const { courses, sessions } = await getPlanner()
  console.log(`Planner: week of ${monday}, ${sessions.length} sessions`)

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  const done = thisWeek.filter((s) => s.done)
  return (
    <>
      <section aria-label="This week">
        <p>Week of {formatWeek(monday)}</p>
        <p>
          {minutes(done)} of {minutes(thisWeek)} minutes done
        </p>
      </section>
      <section aria-label="Courses">
        {courses.map((course) => {
          const own = thisWeek.filter((s) => s.course === course.id)
          return (
            <article key={course.id} className="card">
              <h2>{course.name}</h2>
              <p>
                {own.length} {own.length === 1 ? 'session' : 'sessions'} · {minutes(own)} min
              </p>
            </article>
          )
        })}
      </section>
    </>
  )
}
TSX
put app/page.tsx <<'TSX'
import { Planner } from './Planner'

export default function Page({ searchParams }: PageProps<'/'>) {
  return (
    <main>
      <h1>Study planner</h1>
      <Planner searchParams={searchParams} />
    </main>
  )
}
TSX
block blocking
on "$N | grep -v '^\$'"
block suspense
put app/page.tsx <<'TSX'
import { Suspense } from 'react'
import { Planner } from './Planner'

export default function Page({ searchParams }: PageProps<'/'>) {
  return (
    <main>
      <h1>Study planner</h1>
      <Suspense fallback={<p>Loading the planner…</p>}>
        <Planner searchParams={searchParams} />
      </Suspense>
    </main>
  )
}
TSX
block server-look
on "$N --network | grep -v '_next/static'"
block server-html
on "curl -s 'http://localhost:3000/?week=2026-10-19' | grep -o '<p>80[^/]*</p>\\|<h2>[^<]*</h2>'"
block server-log
served | grep -E 'Planner:|GET /' | tail -n 4

block onclick
on "sed -i 's|<h2>{course.name}</h2>|<h2><button onClick={() => console.log(course.id)}>{course.name}</button></h2>|' app/Planner.tsx && grep -n onClick app/Planner.tsx"
on "$N | sed -n '/Event handlers/,/Client Component\\./p;/heading/p'"
on "sed -i 's|<h2><button onClick={() => console.log(course.id)}>{course.name}</button></h2>|<h2>{course.name}</h2>|' app/Planner.tsx && grep -c onClick app/Planner.tsx"

block client
put app/WeekKeys.tsx <<'TSX'
'use client'

import { useRouter } from 'next/navigation'
import { useEffect } from 'react'
import { addDays } from '@/lib/week'

// The arrow keys move a week, as lesson 5's did. It draws nothing.
export function WeekKeys({ monday }: { monday: string }) {
  const router = useRouter()

  useEffect(() => {
    function onKey(event: KeyboardEvent) {
      if (event.target instanceof HTMLInputElement) return
      if (event.key === 'ArrowLeft') router.push(`/?week=${addDays(monday, -7)}`)
      if (event.key === 'ArrowRight') router.push(`/?week=${addDays(monday, 7)}`)
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [monday, router])

  return null
}
TSX
put app/Planner.tsx <<'TSX'
import Link from 'next/link'
import { getPlanner } from '@/lib/planner'
import { addDays, formatWeek, inWeek, minutes, mondayOf, today } from '@/lib/week'
import { WeekKeys } from './WeekKeys'

type PlannerProps = {
  searchParams: PageProps<'/'>['searchParams']
}

export async function Planner({ searchParams }: PlannerProps) {
  const { week } = await searchParams
  const monday = mondayOf(typeof week === 'string' ? week : today())
  const { courses, sessions } = await getPlanner()
  console.log(`Planner: week of ${monday}, ${sessions.length} sessions`)

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  const done = thisWeek.filter((s) => s.done)
  return (
    <>
      <nav aria-label="Week">
        <Link href={`/?week=${addDays(monday, -7)}`}>Previous week</Link>{' '}
        <Link href={`/?week=${addDays(monday, 7)}`}>Next week</Link>
      </nav>
      <WeekKeys monday={monday} />
      <section aria-label="This week">
        <p>Week of {formatWeek(monday)}</p>
        <p>
          {minutes(done)} of {minutes(thisWeek)} minutes done
        </p>
      </section>
      <section aria-label="Courses">
        {courses.map((course) => {
          const own = thisWeek.filter((s) => s.course === course.id)
          return (
            <article key={course.id} className="card">
              <h2>{course.name}</h2>
              <p>
                {own.length} {own.length === 1 ? 'session' : 'sessions'} · {minutes(own)} min
              </p>
            </article>
          )
        })}
      </section>
    </>
  )
}
TSX
on 'npx tsc --noEmit && echo no errors'
block client-look
on "$N --network --do 'press ArrowRight' | grep -v '_next/static' | grep -v '^%c'"
block client-link
on "$N --do 'click link Previous week' | grep -E 'Week of|minutes done'"
block client-function
on "sed -i 's|<WeekKeys monday={monday} />|<WeekKeys monday={monday} toWeek={(m: string) => console.log(m)} />|' app/Planner.tsx"
on "$N | grep -A 3 'Functions cannot' | head -n 4"
on "sed -i 's|<WeekKeys monday={monday} toWeek={(m: string) => console.log(m)} />|<WeekKeys monday={monday} />|' app/Planner.tsx && grep -c toWeek app/Planner.tsx"
stop

block build
on 'npm run build'
block shipped
on "grep -rl 'localhost:3001' .next/static | wc -l"
on "grep -rl 'ArrowRight' .next/static | wc -l"
on "grep -rl 'localhost:3001' .next/server | wc -l"

block stream
api_stop; fresh; api_start 2000
serve 3000 npm start
TIMING="curl -s -o /dev/null -w '%{time_starttransfer} %{time_total}\\n' 'http://localhost:3000/?week=2026-10-19' | awk '{ printf \"first byte after %.1f s, last after %.1f s\\n\", \$1, \$2 }'"
run "$TIMING" > /dev/null
on "$TIMING"
on "curl -s 'http://localhost:3000/?week=2026-10-19' | sed 's/<!-- -->//g' | grep -b -o 'Loading the planner…' | head -n 1"
on "curl -s 'http://localhost:3000/?week=2026-10-19' | sed 's/<!-- -->//g' | grep -b -o '80 of 195 minutes done'"
stop

api_stop; fresh
lab save after-$(basename "$PWD")
finish
