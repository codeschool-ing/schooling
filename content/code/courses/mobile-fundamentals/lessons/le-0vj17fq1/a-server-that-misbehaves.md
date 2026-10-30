---
title: A server that misbehaves on purpose
version: 1
---

**To see what an app does when the network goes wrong, you need a network that goes wrong when you
ask it to.** A lift is hard to arrange at a desk. A server that answers late, answers never, or
fails a few times before it works is twenty lines of Node.js, and it produces the same three
symptoms a phone meets in the street. It runs on your own computer, on port 8014, and nothing
outside it can reach it.

It serves the planner's week, the same five sessions lesson 1 ended with, and it answers on four
paths:

| path | what it does | what it stands for |
|---|---|---|
| `/week` | answers at once with the week's totals | a good day |
| `/slow` | answers the same, three seconds late | a weak signal, or a busy server |
| `/hang` | reads the request and never answers | the lift: the request left, and nothing comes back |
| `/flaky` | fails two calls in every three with status 503, and answers the third | a server restarting, or overloaded for a moment |

Save it in `~/planner` as `api.ts`:

```typescript
// api.ts: a small server for the planner's week, and three ways for it to misbehave
import { createServer } from "node:http";
import { weekTotal, type Plan } from "./planner.ts";

const plan: Plan = {
  courses: [
    { id: "sql", title: "SQL Databases" },
    { id: "mobile", title: "Mobile Fundamentals" },
  ],
  sessions: [
    { id: "s1", courseId: "sql", date: "2026-10-19", minutes: 50, done: true },
    { id: "s2", courseId: "mobile", date: "2026-10-20", minutes: 40, done: true },
    { id: "s3", courseId: "sql", date: "2026-10-23", minutes: 60, done: false },
    { id: "s4", courseId: "mobile", date: "2026-10-27", minutes: 45, done: false },
    { id: "s5", courseId: "mobile", date: "2026-10-22", minutes: 30, done: true },
  ],
};
let flaky = 0; // how many times /flaky has been asked since the server started

createServer((req, res) => {
  const path = new URL(req.url ?? "/", "http://localhost").pathname;
  console.log(req.method, path);
  const send = (status: number, body: unknown) => {
    res.writeHead(status, { "content-type": "application/json" });
    res.end(JSON.stringify(body));
  };
  const week = () => send(200, weekTotal(plan, "2026-10-21"));

  if (path === "/week") return week();
  if (path === "/slow") return void setTimeout(week, 3000); // answers, three seconds late
  if (path === "/hang") return; // reads the request and never answers it
  if (path === "/flaky") return ++flaky % 3 !== 0 ? send(503, { error: "busy" }) : week();
  send(404, { error: "no such path" });
}).listen(8014, "127.0.0.1", () => console.log("listening on http://127.0.0.1:8014"));
```

**`/hang` is one line, and it is the most important one.** The handler returns without writing
anything, so the connection stays open, the request has arrived, and the answer never starts. That
is exactly what a request sent from a lift looks like from the phone's side. Nothing in it is an
error, and nothing in Node.js will close it for a long time, as the next section measures.

`127.0.0.1` in `listen` keeps the server on your own computer: another machine on your Wi-Fi cannot
reach it. The status 503 means *service unavailable*, the answer a server gives when it is
temporarily unable to do the work, and the one a client is allowed to try again.

## Two terminals

**A server runs until you stop it**, so it takes a terminal of its own. Start it in one, and leave
that terminal alone; open a second one for everything else. As requests arrive, the first terminal
prints one line for each. This is what it showed by the end of this section and the next two:

```
ana@dev:~/planner$ node api.ts
listening on http://127.0.0.1:8014
GET /week
GET /slow
GET /flaky
GET /flaky
GET /flaky
GET /hang
GET /hang
GET /hang
GET /hang
GET /slow
GET /slow
GET /flaky
GET /flaky
GET /flaky
GET /flaky
```

Every `GET /hang` in that log is a request that was never answered. The server did not crash and
did not complain. It simply kept the connection open, and it is the client's job to decide how
long to wait.

## Asking it with curl

In the second terminal, `curl` asks each path. `-sS` hides curl's progress meter and
still shows an error, and `-w` prints the status code and the time the whole exchange took after the body:

```
ana@dev:~/planner$ curl -sS -w "  %{http_code} in %{time_total} s\n" http://127.0.0.1:8014/week
{"monday":"2026-10-19","planned":180,"done":120}  200 in 0.002107 s
ana@dev:~/planner$ curl -sS -w "  %{http_code} in %{time_total} s\n" http://127.0.0.1:8014/slow
{"monday":"2026-10-19","planned":180,"done":120}  200 in 3.003513 s
ana@dev:~/planner$ curl -sS -w "  %{http_code} in %{time_total} s\n" http://127.0.0.1:8014/flaky
{"error":"busy"}  503 in 0.002077 s
ana@dev:~/planner$ curl -sS -w "  %{http_code} in %{time_total} s\n" http://127.0.0.1:8014/flaky
{"error":"busy"}  503 in 0.001430 s
ana@dev:~/planner$ curl -sS -w "  %{http_code} in %{time_total} s\n" http://127.0.0.1:8014/flaky
{"monday":"2026-10-19","planned":180,"done":120}  200 in 0.001318 s
ana@dev:~/planner$ curl -sS --max-time 3 -w "  %{http_code} in %{time_total} s\n" http://127.0.0.1:8014/hang; echo "exit $?"
curl: (28) Operation timed out after 3002 milliseconds with 0 bytes received
  000 in 3.002319 s
exit 28
```

`/week` answered in a few milliseconds, `/slow` in a little over three seconds, and `/flaky` failed
twice before it answered on the third call. For `/hang` the transcript gives curl a limit,
`--max-time 3`, and curl gave up and said so with its exit code 28, *operation timed out*. **Without
`--max-time`, that command would still be waiting**, because curl sets no limit on a whole transfer
unless it is asked to. The times on your computer will differ from these in the
last digits. What does not change is which one answers, which one fails and which one never ends.
