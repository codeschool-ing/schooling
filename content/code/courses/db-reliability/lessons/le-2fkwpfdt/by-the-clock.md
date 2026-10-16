---
title: By the clock, and the rehearsal
version: 1
---

Not every mistake leaves a transaction id that easy to find. More often somebody says "it was just
after four", and the target is a time. The same recovery, by the clock, to the second in which the
`DELETE` committed:

```
ana@vm:~$ sudo pg_ctlcluster 16 restore stop
ana@vm:~$ sudo rm -rf /var/lib/postgresql/16/restore
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --pg1-path=/var/lib/postgresql/16/restore --archive-mode=off --type=time "--target=2026-10-10 16:36:08-03" --target-action=pause restore
ana@vm:~$ sudo pg_ctlcluster 16 restore start
shop=# SELECT count(*), min(placed_at) FROM orders;
 count |          min           
-------+------------------------
 50005 | 2026-01-01 09:07:00-03
(1 row)
```

`recovery_target_time` stops **before the first transaction that committed after the time given**.
The target was 16:36:08, the `DELETE` committed at 16:36:08.563, so it was not replayed, and the copy
again holds 50005 orders. Two things make a time target harder than it looks:

- **Whose clock.** The time somebody remembers comes from their screen, the application's log or a
  monitoring graph, and none of those is necessarily the database server's clock, in the database
  server's time zone. Write the target with its offset, as here (`-03`), and check the commit times in
  the log, as `pg_waldump` showed them, before trusting a memory.
- **Too early is safe, too late is not.** A target a minute early loses a minute of good transactions,
  which the repair can bring back from the live server. A target one second late replays the
  mistake, and the copy is useless. When unsure, pause, look, and go earlier.

## The rehearsal

Everything in this lesson happened on a quiet machine with the right answer known in advance. On the
day it is needed, a point-in-time recovery is done under pressure, by whoever is on call, often for the
first time on that system. The steps are few and each one has a way to go wrong:

1. Stop writes that make the repair harder, if you can.
2. Find the target: the transaction or the time, from the log.
3. Make sure the archive holds the segment with the target in it.
4. Restore to a separate server, **with archiving off**, and **pause** at the target.
5. Look: is the mistake absent, and is everything before it present?
6. Promote, and choose: replace, or repair from the copy.

That list is a runbook in miniature, and lesson 24 writes a full one. Lesson 7 makes a habit of
running it: on a schedule, with a stopwatch, before anybody needs it.
