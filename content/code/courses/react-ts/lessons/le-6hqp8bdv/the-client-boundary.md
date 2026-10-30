---
title: The client boundary
version: 1
---

**Interactivity needs code in the browser, and a Server Component has none there.** Try to make a
course's name a button that logs a click, with `sed` so that the change is one line:

```
ana@dev:~/planner-next$ sed -i 's|<h2>{course.name}</h2>|<h2><button onClick={() => console.log(course.id)}>{course.name}</button></h2>|' app/Planner.tsx && grep -n onClick app/Planner.tsx
29:              <h2><button onClick={() => console.log(course.id)}>{course.name}</button></h2>
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 | sed -n '/Event handlers/,/Client Component\./p;/heading/p'
Uncaught Error: Event handlers cannot be passed to Client Component props.
  <button onClick={function onClick} children=...>
                  ^^^^^^^^^^^^^^^^^^
If you need interactivity, consider converting part of this to a Client Component.
- heading "This page couldn’t load" [level=1]
ana@dev:~/planner-next$ sed -i 's|<h2><button onClick={() => console.log(course.id)}>{course.name}</button></h2>|<h2>{course.name}</h2>|' app/Planner.tsx && grep -c onClick app/Planner.tsx
0
```

The page broke: **Event handlers cannot be passed to Client Component props.** The JSX the server
produces has to travel to the browser as data, and a function, the `onClick`, cannot be turned into
data: it is code, with variables around it, on a machine the browser cannot reach. The page became
Next.js's error page, *This page couldn't load*. The last `sed` put the line back.

**`'use client'` at the top of a file marks the boundary.** That file, and everything it imports, is
sent to the browser and runs there; it can use state, effects and handlers. The planner in lesson 5
moved a week with the arrow keys, and that needs an effect and a listener on `window`, so it becomes a
Client Component, `app/WeekKeys.tsx`:

```tsx
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
```

`useRouter` is Next.js's: `router.push` goes to another address without reloading the page. The
component draws nothing, `return null`, so it can sit anywhere. The planner renders it, and gains two
links for the same moves without a keyboard:

```tsx
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
```

The `Link`s are ordinary links, drawn by the server, which work before any JavaScript has loaded;
Next.js makes them faster once it has. `WeekKeys` is the only part that needs the browser, and the
server passes it one string, `monday`.

```
ana@dev:~/planner-next$ npx tsc --noEmit && echo no errors
no errors
```

Press the right arrow:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --network --do 'press ArrowRight' | grep -v '_next/static' | grep -v '^%c'
net  GET /?week=2026-10-19  200
[HMR] connected
-- press ArrowRight
net  GET /?week=2026-10-26&_rsc=bDxByZpqNar9PdVL  200
- main:
  - heading "Study planner" [level=1]
  - navigation "Week":
    - link "Previous week":
      - /url: /?week=2026-10-19
    - link "Next week":
      - /url: /?week=2026-11-02
  - region "This week":
    - paragraph: Week of 26 Oct 2026
    - paragraph: 0 of 0 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 0 sessions · 0 min
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 0 sessions · 0 min
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 0 sessions · 0 min
- alert
```

**The week of 26 October, with no new page loaded.** The request after the key press is not for
`/api/planner`: it is for the page itself, `/?week=2026-10-26`, with `_rsc` added, which asks the
server for the new week's Server Components as data rather than as HTML. The server fetched from the
API, rendered the planner, and sent the result; the browser fitted it into the page it already had. The
links do the same:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'click link Previous week' | grep -E 'Week of|minutes done'
    - paragraph: Week of 12 Oct 2026
    - paragraph: 60 of 60 minutes done
```

The week before, with its 60 minutes of chemistry, all done.
