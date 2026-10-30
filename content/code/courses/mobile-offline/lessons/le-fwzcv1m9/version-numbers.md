---
title: Version numbers, and the write that names what it read
version: 1
---

**A write that says which version it was made from lets the server see a conflict instead of
guessing at one.** Lesson 13 ended on the question no clock could answer: had the second writer
seen the first write? A version number answers it in one comparison. Every row carries a number,
the server raises it on each write it accepts, and a device sends back the number it read. If the
number has moved on in the meantime, somebody else wrote first, and the device did not know.

This is **optimistic concurrency**: nobody locks the row while they edit, because on a phone that
is offline for an hour a lock would be held for an hour. Writes are allowed to go ahead, and the
rare one that collides is caught when it arrives.

## A server that checks the version

The server below keeps one session, `s3`, at version 1. `GET` returns it; `PUT` accepts a new copy
only if the copy names the version the server holds, and answers **409 Conflict** otherwise, with
the current row in the body so the device does not need a second request to see what changed.
Make the folder `~/planner/versions` and save this there as `server.ts`:

```typescript
// server.ts: sessions with a version number; a write must name the version it read.
import { createServer } from "node:http";

type Session = { id: string; course: string; date: string; minutes: number; done: boolean; version: number };
const sessions = new Map<string, Session>([
  ["s3", { id: "s3", course: "guitar", date: "2026-10-21", minutes: 20, done: false, version: 1 }],
]);

createServer(async (req, res) => {
  const send = (status: number, body: unknown) => {
    res.writeHead(status, { "content-type": "application/json" });
    res.end(JSON.stringify(body) + "\n");
  };
  const id = req.url?.match(/^\/sessions\/(\w+)$/)?.[1] ?? "";
  const current = sessions.get(id);
  if (!current) return send(404, { error: "no such session" });
  if (req.method === "GET") return send(200, current);
  if (req.method !== "PUT") return send(405, { error: "GET or PUT" });

  let raw = "";
  for await (const chunk of req) raw += chunk;
  const write = JSON.parse(raw) as Session;
  if (write.version !== current.version) {
    return send(409, { error: `you read version ${write.version}, the server has ${current.version}`, current });
  }
  const { version: _read, ...fields } = write;
  const next = { id, ...fields, version: current.version + 1 };
  sessions.set(id, next);
  send(200, next);
}).listen(8014, () => console.log("sessions on http://localhost:8014"));
```

Start it in a terminal of its own and leave it running; `Ctrl+C` stops it. Here it was stopped after
a second, to show the line it prints:

```
ana@dev:~/planner/versions$ timeout 1 node server.ts
sessions on http://localhost:8014
```

In a second terminal, play lesson 13's morning with `curl`. The tablet reads the row, then sends its
tick with the version it read. The phone, which read the same version 1 before going offline, sends
its 30 minutes:

```
ana@dev:~/planner/versions$ curl -s http://localhost:8014/sessions/s3
{"id":"s3","course":"guitar","date":"2026-10-21","minutes":20,"done":false,"version":1}
ana@dev:~/planner/versions$ curl -s -X PUT http://localhost:8014/sessions/s3 -d '{"course":"guitar","date":"2026-10-21","minutes":20,"done":true,"version":1}' -w '%{http_code}\n'
{"id":"s3","course":"guitar","date":"2026-10-21","minutes":20,"done":true,"version":2}
200
ana@dev:~/planner/versions$ curl -s -X PUT http://localhost:8014/sessions/s3 -d '{"course":"guitar","date":"2026-10-21","minutes":30,"done":false,"version":1}' -w '%{http_code}\n'
{"error":"you read version 1, the server has 2","current":{"id":"s3","course":"guitar","date":"2026-10-21","minutes":20,"done":true,"version":2}}
409
```

**The phone's write was refused, and it was told why.** That is the whole difference from last
write wins: the server no longer replaces the tablet's row, and the phone learns, in the reply, that
version 2 exists and what it says. The `-w '%{http_code}\n'` at the end of each `curl` prints the
status after the body.

## What the version does not do

A 409 is a question handed back to the device, not an answer. The phone still holds its 30 minutes
and now also holds the server's row; it has to decide what to send next. Sending its copy again with
version 2 would be last write wins with an extra round trip, and it would lose the tick. The section
after next merges the two properly.

HTTP has a standard spelling for the same check. The server sends a version as an `ETag` header, and
the client sends it back in `If-Match`; a mismatch is **412 Precondition Failed**. The course uses
a field in the body because the planner's outbox of lesson 8 stores operations as JSON, and the
version belongs with the operation. Either way the rule is the same: the write carries what it read.
