---
title: When the file is gone
version: 1
---

**A lazy part is a request, and a request can fail.** The interesting case is not a dropped connection
but a deploy. A student opens the planner in the morning; at noon a new version goes out, with new
hashed names, and the old files are deleted from the server. In the afternoon the student, who never
reloaded, clicks a course, and their page asks for a file that no longer exists.

The preview server can play that part. Open the planner, and three seconds later stop the server, the
way a deploy removes the old files, then click a course:

```
ana@dev:~/planner$ look http://localhost:4173/ --today 2026-10-21 --do 'wait 5000' --do 'click button Statistics'
-- wait 5000
-- click button Statistics
[error] Failed to load resource: net::ERR_CONNECTION_REFUSED
[error] TypeError: Failed to fetch dynamically imported module: http://localhost:4173/assets/CourseScreen-rKGK0gfi.js
[error] ErrorBoundary: Failed to fetch dynamically imported module: http://localhost:4173/assets/CourseScreen-rKGK0gfi.js
    at Lazy (<anonymous>)
    at Suspense (<anonymous>)
    at main (<anonymous>)
    at Vt (http://localhost:4173/assets/index-BDKi8Zd8.js:9:55405)
    at Wt (http://localhost:4173/assets/index-BDKi8Zd8.js:9:56812)
    at _ (http://localhost:4173/assets/index-BDKi8Zd8.js:1:9662)
    at Et (http://localhost:4173/assets/index-BDKi8Zd8.js:9:51785)
- main:
  - heading "Study planner" [level=1]
  - alert: Something went wrong, and the planner stopped. Reload the page to start again.
```

The import failed, and **a failed import is an error thrown where the lazy component renders**. It went
up past the `Suspense`, which only handles waiting, and reached the first error boundary above it,
the one lesson 12 put around the whole application. The student sees the root fallback, and for once
its advice is exactly right: a reload fetches the new `index.html`, which names the new files.

Two details in the console:

- **No long message from React this time.** This is the production build, which reports a caught
  error with `console.error` and the error alone; the development build's paragraph about which
  boundary took over is development-only.
- **The component stack is minified.** `Vt`, `Wt` and `Et` are the planner's components, renamed by the
  bundler to save bytes; only React's own `Lazy` and `Suspense`, and the HTML element `main`, keep
  their names. In production, stacks need the **source maps** a build can emit to be read back as the names
  you wrote; lesson 20 covers what a build produces.

The fix that matters is not in the code that loads the file but in how the files are deployed:
**keep the previous version's files on the server for a while after a deploy**, so a page that is
already open can still fetch them. Some hosting platforms do this for you and some replace the whole
folder; it is worth finding out which yours does before the first complaint about a page that broke on
its own.
