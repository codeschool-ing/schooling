---
title: When a delta cannot be trusted
version: 1
---

**A delta sync is a promise that the device's copy plus the changes since its cursor equals the
server's data. Four things break the promise, and in each the cheapest correct move is to throw the
copy away and download a new one.** That download is a **full resync**. It costs more than a delta,
and it is still the cheaper option, because the alternative is a copy that is wrong in ways nobody
can see.

| what happened | why a delta cannot fix it |
|---|---|
| the cursor is older than the history the server kept | the tombstones it needs are gone (lesson 11) |
| the app's new version reads the data differently | a delta carries new rows in the new shape, not the old rows reshaped |
| the local file is damaged | deltas assume the copy they patch is sound |
| a different person signs in on the device | the cursor and the rows belong to somebody else |

The first is the one a server has to announce, because only the server knows how far back it
remembers. The others the device detects itself: the second by a schema version the app stores
beside the cursor, the third by SQLite's own `PRAGMA integrity_check` failing, the fourth by the
account id changing. Lesson 5 is how a schema version is kept on the device.

## The server says so

This lesson's folder is `~/planner/resync`. The server is lesson 11's, grown: `POST /forget` drops
every tombstone, as a real server does on a schedule, and remembers that history before that point
is gone. After that, a request with an older cursor is answered with **410 Gone**, the HTTP status
for "this existed and will not again", and a sentence saying what to do. It also hands out the
whole of its live data, with the matching cursor, at `/snapshot`. Save this as `server.ts`:

```typescript
// server.ts: lesson 11's server, grown for this lesson. It can forget old tombstones, and then it
// refuses a cursor older than what it still remembers, with 410 Gone; and it hands out a snapshot.
import { createServer, type ServerResponse } from "node:http";
import { sessions as starting } from "../data.ts";

type Row = { id: string; course: string; date: string; minutes: number; seq: number; deleted?: true };
const rows = new Map<string, Row>();
let seq = 0;
let oldest = 0; // the oldest cursor the server can still answer from

const write = (id: string, fields: Partial<Row>) => rows.set(id, { ...(rows.get(id) ?? {}), ...fields, id, seq: ++seq } as Row);
for (const s of starting) write(s.id, s);

function reply(res: ServerResponse, status: number, body: unknown) {
  res.writeHead(status, { "content-type": "application/json" }).end(JSON.stringify(body));
}

createServer(async (req, res) => {
  let text = "";
  for await (const chunk of req) text += chunk;
  const url = new URL(req.url!, "http://x");
  const n = Number(url.searchParams.get("n") ?? url.searchParams.get("after") ?? 0);
  const live = () => [...rows.values()].filter((r) => !r.deleted);
  if (req.method === "POST" && url.pathname === "/fill") {
    for (let i = 1; i <= n; i++) write(`h${i}`, { course: ["spanish", "statistics", "guitar"][i % 3], date: "2025-01-01", minutes: 15 + (i % 4) * 15 });
    return reply(res, 200, { seq });
  }
  if (req.method === "POST" && url.pathname === "/forget") {
    // Drop every tombstone, and with them the history before now.
    for (const [id, r] of rows) if (r.deleted) rows.delete(id);
    oldest = seq;
    return reply(res, 200, { oldest });
  }
  if (req.method === "DELETE") { write(url.pathname.split("/")[2], { deleted: true }); return reply(res, 200, { seq }); }
  if (req.method === "PUT") { write(url.pathname.split("/")[2], JSON.parse(text)); return reply(res, 200, { seq }); }
  if (url.pathname === "/changes") {
    if (n < oldest) return reply(res, 410, { error: `cursor ${n} is older than ${oldest}; resync` });
    return reply(res, 200, { cursor: seq, changes: [...rows.values()].filter((r) => r.seq > n) });
  }
  if (url.pathname === "/snapshot") return reply(res, 200, { cursor: seq, sessions: live() });
  res.writeHead(404).end();
}).listen(8012, "127.0.0.1", () => console.log("listening on 8012"));
```

Start it in a second terminal with `node server.ts`. A phone that last pulled at cursor 6 is away
while another phone deletes `s3` and the server forgets its tombstones; then it asks for its delta:

```
ana@dev:~/planner/resync$ curl -s -o /dev/null -X DELETE http://127.0.0.1:8012/sessions/s3
ana@dev:~/planner/resync$ curl -s -X POST http://127.0.0.1:8012/forget; echo
{"oldest":7}
ana@dev:~/planner/resync$ curl -s -w ' %{http_code}\n' 'http://127.0.0.1:8012/changes?after=6'
{"error":"cursor 6 is older than 7; resync"} 410
```

The server could have answered with the changes it still has, and the phone would have kept `s3`
for ever, with no way to learn it was deleted. **Saying 410 is the server being honest about the
limit of its memory**, and it is the device's cue for everything the rest of this lesson builds.
