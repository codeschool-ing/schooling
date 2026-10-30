#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 17's captures.sh
#
# Works in ~/planner-next as lesson 16 left it (lesson 17 changed only
# ~/planner). What is STAGED rather than typed: the files ana wrote, put below
# and shown in the lesson; the API server and the Next.js servers, which ana
# runs in terminals of their own and the script starts in the background (the
# API stopped where the lesson says so); data/planner.json, deleted before each
# demonstration so that each starts from the seed data; and the page's date,
# Wednesday 21 October 2026, set with --today.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-ffbnvh3r
CWD=planner-next
U=http://localhost:3000
T='--today 2026-10-21'
api_start() { lab exec ana "cd ~/planner && (DELAY=${1:-0} setsid node server/api.mjs > /tmp/api.out 2>&1 < /dev/null & echo \$! > /tmp/api.pid)"; sleep 1; }
api_stop() { lab exec ana 'kill $(cat /tmp/api.pid) 2>/dev/null; pkill -u ana -f server/api.mjs; rm -f /tmp/api.pid' > /dev/null 2>&1; sleep 0.5; }
fresh() { lab exec ana 'rm -f ~/planner/data/planner.json'; }
fresh; api_start

block folder
put 'app/courses/[courseId]/page.tsx' <<'TSX'
import Link from 'next/link'
import { notFound } from 'next/navigation'
import { getPlanner } from '@/lib/planner'
import { formatDay, minutes } from '@/lib/week'

export default async function CoursePage({ params }: PageProps<'/courses/[courseId]'>) {
  const { courseId } = await params
  const { courses, sessions } = await getPlanner()
  const course = courses.find((c) => c.id === courseId)
  if (!course) notFound()

  const own = sessions
    .filter((s) => s.course === course.id)
    .sort((a, b) => a.date.localeCompare(b.date))
  const done = own.filter((s) => s.done)
  return (
    <main>
      <Link href="/">Back to the week</Link>
      <h1>{course.name}</h1>
      <p>
        {minutes(done)} of {minutes(own)} minutes done
      </p>
      <ul>
        {own.map((s) => (
          <li key={s.id}>
            {formatDay(s.date)} · {s.minutes} min{s.done && ' · done'}
          </li>
        ))}
      </ul>
    </main>
  )
}
TSX
serve 3000 npm run dev
on "look $U/courses/chemistry $T | grep -v '^\$'"

block loading
put 'app/courses/[courseId]/loading.tsx' <<'TSX'
export default function Loading() {
  return <p>Loading the course…</p>
}
TSX
on "look $U/courses/chemistry $T | grep -v '^\$'"

block not-found
on "look $U/courses/latin $T | grep -v '^\$'"
put 'app/courses/[courseId]/not-found.tsx' <<'TSX'
import Link from 'next/link'

export default function CourseNotFound() {
  return (
    <main>
      <h1>No such course</h1>
      <p>The planner has no course at this address.</p>
      <Link href="/">Back to the week</Link>
    </main>
  )
}
TSX
on "look $U/courses/latin $T | grep -v '^\$'"
on "curl -s -o /dev/null -w '%{http_code}\\n' $U/courses/latin"
on "curl -s $U/courses/latin | grep -o '<meta name=\"robots\"[^>]*>'"

block error
put 'app/courses/[courseId]/error.tsx' <<'TSX'
'use client'

export default function CourseError({ retry }: { error: unknown; retry: () => void }) {
  return (
    <main>
      <h1>The course could not be loaded</h1>
      <p role="alert">The planner's server did not answer.</p>
      <button type="button" onClick={() => retry()}>
        Try again
      </button>
    </main>
  )
}
TSX
api_stop
on "look $U/courses/chemistry $T | grep -v '^\$' | grep -v '^    at '"
api_start

block links
put app/Planner.tsx <<'TSX'
import Link from 'next/link'
import { getPlanner } from '@/lib/planner'
import { addDays, formatWeek, inWeek, minutes, mondayOf, today } from '@/lib/week'
import { AddSession } from './AddSession'
import { SessionList } from './SessionList'
import { WeekKeys } from './WeekKeys'

type PlannerProps = {
  searchParams: PageProps<'/'>['searchParams']
}

export async function Planner({ searchParams }: PlannerProps) {
  const { week } = await searchParams
  const monday = mondayOf(typeof week === 'string' ? week : today())
  const { courses, sessions } = await getPlanner()

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
      <nav aria-label="Courses">
        <ul>
          {courses.map((c) => (
            <li key={c.id}>
              <Link href={`/courses/${c.id}`}>{c.name}</Link>
            </li>
          ))}
        </ul>
      </nav>
      <SessionList sessions={thisWeek} courses={courses} />
      <AddSession courses={courses} />
    </>
  )
}
TSX
on "look '$U/?week=2026-10-19' $T --network --do 'click link Spanish' | grep -E 'GET /courses|_rsc|^-- |heading|paragraph'"
stop

block modes
on 'npm run build | sed -n "/^Route/,\$p"'

block cache
put lib/planner.ts <<'TS'
import { cacheLife, cacheTag } from 'next/cache'
import type { Course, Session } from './types'

export type Planner = { courses: Course[]; sessions: Session[] }

// Asks the planner's API, from lesson 11, for everything it holds. The answer
// is cached, tagged 'planner', so that a change can say it is out of date.
export async function getPlanner(): Promise<Planner> {
  'use cache'
  cacheTag('planner')
  cacheLife('hours')
  const response = await fetch('http://localhost:3001/api/planner')
  if (!response.ok) throw new Error(`HTTP ${response.status} from the planner API`)
  return response.json()
}
TS
on "sed -i '/^export default async function CoursePage/i export async function generateStaticParams() {\\n  const { courses } = await getPlanner()\\n  return courses.map((c) => ({ courseId: c.id }))\\n}\\n' 'app/courses/[courseId]/page.tsx' && sed -n '1,12p' 'app/courses/[courseId]/page.tsx'"
on 'npm run build | sed -n "/^Route/,\$p"'

block stale
fresh
serve 3000 npm start
on "curl -s $U/courses/chemistry | sed 's/<!-- -->//g' | grep -o '[0-9]* of [0-9]* minutes done'"
on "curl -s -X PATCH http://localhost:3001/api/sessions/s6 -H 'content-type: application/json' -d '{\"done\":true}'; echo"
on "curl -s $U/courses/chemistry | sed 's/<!-- -->//g' | grep -o '[0-9]* of [0-9]* minutes done'"
block own-write
on "look '$U/?week=2026-10-19' $T --do 'click button Wed 21 Oct · Statistics · 40 min' --do 'wait 2000' | grep -E 'minutes done|Statistics ·'"
stop

block update
on "sed -i 's/import { refresh } from .next\\/cache./import { updateTag } from '\\''next\\/cache'\\''/; s/^  refresh()/  updateTag('\\''planner'\\'')/' app/actions.ts && grep -n 'updateTag\\|refresh' app/actions.ts"
on 'npm run build > /dev/null && echo built'
fresh
serve 3000 npm start
on "look '$U/?week=2026-10-19' $T --do 'click button Wed 21 Oct · Statistics · 40 min' --do 'wait 2000' | grep -E 'minutes done|Statistics ·'"
on "curl -s $U/courses/statistics | sed 's/<!-- -->//g' | grep -o '[0-9]* of [0-9]* minutes done'"
stop

api_stop; fresh
lab save after-$(basename "$PWD")
finish
