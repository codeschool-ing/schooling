---
title: Not found, and failed
version: 1
---

**Two things can go wrong with a course page, and they deserve different screens.** The course may not
exist, which is the student's address and nobody's fault; or the server may not answer, which is
nobody's address and our fault. Ask for a course the planner does not have:

```
ana@dev:~/planner-next$ look http://localhost:3000/courses/latin --today 2026-10-21 | grep -v '^$'
[HMR] connected
- alert
- heading "404" [level=1]
- heading "This page could not be found." [level=2]
ana@dev:~/planner-next$ look http://localhost:3000/courses/latin --today 2026-10-21 | grep -v '^$'
[HMR] connected
- alert
- main:
  - heading "No such course" [level=1]
  - paragraph: The planner has no course at this address.
  - link "Back to the week":
    - /url: /
ana@dev:~/planner-next$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:3000/courses/latin
200
ana@dev:~/planner-next$ curl -s http://localhost:3000/courses/latin | grep -o '<meta name="robots"[^>]*>'
<meta name="robots" content="noindex"/>
```

The first `look` got Next.js's own 404 page: `notFound()` ran, and with no `not-found.tsx` in the
folder, Next.js used its default. The planner's own, in `app/courses/[courseId]/not-found.tsx`:

```tsx
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
```

drew on the second. Then two checks without a browser. **The status is 200**, not 404, and the page
carries a `robots` meta tag that says `noindex`. That is the price of `loading.tsx`: to send the
fallback at once, the server had to send the status line first, before the page had found out that the
course does not exist, and a status that has been sent cannot be changed. Next.js does the next best
thing and tells search engines not to index the page. A check that has to answer 404 runs before
anything streams, in the place lesson 17's loader had: Next.js's proxy, which runs before the page.

**A server that does not answer is a failure, not an absence.** The folder's error boundary,
`app/courses/[courseId]/error.tsx`:

```tsx
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
```

- **It must be a Client Component**, because an error boundary holds state, as lesson 12's class did,
  and offers a button.
- **`retry`**, from Next.js, renders the page again on the server. A page that failed because the
  server was down for a moment then has a second chance, which is what lesson 12 said a retry needs.

With the API stopped:

```
ana@dev:~/planner-next$ look http://localhost:3000/courses/chemistry --today 2026-10-21 | grep -v '^$' | grep -v '^    at '
[HMR] connected
[error] %o
%s TypeError: fetch failed
- alert
- main:
  - heading "The course could not be loaded" [level=1]
  - alert: The planner's server did not answer.
  - button "Try again"
```

The page's `fetch` failed, *TypeError: fetch failed*, in React's console format; the boundary replaced
the page with its heading, an alert and a button. The rest of the application, had there been a layout
around the course, would have stayed.
