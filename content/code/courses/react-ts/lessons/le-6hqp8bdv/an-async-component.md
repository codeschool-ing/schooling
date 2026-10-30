---
title: A component that runs on the server
version: 1
---

**A Server Component can be an `async` function**, and `await` what it needs before it returns its
JSX. There is no effect, no loading state of its own and no request from the browser: the data is
fetched where the component runs, on the server. In Next.js's `app/` folder, every component is a
Server Component unless its file says otherwise.

The Next.js planner reuses what it can from the Vite one: the types, the date arithmetic from lesson 3,
and the stylesheet:

```
ana@dev:~/planner-next$ mkdir lib && cp ../planner/src/types.ts ../planner/src/week.ts lib/ && cp ../planner/src/index.css app/globals.css && ls lib app
app:
globals.css
layout.tsx
page.tsx

lib:
types.ts
week.ts
```

Then one function that asks the API, `lib/planner.ts`:

```ts
import type { Course, Session } from './types'

export type Planner = { courses: Course[]; sessions: Session[] }

// Asks the planner's API, from lesson 11, for everything it holds.
export async function getPlanner(): Promise<Planner> {
  const response = await fetch('http://localhost:3001/api/planner')
  if (!response.ok) throw new Error(`HTTP ${response.status} from the planner API`)
  return response.json()
}
```

This `fetch` runs in Node.js, on the server, so it can name `localhost:3001` directly: no proxy, and
the address never needs to be known to a browser. The root layout, `app/layout.tsx`, gets the planner's
title and imports the stylesheet:

```tsx
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
```

The component that draws the week, `app/Planner.tsx`:

```tsx
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
```

It reads the week from the address, `?week=2026-10-19`, instead of from state, because a Server
Component has no state: it runs once per request and is gone. **`searchParams` is a promise** in this
version of Next.js, and the component awaits it. `PageProps<'/'>` is a type Next.js generates for each
route, with the right shape for that route's `searchParams`. The `console.log` is there to show where
this code runs.

And the page, `app/page.tsx`, draws the heading and the planner:

```tsx
import { Planner } from './Planner'

export default function Page({ searchParams }: PageProps<'/'>) {
  return (
    <main>
      <h1>Study planner</h1>
      <Planner searchParams={searchParams} />
    </main>
  )
}
```

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 | grep -v '^$'
[HMR] connected
%c%s%c Planner: week of 2026-10-19, 6 sessions background: #e6e6e6;background: light-dark(rgba(0,0,0,0.1), rgba(255,255,255,0.25));color: #000000;color: light-dark(#000000, #ffffff);border-radius: 2px  Server  
[error] Error: Route "/": Next.js encountered uncached data during prerendering.
`fetch(...)` or `connection()` accessed outside of `<Suspense>` prevents the route from being prerendered, blocking the page load and leading to a slower user experience.
Ways to fix this:
  - [stream] Provide a placeholder with `<Suspense fallback={...}>` around the data access
  - [cache] Cache the data access with `"use cache"` (does not apply to `connection()`)
  - [block] Set `export const instant = false` to allow a blocking route
Learn more: https://nextjs.org/docs/messages/blocking-prerender-dynamic
    at getPlanner (about://React/Server/file:///home/ana/planner-next/.next/dev/server/chunks/ssr/%255Broot-of-the-server%255D__12kpotjuv4lhr._.js?id=%255Bproject%255D/lib/planner.ts+%255Bapp-rsc%255D+(ecmascript)?16:9:28)
    at Planner (about://React/Server/file:///home/ana/planner-next/.next/dev/server/chunks/ssr/%255Broot-of-the-server%255D__12kpotjuv4lhr._.js?id=%255Bproject%255D/app/Planner.tsx+%255Bapp-rsc%255D+(ecmascript)?17:17:170)
    at Page (about://React/Server/file:///home/ana/planner-next/.next/dev/server/chunks/ssr/%255Broot-of-the-server%255D__12kpotjuv4lhr._.js?id=%255Bproject%255D/app/page.tsx+%255Bapp-rsc%255D+(ecmascript)?18:22:264)
    at resolveErrorDev (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2029:105)
    at getOutlinedModel (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:1568:28)
    at parseModelString (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:1688:50)
    at reviveModel (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2634:66)
    at reviveModel (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2637:61)
    at reviveModel (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2716:112)
    at parseModel (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2629:16)
    at initializeModelChunk (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:1141:25)
    at resolveModelChunk (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:1039:43)
    at processFullStringRow (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2585:371)
    at processFullBinaryRow (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2507:9)
    at processBinaryChunk (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2614:221)
    at progress (http://localhost:3000/_next/static/chunks/node_modules_next_dist_compiled_react-server-dom-turbopack_164kp-67asdr9._.js:2801:13)
- main:
  - heading "Study planner" [level=1]
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 2 sessions · 90 min
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 2 sessions · 60 min
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 1 session · 45 min
- alert
```

The page drew: the week, the 80 of 195 minutes, the three courses. **And Next.js printed an error
anyway**, which is Cache Components at work. With it on, Next.js tries to build every page ahead of
time as a static shell, and anything that cannot be known ahead of time, such as a `fetch` whose
answer may change, has to say what to show until it arrives. A page that does not say so would make
the browser wait for the whole of it, and the message names three ways out. The first, `[stream]`, is
lesson 13's tool, now on the server: `Suspense`, with a fallback.

```tsx
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
```

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --network | grep -v '_next/static'
net  GET /?week=2026-10-19  200
[HMR] connected
%c%s%c Planner: week of 2026-10-19, 6 sessions background: #e6e6e6;background: light-dark(rgba(0,0,0,0.1), rgba(255,255,255,0.25));color: #000000;color: light-dark(#000000, #ffffff);border-radius: 2px  Server  
- main:
  - heading "Study planner" [level=1]
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 2 sessions · 90 min
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 2 sessions · 60 min
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 1 session · 45 min
- alert
```

No error now. And look at the network: **one request, for the page**, and nothing to `/api/planner`
(the `grep` hid only Next.js's own JavaScript files). The browser never asked for the data, because the
data came inside the page.
