---
title: Pulling everything, and what it costs
version: 1
---

**Lessons 8 to 10 sent the device's changes to the server. This lesson brings the server's changes
to the device: what another phone of the same person wrote, or what the server itself changed.**
The first version anybody writes asks for everything and replaces the local copy with it. It is
correct, and it is the right thing to measure before replacing.

## The server, with a sequence

This lesson's folder is `~/planner/delta`. The server is lesson 10's, grown in one direction: **every
write it accepts gets the next number of a single sequence**, and a row remembers the number of its
last write. A delete does not remove the row; it marks it, and the last section of the lesson says
why. It also carries a stamp, the time the writing phone said it was, which the third section is
about. It starts with lesson 1's six sessions, and `POST /fill` adds as many more as you ask for, the
same ones on every run, so you can measure a planner with a few years in it. Save this as
`server.ts`:

```typescript
// server.ts: lesson 10's server, grown for this lesson. Every write gets the next number in one
// sequence, and a delete leaves a tombstone, so a client can ask what changed after a number.
import { createServer, type ServerResponse } from "node:http";
import { sessions as starting } from "../data.ts";

type Row = { id: string; course: string; date: string; minutes: number; seq: number; stamp: string; deleted?: true };
const rows = new Map<string, Row>();
let seq = 0;

function write(id: string, fields: Partial<Row>, stamp: string) {
  rows.set(id, { ...(rows.get(id) ?? {}), ...fields, id, seq: ++seq, stamp } as Row);
}
for (const s of starting) write(s.id, s, "2026-10-19T08:00:00Z");

function reply(res: ServerResponse, body: unknown) {
  res.writeHead(200, { "content-type": "application/json" }).end(JSON.stringify(body));
}

createServer(async (req, res) => {
  let text = "";
  for await (const chunk of req) text += chunk;
  const url = new URL(req.url!, "http://x");
  const id = url.pathname.split("/")[2];
  if (req.method === "POST" && url.pathname === "/fill") {
    // A planner with a few years in it: n more sessions, the same ones on every run.
    for (let i = 1; i <= Number(url.searchParams.get("n")); i++) {
      write(`h${i}`, { course: ["spanish", "statistics", "guitar"][i % 3], date: "2025-01-01", minutes: 15 + (i % 4) * 15 }, "2026-10-19T08:00:00Z");
    }
    return reply(res, { seq });
  }
  if (req.method === "PUT") { write(id, JSON.parse(text), url.searchParams.get("stamp")!); return reply(res, rows.get(id)); }
  if (req.method === "DELETE") { write(id, { deleted: true }, url.searchParams.get("stamp")!); return reply(res, rows.get(id)); }
  const all = [...rows.values()];
  if (url.pathname === "/sessions") return reply(res, all.filter((r) => !r.deleted));
  if (url.pathname === "/changes") {
    const after = Number(url.searchParams.get("after") ?? 0);
    return reply(res, { cursor: seq, changes: all.filter((r) => r.seq > after) });
  }
  if (url.pathname === "/changed-since") {
    const t = url.searchParams.get("t")!;
    return reply(res, all.filter((r) => r.stamp > t && !r.deleted));
  }
  res.writeHead(404).end();
}).listen(8011, "127.0.0.1", () => console.log("listening on 8011"));
```

The device side keeps a copy in SQLite and a bookmark, `cursor`, in a table of its own. `all` asks
for every session and replaces the copy; `delta` asks only for what changed after the bookmark,
which the next section uses. Save this as `pull.ts`:

```typescript
// pull.ts: bring the device's copy up to date, all of it or only what changed.
// node pull.ts all | node pull.ts delta
import Database from "better-sqlite3";

const SERVER = "http://127.0.0.1:8011";
const db = new Database("planner.db");
db.exec(`create table if not exists sessions (id text primary key, course text, date text, minutes integer);
         create table if not exists meta (name text primary key, value text)`);
const cursor = () => Number((db.prepare("select value from meta where name = 'cursor'").get() as { value: string } | undefined)?.value ?? 0);
const save = db.prepare("insert or replace into sessions values (@id, @course, @date, @minutes)");
const drop = db.prepare("delete from sessions where id = ?");

type Change = { id: string; course: string; date: string; minutes: number; deleted?: true };
let text: string, changes: Change[], next: number;
if (process.argv[2] === "all") {
  text = await (await fetch(`${SERVER}/sessions`)).text();
  changes = JSON.parse(text);
  next = cursor();
  db.exec("delete from sessions");
} else {
  text = await (await fetch(`${SERVER}/changes?after=${cursor()}`)).text();
  ({ cursor: next, changes } = JSON.parse(text));
}
db.transaction(() => {
  for (const c of changes) c.deleted ? drop.run(c.id) : save.run(c);
  db.prepare("insert or replace into meta values ('cursor', ?)").run(String(next));
})();
const { n } = db.prepare("select count(*) as n from sessions").get() as { n: number };
console.log(`received ${changes.length} ${changes.length === 1 ? "row" : "rows"}, ${text.length} bytes; cursor ${cursor()}; ${n} sessions on the device`);
```

Start the server in a second terminal with `node server.ts`, give it two thousand more sessions, and
pull everything twice:

```
ana@dev:~/planner/delta$ curl -s -X POST 'http://127.0.0.1:8011/fill?n=2000'; echo
{"seq":2006}
ana@dev:~/planner/delta$ node pull.ts all
received 2006 rows, 217837 bytes; cursor 0; 2006 sessions on the device
ana@dev:~/planner/delta$ node pull.ts all
received 2006 rows, 217837 bytes; cursor 0; 2006 sessions on the device
```

**The second pull moved 217,837 bytes to learn that nothing had changed.** That is the shape of
pulling everything: the cost follows the size of the data, not the size of the change, and the size
of the data only grows. A planner opened ten times a day on the mobile network pays it ten times,
in data, in battery for the radio, and in the time before the screen is fresh.

There is a quieter cost too. Replacing the local copy wholesale throws away anything the device
holds that the server has not seen yet, so it can only run when the outbox is empty, and lesson 12
shows a full download that respects it. For everyday sync, the question has to change from "what is
there?" to "what changed since I last asked?", and the next section is how the device asks it.
