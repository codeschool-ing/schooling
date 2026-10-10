---
title: The first attempt, and the segment that was not there
version: 1
---

The restore is lesson 5's, with three more options: **`--type=xid --target=742`** names the
transaction, **`--target-exclusive`** says to stop before it rather than after, and
**`--target-action=pause`** says what to do on arrival, which the next section explains. Restore into
the second server, as before, and start it:

```
ana@vm:~$ sudo pg_ctlcluster 16 restore stop
ana@vm:~$ sudo rm -rf /var/lib/postgresql/16/restore
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --pg1-path=/var/lib/postgresql/16/restore --archive-mode=off --type=xid --target=742 --target-exclusive --target-action=pause restore
ana@vm:~$ sudo tail -n 4 /var/lib/postgresql/16/restore/postgresql.auto.conf
archive_mode = 'off'
restore_command = 'pgbackrest --pg1-path=/var/lib/postgresql/16/restore --stanza=main archive-get %f "%p"'
recovery_target_xid = '742'
recovery_target_inclusive = 'false'
ana@vm:~$ sudo pg_ctlcluster 16 restore start 2>&1 | grep -E "FATAL|could not start"
2026-10-10 16:36:15.295 -03 [4460] FATAL:  recovery ended before configured recovery target was reached
pg_ctl: could not start server
```

pgBackRest wrote the target into the copy's settings, `recovery_target_xid` and
`recovery_target_inclusive = 'false'`, and the server refused to start: **recovery ended before
configured recovery target was reached.** It replayed every segment it could fetch and never met
transaction 742.

The question is which segments it could fetch:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info | grep "wal archive"
        wal archive min/max (16): 000000010000000000000002/000000010000000000000003
shop=# SELECT pg_switch_wal();
 pg_switch_wal 
---------------
 0/4165F08
(1 row)
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info | grep "wal archive"
        wal archive min/max (16): 000000010000000000000002/000000010000000000000004
```

The archive ended at `…03`. Transaction 742 is in `…04`, **the segment the server is still writing**,
and a segment is archived only once it is finished: lesson 4's quiet-hour problem, arriving at the
worst possible moment. `pg_switch_wal()` on the live server finishes it, `archive-push` sends it, and
`info` now ends at `…04`.

This failure is the most common way a first point-in-time recovery goes wrong, and it is worth two
habits:

- **Before restoring to a recent moment, finish the current segment** on the live server, if it is
  still running, and check that the archive has it.
- **Read the refusal as good news.** PostgreSQL stopped rather than open a database that is not at
  the moment you asked for. A copy that silently ended at `…03` and called itself recovered would
  have been missing the five good orders, and somebody would have found out later.
