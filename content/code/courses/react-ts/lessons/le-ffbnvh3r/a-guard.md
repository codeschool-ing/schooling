---
title: A loader as a guard
version: 1
---

**An address can name something that does not exist**, and someone will type one. The loader is the
place to catch it, because it runs before the screen: a screen that is never drawn cannot crash on a
course that is not there. Ask for a course the planner does not have, and for an address no route
matches:

```
ana@dev:~/planner$ look http://localhost:5173/courses/latin --today 2026-10-21
- main:
  - heading "Study planner" [level=1]
  - alert: "404: There is no course called “latin”."
  - link "Back to this week":
    - /url: /
ana@dev:~/planner$ look http://localhost:5173/no/such/page --today 2026-10-21
- main:
  - heading "Study planner" [level=1]
  - alert: "404: Error: No route matches URL \"/no/such/page\""
  - link "Back to this week":
    - /url: /
```

Both reached `src/RouteError.tsx`, the `ErrorBoundary` of the route at `/`:

```tsx
import { isRouteErrorResponse, Link, useRouteError } from 'react-router'

export function RouteError() {
  const error = useRouteError()
  const message = isRouteErrorResponse(error)
    ? `${error.status}: ${error.data}`
    : error instanceof Error
      ? error.message
      : 'Something went wrong.'
  return (
    <main>
      <h1>Study planner</h1>
      <p role="alert">{message}</p>
      <Link to="/">Back to this week</Link>
    </main>
  )
}
```

- **`throw data(…, { status: 404 })`** in the loader stopped the route before it was drawn, and the
  router took the nearest `ErrorBoundary` instead, with the thrown value from `useRouteError()`.
  `isRouteErrorResponse` recognises a thrown `data()` and gives its `status` and its `data`, here the
  sentence.
- **An address no route matches** is the router's own 404, through the same boundary, with its own
  sentence: *No route matches URL*.
- **Anything else thrown while rendering a route**, an ordinary `Error`, arrives here too, and the
  boundary shows its message. A route's `ErrorBoundary` is lesson 12's error boundary, given to each
  route.

**That is the shape of every route guard.** The usual example is a page only signed-in users may see:
its loader checks the session and, when there is none, `throw redirect('/login')`, which sends the
browser elsewhere before anything private is drawn. The planner has no accounts, so its guard is the
404, but the mechanism is the same: **a loader runs first, and can refuse**.

One thing the development server does for you, and a real server will not unless asked: Vite answers
`/courses/latin` and `/no/such/page` with `index.html`, so that the router in the browser can decide.
A server that only has the files from `npm run build` would answer those addresses with its own 404,
before any JavaScript runs. Deploying a single-page app means telling the server to answer every
address that is not a file with `index.html`.
