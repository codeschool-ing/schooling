---
title: Caching the data, and what it costs
version: 1
---

**`'use cache'` at the top of a function caches what it returns**, and with Cache Components it is
the way to say that a piece of data may be reused. `lib/planner.ts`:

```ts
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
```

- **`'use cache'`** inside the function caches its result. Its arguments, here none, are part of the
  key, so a function with an argument keeps one entry per value.
- **`cacheTag('planner')`** names the entry, so that a change can mark it out of date by name. The next
  section does.
- **`cacheLife('hours')`** says how long it may be reused. The `hours` profile, from Next.js's own
  table, serves the entry for up to an hour, then fetches it again in the background, and throws it away
  after a day without use.

The course page can now be built ahead for every course, if the build knows which courses there are.
`generateStaticParams` tells it, and a `sed` puts it above the page's component:

```
ana@dev:~/planner-next$ sed -i '/^export default async function CoursePage/i export async function generateStaticParams() {\n  const { courses } = await getPlanner()\n  return courses.map((c) => ({ courseId: c.id }))\n}\n' 'app/courses/[courseId]/page.tsx' && sed -n '1,12p' 'app/courses/[courseId]/page.tsx'
import Link from 'next/link'
import { notFound } from 'next/navigation'
import { getPlanner } from '@/lib/planner'
import { formatDay, minutes } from '@/lib/week'

export async function generateStaticParams() {
  const { courses } = await getPlanner()
  return courses.map((c) => ({ courseId: c.id }))
}

export default async function CoursePage({ params }: PageProps<'/courses/[courseId]'>) {
  const { courseId } = await params
ana@dev:~/planner-next$ npm run build | sed -n "/^Route/,\$p"
Route (app)
┌ ◐ /
├ ○ /_not-found
└   /courses/[courseId]
  ├ ◐ /courses/[courseId]
  ├ ○ /courses/statistics
  ├ ○ /courses/spanish
  └ ○ /courses/chemistry


○  (Static)             prerendered as static content
◐  (Partial Prerender)  prerendered as static HTML with dynamic server-streamed content
```

**Three new static pages**, `○ /courses/statistics`, `spanish` and `chemistry`: the build called
`generateStaticParams`, rendered each course with the cached planner, and wrote the result to a file.
`/courses/[courseId]` is still a partial prerender, for a course added after the build: `latin` would
still be looked up per request, and still find nothing.

What that costs is the subject of this whole section. Start the production server, read chemistry's
page, change the data **behind Next.js's back**, with `curl` straight to the API, and read the page
again:

```
ana@dev:~/planner-next$ curl -s http://localhost:3000/courses/chemistry | sed 's/<!-- -->//g' | grep -o '[0-9]* of [0-9]* minutes done'
60 of 105 minutes done
ana@dev:~/planner-next$ curl -s -X PATCH http://localhost:3001/api/sessions/s6 -H 'content-type: application/json' -d '{"done":true}'; echo
{"id":"s6","course":"chemistry","date":"2026-10-22","minutes":45,"done":true}
ana@dev:~/planner-next$ curl -s http://localhost:3000/courses/chemistry | sed 's/<!-- -->//g' | grep -o '[0-9]* of [0-9]* minutes done'
60 of 105 minutes done
```

**60 of 105, before and after.** The API says Thursday's session is done, and the page does not: it
was built from the cached planner, and the entry has an hour to live. Nothing is broken; this is the
cache doing what it was told. Every cache is a promise that a slightly old answer is acceptable, and
`cacheLife` is how long "slightly" is. For somebody else's change, an hour may be fine. For your own,
it is not, and the next section shows why.
