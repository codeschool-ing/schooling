---
title: Coalescing, so the queue says only what matters
version: 1
---

**A person offline for a day can queue dozens of operations on a handful of sessions, and most of
them say nothing the last one does not.** Lengthen a session three times and the server needs the
final length, not the two before it. Create a session and delete it before the train comes out of
the tunnel, and the server needs to hear nothing at all. Shortening the queue before it is sent is
called **coalescing**.

It is safe here for one reason, and it is worth seeing why: every operation's body is the whole row
as it stood after the change. An update that says "minutes is now 35" can replace the one that said
30 without losing anything. An update that said "add five minutes" could not, because the two
describe different steps and both have to happen.

## Three rules

For each session, taking its operations in order:

| queued | becomes | why |
|---|---|---|
| `create`, then `update` | one `create` with the newer body | the server has never seen the row, so it may as well see its latest version |
| `update`, then `update` | one `update` with the newer body | the older body has been overwritten on the device already |
| `create`, then `delete` | nothing | the server never had it and never will |
| `update`, then `delete` | one `delete` | the update would be thrown away a moment later |

The fourth rule keeps the later operation's place in the queue, the third removes both, and the
first two keep the earlier one's place, so a session's create still goes before anything that
depends on it. Save this as `compact.ts`:

```typescript
// compact.ts: shorten the outbox before it is sent, without changing what the server ends up with.
import { db } from "./store.ts";

type Op = { seq: number; op: string; session: string; body: string | null };
const ops = db.prepare("select seq, op, session, body from outbox order by seq").all() as Op[];
const del = db.prepare("delete from outbox where seq = ?");
const setBody = db.prepare("update outbox set body = ? where seq = ?");

db.transaction(() => {
  const first = new Map<string, Op>(); // the earliest operation still queued for each session
  for (const o of ops) {
    const f = first.get(o.session);
    if (!f) { first.set(o.session, o); continue; }
    if (o.op === "update") { setBody.run(o.body, f.seq); f.body = o.body; del.run(o.seq); } // fold it into the first
    else if (o.op === "delete" && f.op === "create") { del.run(f.seq); del.run(o.seq); first.delete(o.session); } // never existed
    else if (o.op === "delete") { del.run(f.seq); f.seq = o.seq; f.op = "delete"; } // only the delete matters
  }
})();
console.log(`${ops.length} operations, now ${(db.prepare("select count(*) as n from outbox").get() as { n: number }).n}`);
```

A day's worth, in miniature: a session lengthened twice, one created and deleted, and one added
after them all. Then the compaction:

```
ana@dev:~/planner/outbox$ node app.ts minutes s7 35
ana@dev:~/planner/outbox$ node app.ts minutes s7 40
ana@dev:~/planner/outbox$ node app.ts add s9 spanish 2026-10-25 30
ana@dev:~/planner/outbox$ node app.ts remove s9
ana@dev:~/planner/outbox$ node app.ts add s10 guitar 2026-10-26 20
ana@dev:~/planner/outbox$ node app.ts outbox
#4 update s7  {"id":"s7","course":"guitar","date":"2026-10-23","minutes":35}
#5 update s7  {"id":"s7","course":"guitar","date":"2026-10-23","minutes":40}
#6 create s9  {"id":"s9","course":"spanish","date":"2026-10-25","minutes":30}
#7 delete s9
#8 create s10  {"id":"s10","course":"guitar","date":"2026-10-26","minutes":20}
ana@dev:~/planner/outbox$ node compact.ts
5 operations, now 2
ana@dev:~/planner/outbox$ node app.ts outbox
#4 update s7  {"id":"s7","course":"guitar","date":"2026-10-23","minutes":40}
#8 create s10  {"id":"s10","course":"guitar","date":"2026-10-26","minutes":20}
ana@dev:~/planner/outbox$ node drain.ts
#4 update s7: 200
#8 create s10: 201
0 waiting
```

**Five operations became two, and the server ends up exactly where it would have with all six.** That
equality is the test for any rule you add. If coalescing two operations would leave the server in a
different state from sending both, the rule is wrong.

## When not to coalesce

Not every operation is a new version of a row. An operation that **moves money**, or adds to a
counter, or appends a message to a conversation, is an event, and each one has to arrive. The
planner's sessions are rows; a log of "studied 25 minutes" events would not be, and lesson 15
comes back to what changes when the data is a count rather than a value.

Coalescing also needs the drain to be stopped while it runs. If `drain.ts` had sent `#2` and was
waiting for the answer while `compact.ts` folded `#3` into `#1`, the server could receive an update
for a session whose create it never got. The same lock that allows one drain at a time covers
compaction.
