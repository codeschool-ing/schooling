---
title: A function the browser calls on the server
version: 1
---

**A Server Function is an `async` function in a file that starts with `'use server'`.** It runs on the
server, and a Client Component, or a form, can call it as if it were local: the framework turns the
call into a request, runs the function, and sends back its result. Lesson 15 met it in an error message,
as the one kind of function allowed across the boundary.

The Next.js planner shows the week but cannot change it. A session should be markable as done, and the
change has to reach the API. `app/actions.ts`:

```ts
'use server'

import { refresh } from 'next/cache'

// Server Functions. The browser calls them; they run here, on the server.

export async function setDone(id: string, done: boolean) {
  const response = await fetch(`http://localhost:3001/api/sessions/${id}`, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ done }),
  })
  if (!response.ok) throw new Error(`HTTP ${response.status} from the planner API`)
  refresh()
}
```

It is the same `PATCH` the Vite planner sends, with one addition: **`refresh()`** tells Next.js that
the page this call came from is out of date, so the response to the call carries the page rendered
again, with the API's new answer in it. It is lesson 11's invalidation, on the server.

Each session of the week becomes a form whose action is that function. `app/SessionList.tsx`:

```tsx
import type { Course, Session } from '@/lib/types'
import { formatDay } from '@/lib/week'
import { setDone } from './actions'

type SessionListProps = {
  sessions: Session[]
  courses: Course[]
}

export function SessionList({ sessions, courses }: SessionListProps) {
  const name = (id: string) => courses.find((c) => c.id === id)?.name ?? id
  const sorted = [...sessions].sort((a, b) => a.date.localeCompare(b.date))
  return (
    <section aria-labelledby="sessions-heading">
      <h2 id="sessions-heading">Sessions this week</h2>
      <ul>
        {sorted.map((s) => (
          <li key={s.id}>
            <form action={setDone.bind(null, s.id, !s.done)}>
              <button type="submit" aria-pressed={s.done}>
                {formatDay(s.date)} · {name(s.course)} · {s.minutes} min
              </button>
            </form>
          </li>
        ))}
      </ul>
    </section>
  )
}
```

- **`setDone.bind(null, s.id, !s.done)`** makes a version of the function with its two arguments
  already filled in. The form calls it with nothing more, and the arguments travel with the request.
- **The button is a toggle**, `aria-pressed`, named by the session itself. A screen reader announces
  it as *pressed* when the session is done, which is the checkbox's meaning with a button's behaviour.
- **There is no `'use client'`.** The list is a Server Component, and a form whose action is a Server
  Function needs no JavaScript of yours in the browser: before the page's code has loaded, the browser
  submits it the way forms have always been submitted.

`Planner` loses its course cards to make room, and renders the list:

```tsx
import Link from 'next/link'
import { getPlanner } from '@/lib/planner'
import { addDays, formatWeek, inWeek, minutes, mondayOf, today } from '@/lib/week'
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
      <SessionList sessions={thisWeek} courses={courses} />
    </>
  )
}
```

```
ana@dev:~/planner-next$ npx tsc --noEmit && echo no errors
no errors
```

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 | sed -n '/This week/,$p'
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Sessions this week":
    - heading "Sessions this week" [level=2]
    - list:
      - listitem:
        - button "Mon 19 Oct · Statistics · 50 min" [pressed]
      - listitem:
        - button "Tue 20 Oct · Spanish · 30 min" [pressed]
      - listitem:
        - button "Wed 21 Oct · Statistics · 40 min"
      - listitem:
        - button "Thu 22 Oct · Organic chemistry · 45 min"
      - listitem:
        - button "Fri 23 Oct · Spanish · 30 min"
- alert
```

The two sessions already done are `[pressed]`. Press Wednesday's:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --network --do 'click button Wed 21 Oct · Statistics · 40 min' | grep -E 'POST|minutes done|Statistics'
-- click button Wed 21 Oct · Statistics · 40 min
net  POST /?week=2026-10-19  200
    - paragraph: 120 of 195 minutes done
        - button "Mon 19 Oct · Statistics · 50 min" [pressed]
        - button "Wed 21 Oct · Statistics · 40 min" [pressed]
```

**One request, a `POST` to the page's own address**, and the page came back with Wednesday pressed and
the week at 120 minutes. The API's terminal shows the rest of the story:

```
----- the API terminal
planner API on http://localhost:3001
GET /api/planner
GET /api/planner
GET /api/planner
GET /api/planner
PATCH /api/sessions/s2
GET /api/planner
```

Every render of the page asks the API once, so the first `GET`s are the visits so far. Then the
**`PATCH`**, from
`setDone`, and **one more `GET`**: that is `refresh()`, the page rendered again on the server, with the
fresh data, inside the answer to the `POST`. The browser asked for nothing else.

```schooling-figure
{"svg": "<svg data-fig=\"round-trip\" viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"One press of a session's button. The browser posts the form to the page's address. On the server, setDone sends PATCH to the API, then refresh renders the page again, which sends GET to the API. The answer to the POST carries the new page, and the browser fits it in.\"><rect x=\"20\" y=\"60\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"82.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the browser</text><text x=\"90.0\" y=\"97.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">POST /?week=…</text><rect x=\"240\" y=\"30\" width=\"220\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the Next.js server</text><rect x=\"256\" y=\"62\" width=\"188\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">setDone('s2', true)</text><rect x=\"256\" y=\"104\" width=\"188\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">refresh() → Planner</text><rect x=\"560\" y=\"60\" width=\"140\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">API :3001</text><text x=\"630.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">PATCH · GET</text><line x1=\"162\" y1=\"80\" x2=\"238\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"238.0,80.0 230.5,83.2 230.5,76.8\" fill=\"var(--phosphor)\"></polygon><line x1=\"446\" y1=\"77\" x2=\"558\" y2=\"77\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,77.0 550.5,80.2 550.5,73.8\" fill=\"var(--amber)\"></polygon><line x1=\"446\" y1=\"119\" x2=\"558\" y2=\"103\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,103.0 551.0,107.2 550.1,100.9\" fill=\"var(--amber)\"></polygon><line x1=\"238\" y1=\"104\" x2=\"162\" y2=\"104\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"162.0,104.0 169.5,100.8 169.5,107.2\" fill=\"var(--amber)\"></polygon><text x=\"200\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the new page</text><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the browser makes one request; the API is asked twice, by the server</text></svg>", "caption": "One request from the browser; the server does the rest and answers with the page."}
```
