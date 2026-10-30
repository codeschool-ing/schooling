---
title: What a resync costs, and when it is cheaper
version: 1
---

**A resync costs a download the size of the person's whole data, once; a delta costs the size of the
changes, every time. So a resync is the cheaper option exactly when the changes since the cursor
would be larger than the data, or cannot be known at all.** The 410 is the second case. The first
deserves measuring, because it is where a server can decide to send a snapshot even when it still
has the history.

## Measured

Restart the server, give it two thousand more sessions, and let the device catch up by delta. Then
delete one session on another phone, have the server forget, and pull:

```
ana@dev:~/planner/resync$ rm planner.db
ana@dev:~/planner/resync$ curl -s -X POST 'http://127.0.0.1:8012/fill?n=2000'; echo
{"seq":2006}
ana@dev:~/planner/resync$ node device.ts pull
delta: 2006 changes, cursor 2006
ana@dev:~/planner/resync$ curl -s -o /dev/null -X DELETE http://127.0.0.1:8012/sessions/s3
ana@dev:~/planner/resync$ curl -s -o /dev/null -X POST http://127.0.0.1:8012/forget
ana@dev:~/planner/resync$ node device.ts pull
410: cursor 2006 is older than 2007; resync
snapshot: 2005 sessions, 155594 bytes; 0 pending carried over
ana@dev:~/planner/resync$ stat -c '%s bytes' planner.db
131072 bytes
```

The first delta, from an empty device, carried 2006 changes, because an empty device has everything
to learn. After the forget, the resync downloaded 2005 sessions in 155,594 bytes and wrote a
database file of 131,072 bytes. The delta it replaced would have been one tombstone, a little over
a hundred bytes, had the server still had it.

That ratio, a thousand to one, is why a resync is the exception. It is also why a server sets its
tombstone window by the phones it serves rather than by its own disk: thirty days of tombstones cost
the server a few rows per delete, and every phone that falls outside the window costs a full
download.

## When the server should choose it

A server that still has the history may still answer with a snapshot when:

- **the history since the cursor is longer than the data**: a phone a year behind on a planner that
  rewrote half its sessions last month;
- **the history is expensive to compute**: thousands of small changes to rows that now hold one value
  each, where the snapshot is the compaction lesson 8 did on the device;
- **the server's shape changed**, and replaying old changes in the old shape would need code nobody
  wants to keep.

For the device the advice is shorter: **be ready for a resync at any pull**, keep the outbox across
it, and make the rename the only moment the screen's data changes source. Lesson 16 asks the last
question this one leaves: when, on a phone, a download of a hundred and fifty kilobytes is allowed to run.
