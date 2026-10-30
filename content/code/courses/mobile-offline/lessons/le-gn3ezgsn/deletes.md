---
title: Deletes need a tombstone
version: 1
---

**A delta sync asks what changed. A row that was deleted is not there to be asked about, so unless
the delete leaves something behind, no question can return it.** What it leaves behind is a
**tombstone**: the row's id, marked deleted, given a place in the history like any other write.

The tempting design deletes the row on the server and expects the devices to notice. They cannot. A
device that pulled `s3` last week keeps it, shows it in the week, and counts its 20 minutes. If the
device ever sends it back, a session the person deleted on their tablet reappears on the server.

## Watching both

The server's `DELETE` writes a tombstone: the row stays, with `deleted: true`, and takes the next
number of the sequence. `/changed-since`, the timestamp query from the previous section, reads only
rows that are not deleted, which is how a query over live rows behaves. Restart the server, pull the
six sessions, delete `s3` from another phone, then ask both ways:

```
ana@dev:~/planner/delta$ rm planner.db
ana@dev:~/planner/delta$ node pull.ts delta
received 6 rows, 722 bytes; cursor 6; 6 sessions on the device
ana@dev:~/planner/delta$ curl -s -o /dev/null -X DELETE 'http://127.0.0.1:8011/sessions/s3?stamp=2026-10-21T10:30:00Z'
ana@dev:~/planner/delta$ curl -s 'http://127.0.0.1:8011/changed-since?t=2026-10-21T10:00:00Z'; echo
[]
ana@dev:~/planner/delta$ node pull.ts delta
received 1 row, 154 bytes; cursor 7; 5 sessions on the device
```

The timestamp query answered an empty list, which is true of the live rows and useless to the
device. The cursor pull received one row, the tombstone, and `pull.ts` deleted `s3` locally: five
sessions on the device, as on the server.

## How long a tombstone lives

A tombstone costs a row for every delete, for ever, unless the server removes it. It can remove one
only when **every device that might still hold the row has pulled past the tombstone's number**, and
a server cannot know that about a phone that is in a drawer. So servers keep tombstones for a fixed
window, thirty days or ninety, and accept that a device away for longer cannot be brought up to date
by deltas. That device needs something else, and lesson 12 is it: the full resync, and the
`410 Gone` that says when to do one.

A tombstone also answers a question a deleted row cannot: *who deleted it, and when*. A server that
keeps that much can show the person "deleted on the tablet on Tuesday", which is lesson 13's
conflict seen from the other side.
