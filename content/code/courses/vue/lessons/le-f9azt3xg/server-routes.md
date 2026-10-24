---
title: Server routes, an API in the same project
version: 1
---

**A file in `server/api/` is an endpoint of the server Nuxt runs, and its name says the address and the
method: `server/api/courses.get.ts` answers `GET /api/courses`.** The Vite planner read a file Vite
served from `public`, and could not change it: ticking a session changed the browser's copy, which
lesson 4 saved in `localStorage`. With a server of its own, the planner can keep its data where every
browser sees the same thing.

The data is the `courses.json` copied in the last section. A module in `server/utils/` holds it while
the server runs, and `server/utils`, like `shared/utils`, is auto-imported, though only into the
server's code:

```typescript
// server/utils/planner-data.ts: the planner's data, held by the server while it runs.
import data from '../data/courses.json'

// A copy, so that a change is made to the server's data and never to the import.
export const planner: { courses: Course[]; sessions: Session[] } = structuredClone(data)
```

The endpoint that reads it is one line:

```typescript
// server/api/courses.get.ts: GET /api/courses, every course and every session.
export default defineEventHandler(() => planner)
```

`defineEventHandler` takes a function of the request, the *event*, and whatever it returns is the
response, an object turned into JSON. Ask for it:

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/api/courses | head -12
{
  "courses": [
    {
      "id": "statistics",
      "title": "Statistics",
      "goal": 180
    },
    {
      "id": "spanish",
      "title": "Spanish",
      "goal": 120
    },
```

## A route that changes something

Ticking a session is a `PATCH` to the session's own address. The square brackets work as they do in
`pages`, so `[id].patch.ts` in `server/api/sessions/` answers `PATCH /api/sessions/s4` and every other
id:

```typescript
// server/api/sessions/[id].patch.ts: PATCH /api/sessions/s4 ticks or unticks s4.
export default defineEventHandler((event) => {
  const id = getRouterParam(event, 'id')
  if (!planner.sessions.some((s) => s.id === id)) {
    throw createError({ statusCode: 404, statusMessage: `No session ${id}` })
  }
  planner.sessions = toggleDone(planner.sessions, id!)
  return planner.sessions.find((s) => s.id === id)
})
```

`toggleDone` is lesson 3's, reached through `shared/utils`, the same function the browser used to
call. The handler refuses an id it does not have **before** it changes anything, with a `404` the
client can tell apart from a success. Try a real session and a made-up one:

```
ana@dev:~/vue/planner-nuxt$ curl -s -X PATCH http://localhost:3000/api/sessions/s4
{
  "id": "s4",
  "course": "statistics",
  "date": "2026-10-21",
  "minutes": 60,
  "done": true
}ana@dev:~/vue/planner-nuxt$ curl -s -X PATCH http://localhost:3000/api/sessions/s99
{
  "error": true,
  "url": "http://localhost:3000/api/sessions/s99",
  "statusCode": 404,
  "statusMessage": "No session s99",
  "message": "No session s99",
  "stack": [
    "No session s99",
    "at createError (/home/ana/vue/planner-nuxt/node_modules/h3/dist/index.mjs:71:15)",
    "at Object.handler (/home/ana/vue/planner-nuxt/server/api/sessions/[id].patch.ts:5:10)",
    "at Object.handler (/home/ana/vue/planner-nuxt/node_modules/h3/dist/index.mjs:1940:24)",
    "at Object.handler (/home/ana/vue/planner-nuxt/node_modules/h3/dist/index.mjs:2263:34)",
    "at /home/ana/vue/planner-nuxt/node_modules/h3/dist/index.mjs:2017:31)",
    "at process.processTicksAndRejections (node:internal/process/task_queues:103:5)",
    "at async Object.callAsync (/home/ana/vue/planner-nuxt/node_modules/nitropack/node_modules/unctx/dist/index.mjs:72:16)",
    "at async Server.toNodeHandle (/home/ana/vue/planner-nuxt/node_modules/h3/dist/index.mjs:2316:7)"
  ]
}ana@dev:~/vue/planner-nuxt$ curl -s -o /dev/null -w '%{http_code}\n' http://localhost:3000/api/sessions/s4
404
```

**s4 is done now, and `s99` is a `404` with the message the handler wrote.** In development the error
also carries a `stack`, the path through the server's files; a build leaves it out, because the files
of a server are nobody else's business. A `GET` of the same address is a `404` of Nuxt's own, since no
`[id].get.ts` exists. Tick s4 again so the next section starts from the data as it was:

```
ana@dev:~/vue/planner-nuxt$ curl -s -X PATCH http://localhost:3000/api/sessions/s4 | grep done
  "done": false
```

## What this server is not yet

**The data lives in memory, so a restart of the server puts it back to `courses.json`.** For a planner
studied on one computer that is a fair trade, and a real one would write to a database, or to a file
through Nitro's storage layer. And **anybody who can reach port 3000 can tick anybody's session**: the
endpoints check that the session exists and nothing else. That is fine while the server answers only
`localhost`, which is what `use --host to expose` in the dev server's banner means. The day the
planner is on the internet, every route that changes something needs to know who is asking, which is
the work of a sign-in and outside this course.
