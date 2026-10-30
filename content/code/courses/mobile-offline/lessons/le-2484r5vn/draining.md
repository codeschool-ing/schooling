---
title: Draining it, in order, one at a time
version: 1
---

**The outbox is sent oldest first, one operation at a time, and the drain stops at the first one
the network fails to deliver.** All three rules are about order. An update sent before the create
it updates reaches a server that has never heard of the session, and a delete sent before an
earlier update turns into a 404 followed by a resurrection.

The tempting version sends everything at once, in parallel, because it is faster. It is faster
until two operations on the same session arrive in the other order, which on a mobile network they
will. One at a time costs a round trip each, and for the planner's few dozen operations a day that
is nothing.

## The server

The planner needs something to send to, and this is the smallest that holds the rules: it keeps
sessions in memory, answers `POST`, `PUT`, `DELETE` and `GET`, and refuses a session longer than
240 minutes. It forgets everything when it stops, which is fine for a lesson and is the reason it
is not a real server. Save this as `server.ts`:

```typescript
// server.ts: the planner's server, as small as it can be. It keeps sessions in memory, so a
// restart forgets them, and it holds the one rule a session must meet.
import { createServer } from "node:http";

type Session = { id: string; course: string; date: string; minutes: number };
const sessions = new Map<string, Session>();

function reply(res: import("node:http").ServerResponse, status: number, body: unknown) {
  res.writeHead(status, { "content-type": "application/json" }).end(JSON.stringify(body) + "\n");
}

createServer(async (req, res) => {
  let text = "";
  for await (const chunk of req) text += chunk;
  const [, , id] = (req.url ?? "").split("/"); // /sessions/<id>
  const body = text ? JSON.parse(text) : null;
  console.log(req.method, req.url);

  if (req.method === "GET") return reply(res, 200, [...sessions.values()]);
  if (body && body.minutes > 240) return reply(res, 422, { error: "a session is at most 240 minutes" });
  if (req.method === "POST") {
    if (sessions.has(body.id)) return reply(res, 409, { error: `${body.id} exists` });
    sessions.set(body.id, body);
    return reply(res, 201, body);
  }
  if (!sessions.has(id)) return reply(res, 404, { error: `no session ${id}` });
  if (req.method === "PUT") { sessions.set(id, body); return reply(res, 200, body); }
  if (req.method === "DELETE") { sessions.delete(id); return reply(res, 204, null); }
  reply(res, 405, { error: "method not allowed" });
}).listen(8008, "127.0.0.1", () => console.log("listening on 8008"));
```

Lessons 9 to 12 grow their own copies of this server, one change at a time.

## The drain

`drain.ts` reads the outbox in `seq` order and sends each operation as the HTTP method it stands
for. A success removes the row. A network failure, or a 5xx, stops the drain: the operation is
still there and the next run starts from it. A 4xx is different, and the section after next is
about it. Save this as `drain.ts`:

```typescript
// drain.ts: send the outbox to the server, oldest first, one operation at a time.
import { db } from "./store.ts";

type Op = { seq: number; op: "create" | "update" | "delete"; session: string; body: string | null };
const SERVER = "http://127.0.0.1:8008/sessions";
const method = { create: "POST", update: "PUT", delete: "DELETE" };
const held = new Set<string>(); // sessions with an operation that cannot be sent

for (const o of db.prepare("select seq, op, session, body from outbox order by seq").all() as Op[]) {
  const name = `#${o.seq} ${o.op} ${o.session}`;
  if (held.has(o.session)) { console.log(`${name}: held behind a dead operation`); continue; }
  let res: Response;
  try {
    const url = o.op === "create" ? SERVER : `${SERVER}/${o.session}`;
    res = await fetch(url, { method: method[o.op], headers: { "content-type": "application/json" }, body: o.body ?? undefined });
  } catch {
    console.log(`${name}: server unreachable, stopping`);
    break;
  }
  if (res.ok) {
    db.prepare("delete from outbox where seq = ?").run(o.seq);
    console.log(`${name}: ${res.status}`);
  } else if (res.status >= 500) {
    console.log(`${name}: ${res.status}, stopping`);
    break;
  } else {
    // A 4xx is the server's answer, and it will give the same one every time.
    const reason = `${res.status} ${(await res.json()).error}`;
    db.transaction(() => {
      db.prepare("insert into dead select seq, op, session, body, ? from outbox where seq = ?").run(reason, o.seq);
      db.prepare("delete from outbox where seq = ?").run(o.seq);
    })();
    held.add(o.session);
    console.log(`${name}: ${reason}, moved to dead`);
  }
}
const { n } = db.prepare("select count(*) as n from outbox").get() as { n: number };
console.log(`${n} waiting`);
```

First with no server, which is the train:

```
ana@dev:~/planner/outbox$ node drain.ts
#1 create s7: server unreachable, stopping
3 waiting
```

The first operation failed and the drain stopped there. It did not try `#2` and `#3`, because both
depend on `#1` having arrived. Now start the server in a second terminal, `node server.ts`, leave it
running, and drain again from the first:

```
ana@dev:~/planner/outbox$ node drain.ts
#1 create s7: 201
#2 update s7: 200
#3 create s8: 201
0 waiting
ana@dev:~/planner/outbox$ curl -s http://127.0.0.1:8008/sessions
[{"id":"s7","course":"guitar","date":"2026-10-23","minutes":30},{"id":"s8","course":"statistics","date":"2026-10-24","minutes":40}]
```

Each operation went in the order it was written, and the outbox is empty. The server's terminal
printed a line per request:

```
ana@dev:~/planner/outbox$ node server.ts
listening on 8008
POST /sessions
PUT /sessions/s7
POST /sessions
GET /sessions
```

## When the drain runs

Here you run it by hand. In an app it runs when a change is written and the network is up, when the
network comes back, and when the app is opened. **Each of those can start a drain while another is
still running**, so a real outbox allows one drain at a time: a flag in memory for one process, or a
background job the system runs alone. Lesson 16 is what each platform lets an app do in the
background.
