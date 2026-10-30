---
title: A server to talk to
version: 1
---

**Until now the planner has read a file and kept every change in memory, so a reload lost them.**
A real app sends its changes to a server and reads them back. This lesson gives the planner a small
API, written with nothing but Node's own modules so that every line of it is here, and then lets a
library do the talking. Save it as `server/api.mjs`, beside `src/` and outside it, because it runs in
Node and never reaches a browser:

```javascript
// server/api.mjs: the planner's API, from lesson 11 on. Node.js and nothing else.
//
//   node server/api.mjs      listens on http://localhost:3001
//
// It keeps the planner in data/planner.json, made from public/courses.json the
// first time. DELAY=ms makes every answer wait that long, to see loading states.
import { randomUUID } from 'node:crypto'
import { mkdir, readFile, writeFile } from 'node:fs/promises'
import { createServer } from 'node:http'

const DATA = new URL('../data/planner.json', import.meta.url)
const SEED = new URL('../public/courses.json', import.meta.url)
const DELAY = Number(process.env.DELAY ?? 0)

async function load() {
  try {
    return JSON.parse(await readFile(DATA, 'utf8'))
  } catch {
    return JSON.parse(await readFile(SEED, 'utf8'))
  }
}

async function save(planner) {
  await mkdir(new URL('.', DATA), { recursive: true })
  await writeFile(DATA, JSON.stringify(planner, null, 2) + '\n')
}

async function readBody(request) {
  let text = ''
  for await (const chunk of request) text += chunk
  return text ? JSON.parse(text) : {}
}

function send(response, status, body) {
  response.writeHead(status, { 'content-type': 'application/json' })
  response.end(JSON.stringify(body))
}

createServer(async (request, response) => {
  await new Promise((resolve) => setTimeout(resolve, DELAY))
  const url = new URL(request.url, 'http://localhost')
  console.log(request.method, url.pathname)
  const planner = await load()

  if (request.method === 'GET' && url.pathname === '/api/planner') {
    return send(response, 200, planner)
  }

  if (request.method === 'POST' && url.pathname === '/api/sessions') {
    const { course, date, minutes } = await readBody(request)
    const valid =
      planner.courses.some((c) => c.id === course) &&
      /^\d{4}-\d\d-\d\d$/.test(date) &&
      Number.isInteger(minutes) && minutes >= 5 && minutes <= 240
    if (!valid) return send(response, 400, { error: 'not a valid session' })
    const session = { id: randomUUID(), course, date, minutes, done: false }
    planner.sessions.push(session)
    await save(planner)
    return send(response, 201, session)
  }

  const match = url.pathname.match(/^\/api\/sessions\/([\w-]+)$/)
  if (request.method === 'PATCH' && match) {
    const session = planner.sessions.find((s) => s.id === match[1])
    if (!session) return send(response, 404, { error: 'no such session' })
    const { done } = await readBody(request)
    if (typeof done !== 'boolean') return send(response, 400, { error: 'done must be true or false' })
    session.done = done
    await save(planner)
    return send(response, 200, session)
  }

  send(response, 404, { error: 'not found' })
}).listen(3001, () => console.log('planner API on http://localhost:3001'))
```

Three routes, which is all the planner needs: **`GET /api/planner`** answers the courses and the
sessions, **`POST /api/sessions`** adds one, and **`PATCH /api/sessions/:id`** changes whether one is
done. The data starts as a copy of `public/courses.json` and is written to `data/planner.json` from
the first change on, so it survives a restart. `DELAY` slows every answer down on purpose, which
lesson 13 uses.

**The server checks everything it receives**, as lesson 10's form did. The form's checks are for the
person typing; these are for whatever reaches the server, which may not be the form at all. A
browser's developer tools can send any request, and an API that trusted its own front end would
accept anything they sent.

`data/` holds state, not code, so it goes in `.gitignore`. Then start the server in a terminal of its
own, and ask it something from another:

```
ana@dev:~/planner$ printf 'data/\n' >> .gitignore && tail -n 2 .gitignore
*.sw?
data/
ana@dev:~/planner$ node server/api.mjs
ana@dev:~/planner$ curl -s http://localhost:3001/api/planner | head -c 160; echo
{"courses":[{"id":"statistics","name":"Statistics"},{"id":"spanish","name":"Spanish"},{"id":"chemistry","name":"Organic chemistry"}],"sessions":[{"id":"s1","cou
ana@dev:~/planner$ curl -s -w ' %{http_code}\n' -X PATCH http://localhost:3001/api/sessions/s2 -H 'content-type: application/json' -d '{"done":true}'
{"id":"s2","course":"statistics","date":"2026-10-21","minutes":40,"done":true} 200
ana@dev:~/planner$ curl -s -X PATCH http://localhost:3001/api/sessions/s2 -H 'content-type: application/json' -d '{"done":"yes"}' -w ' %{http_code}\n'
{"error":"done must be true or false"} 400
ana@dev:~/planner$ curl -s -X POST http://localhost:3001/api/sessions -H 'content-type: application/json' -d '{"course":"statistics","date":"","minutes":30}' -w ' %{http_code}\n'
{"error":"not a valid session"} 400
ana@dev:~/planner$ ls data
planner.json
----- the API terminal
planner API on http://localhost:3001
GET /api/planner
PATCH /api/sessions/s2
PATCH /api/sessions/s2
POST /api/sessions
```

A good change answers 200 with the session as it now is; a malformed one, `"yes"` instead of `true`,
and an empty date answer 400 with a sentence; and the server's own terminal logs each request. The
file in `data/` now exists.

## One address for both

The page is served from `localhost:5173` and the API from `localhost:3001`. A page that fetched from
another port would be making a cross-origin request, which the browser allows only if the server says
so in its headers, and that is `front-quality`'s subject. In development the simpler answer is to
make the page's own server pass `/api` along, which is what Vite's **proxy** does. In
`vite.config.ts`:

```typescript
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': 'http://localhost:3001',
    },
  },
})
```

Vite restarts itself when its configuration changes. From then on, a request for `/api/planner` sent
to Vite is forwarded to port 3001, and the page never knows there are two servers:

```
ana@dev:~/planner$ curl -s http://localhost:5173/api/planner | head -c 80; echo
{"courses":[{"id":"statistics","name":"Statistics"},{"id":"spanish","name":"Span
```

Lesson 20 says more about the proxy and what replaces it in a build.
