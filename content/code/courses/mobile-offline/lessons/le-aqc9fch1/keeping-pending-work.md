---
title: Keeping the work that is not sent yet
version: 1
---

**A resync replaces the device's copy of the server's data. It must not replace the person's work
that the server has not seen**, and that work is the outbox. Throwing the old file away with the
outbox in it would be lesson 11's "replace everything" mistake, made by the one piece of code that
was supposed to be careful.

`resync.ts` deals with it in two steps, inside the same transaction that writes the snapshot. It
copies every outbox row across with its `seq`, so order is kept and lesson 10's idempotency key, in a
real outbox, comes across with its row. Then it applies each pending operation to the new copy: a
create or an update writes its body over the snapshot's row, and a delete removes it. **The screen
after the resync shows what it showed before, plus whatever the server knew that the device did
not.**

## With a session waiting

Restart the server and pull. Then, offline, add a Spanish session, while another phone deletes
`s3` and the server forgets; then pull:

```
ana@dev:~/planner/resync$ rm planner.db
ana@dev:~/planner/resync$ node device.ts pull
delta: 6 changes, cursor 6
ana@dev:~/planner/resync$ node device.ts add s9 spanish 2026-10-27 30
ana@dev:~/planner/resync$ curl -s -o /dev/null -X DELETE http://127.0.0.1:8012/sessions/s3
ana@dev:~/planner/resync$ curl -s -o /dev/null -X POST http://127.0.0.1:8012/forget
ana@dev:~/planner/resync$ node device.ts pull
410: cursor 6 is older than 7; resync
snapshot: 5 sessions, 453 bytes; 1 pending carried over
ana@dev:~/planner/resync$ node device.ts show
s1   2026-10-19  spanish     30 min
s2   2026-10-20  statistics  45 min
s4   2026-10-22  spanish     30 min
s5   2026-10-26  statistics  60 min
s9   2026-10-27  spanish     30 min  waiting to send
s6   2026-10-28  guitar      20 min
cursor 7
```

The snapshot brought five sessions, and one pending operation was carried over. `s9` is on the
screen and still `waiting to send`, and the next drain sends it as if no resync had happened, which
for the outbox is true. The two kinds of truth stayed apart: the snapshot decided what the server
has, and the outbox decided what the person has done since.

## Where it gets harder

The pending operation was applied *over* the snapshot, which is right for a create the server has
never seen. It is a choice, not a law, as soon as both sides touched the same row. If the person
lengthened `s5` while away, and another phone deleted `s5` meanwhile, the snapshot says `s5` does
not exist and the outbox says it is now 90 minutes. Applying the outbox brings it back; dropping it
throws away the person's edit. That is a conflict, and lessons 13 to 15 are three ways to settle
one. A resync does not settle it; **it only must not hide it**, which is why it keeps the operation
rather than deciding for the person.
