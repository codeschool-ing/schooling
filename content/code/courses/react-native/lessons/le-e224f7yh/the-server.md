---
title: A server in twenty lines
version: 1
---

**The planner's server answers two requests.** `GET /plan` returns the whole plan, and `POST
/sessions/<id>/done` marks one session done. It keeps the plan in memory, so it forgets every change when
it stops, which is exactly right for a server whose job is to be talked to in a lesson. Save it in the
project as `server.mjs`:

```javascript
// server.mjs: the planner's server: the plan, and one way to change it.
// It keeps the plan in memory, so it starts from src/courses.json every time it starts.
import { readFileSync } from "node:fs";
import { createServer } from "node:http";

const plan = JSON.parse(readFileSync("src/courses.json", "utf8"));
const headers = {
  "content-type": "application/json",
  "access-control-allow-origin": "*", // the web build is served from another port
  "access-control-allow-methods": "GET, POST",
};

createServer((req, res) => {
  console.log(req.method, req.url);
  const done = req.url?.match(/^\/sessions\/([\w-]+)\/done$/);
  if (req.method === "OPTIONS") return res.writeHead(204, headers).end();
  if (req.method === "GET" && req.url === "/plan") return res.writeHead(200, headers).end(JSON.stringify(plan));
  if (req.method === "POST" && done) {
    const session = plan.sessions.find((s) => s.id === done[1]);
    if (!session) return res.writeHead(404, headers).end(JSON.stringify({ error: `no session ${done[1]}` }));
    session.done = true;
    return res.writeHead(200, headers).end(JSON.stringify(session));
  }
  res.writeHead(404, headers).end(JSON.stringify({ error: "not found" }));
}).listen(8008, () => console.log("listening on 8008"));
```

The `access-control-allow-*` headers let the web build, served from another port, call it: a browser
refuses a cross-origin answer unless the server says it may be read. A phone does not apply that rule,
and the headers do no harm there. Start it in a third terminal and leave it running:

```sh
node server.mjs
```

Then talk to it with `curl`, before the app does:

```
ana@dev:~/planner$ curl -s localhost:8008/plan | head -c 150; echo
{"courses":[{"id":"spanish","name":"Spanish A2"},{"id":"statistics","name":"Statistics"},{"id":"guitar","name":"Guitar"}],"sessions":[{"id":"s1","cour
ana@dev:~/planner$ curl -s -i -X POST localhost:8008/sessions/s9/done | head -1
HTTP/1.1 404 Not Found
ana@dev:~/planner$ curl -s -i -X POST localhost:8008/sessions/s9/done | tail -1; echo
{"error":"no session s9"}
```

The plan comes back as the JSON of lesson 3. `s9` does not exist, and the server says so with a 404 and a
sentence, which is what the app will need when it gets something wrong.

## The app's side

The two requests, as functions, in a file that knows nothing about screens. Save it as `src/api.ts`:

```typescript
// src/api.ts: the two requests the planner makes, and nothing about screens.
import type { Plan, Session } from "./planner";

const BASE = process.env.EXPO_PUBLIC_API_URL ?? "http://localhost:8008";

async function json<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(BASE + path, init);
  if (!res.ok) throw new Error(`${init?.method ?? "GET"} ${path} answered ${res.status}`);
  return (await res.json()) as T;
}

export const fetchPlan = () => json<Plan>("/plan");
export const sendDone = (id: string) => json<Session>(`/sessions/${id}/done`, { method: "POST" });
```

**`fetch` resolves even for a 404 or a 500**; only a network failure rejects it. `json` turns any answer
that is not `ok` into an error with the method, the path and the status in it, so that a server refusing
looks to the rest of the app exactly like a server that could not be reached.

`EXPO_PUBLIC_API_URL` is read when Metro **bundles** the app: Expo replaces `process.env.EXPO_PUBLIC_…` with
the value it had at that moment, so a build is made for one server. On a phone, `localhost` is the phone
itself; to reach the server on your computer from Expo Go, the bundle must name the computer's address on
the Wi-Fi, such as `EXPO_PUBLIC_API_URL=http://192.168.1.20:8008 npx expo start`. *That was not run for
this course*, which had no phone; the web build of the last section names `localhost`, which is right for
a browser on the same computer.
