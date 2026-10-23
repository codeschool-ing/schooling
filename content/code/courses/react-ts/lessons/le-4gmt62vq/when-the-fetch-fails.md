---
title: When the fetch fails, and when it only looks as if it worked
version: 1
---

**A failed request can arrive with status 200.** This section misspells the file's name to see what
the planner does with a request that goes wrong, and the answer is more instructive than expected.

```
ana@dev:~/planner$ sed -i "s|fetch('/courses.json')|fetch('/course.json')|" src/App.tsx
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network | grep -v 'GET /[@sn]'
net  GET /  200
net  GET /course.json  200
net  GET /course.json  200
[error] could not load the planner: Unexpected token '<', "<!doctype "... is not valid JSON
- alert: The planner could not be loaded.
ana@dev:~/planner$ curl -s -i http://localhost:5173/course.json | head -n 4
HTTP/1.1 200 OK
Vary: Origin
Content-Type: text/html
Cache-Control: no-cache
ana@dev:~/planner$ sed -i "s|fetch('/course.json')|fetch('/courses.json')|" src/App.tsx
```

The planner did the right thing in the end: the console has the error, and the screen says the
planner could not be loaded, as an `alert`, which a screen reader announces as soon as it appears.
But read how it got there. **`/course.json` answered 200**, twice, strict mode again. The `curl` shows
why: the development server answers any address it does not recognise with the app's `index.html`,
so that an app with its own addresses, lesson 17's subject, can be opened at any of them. The status
was fine, `response.ok` was true, and the failure came one step later, when `response.json()` met
`<!doctype` instead of JSON.

So the planner caught it, but by luck: it caught a parsing error, not a missing file. Three things
make that luck into a design:

- **Check the status, and then check the shape.** `response.ok` catches a server that says no. Only
  parsing, and lesson 10's schema validation, catches a server that says yes and sends the wrong
  thing.
- **Say what happened on the console, and something useful on the screen.** The console line has the
  real reason; the screen has a sentence a user can act on. Lesson 12 gives the screen a way to offer
  a retry.
- **Every request has three outcomes**, and each needs a screen: still waiting, arrived, failed. The
  planner's `status` is those three. A component that only draws the second shows an empty list while
  it waits, which looks exactly like a planner with no courses.

When the development server is not running at all, the page itself never loads, and lesson 1's
`ERR_CONNECTION_REFUSED` is what you see. In the build you publish, a missing file is a real 404, and
the `response.ok` check is the one that catches it.
