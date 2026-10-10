---
title: The target, and stopping there to look
version: 1
---

With the segment in the archive, the same restore again:

```
ana@vm:~$ sudo rm -rf /var/lib/postgresql/16/restore
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --pg1-path=/var/lib/postgresql/16/restore --archive-mode=off --type=xid --target=742 --target-exclusive --target-action=pause restore
ana@vm:~$ sudo pg_ctlcluster 16 restore start
ana@vm:~$ sudo grep -E "starting point-in-time|recovery stopping|pausing at|ready to accept" /var/log/postgresql/postgresql-16-restore.log | tail -n 4
2026-10-10 16:36:20.129 -03 [4524] LOG:  starting point-in-time recovery to XID 742
2026-10-10 16:36:20.320 -03 [4521] LOG:  database system is ready to accept read-only connections
2026-10-10 16:36:20.330 -03 [4524] LOG:  recovery stopping before commit of transaction 742, time 2026-10-10 16:36:08.563344-03
2026-10-10 16:36:20.330 -03 [4524] LOG:  pausing at the end of recovery
```

The log tells the recovery in four lines: it set out for transaction 742, opened for **read-only**
connections as soon as the copy was consistent, then **stopped before the commit of transaction
742**, naming the commit time the dump showed, and paused.

## Four ways to name the moment

| setting | stops at | when to use it |
|---|---|---|
| `recovery_target_xid` | a transaction | the log has shown you which one, as here |
| `recovery_target_time` | a point on the clock | you know roughly when, and nothing more precise |
| `recovery_target_lsn` | a position in the log | the dump gave you a record rather than a transaction |
| `recovery_target_name` | a named point | somebody ran `pg_create_restore_point('before-migration')` beforehand |

Each one comes with `recovery_target_inclusive`, which decides whether the target itself is replayed.
For a transaction you want undone, it is `false`; that is what `--target-exclusive` set. And the
last one is the cheapest insurance there is: **a named restore point before every risky change**,
a migration, a bulk update, a cleanup, costs one function call and turns "about four o'clock" into
an exact target.

## Pause, and look before you commit to it

`--target-action=pause` is why the server is still in recovery. It stops at the target and waits,
read-only, so you can check that the target was the right one **before** anything irreversible
happens:

```
shop=# SELECT pg_is_in_recovery(), pg_get_wal_replay_pause_state();
 pg_is_in_recovery | pg_get_wal_replay_pause_state 
-------------------+-------------------------------
 t                 | paused
(1 row)

shop=# SELECT count(*), min(placed_at), max(id) FROM orders;
 count |          min           |  max  
-------+------------------------+-------
 50005 | 2026-01-01 09:07:00-03 | 50005
(1 row)
```

**50005 orders**: the fifty thousand from before, plus the five that arrived before the `DELETE`,
and the oldest is from 1 January again. The three orders after the `DELETE` are not here, because
they came after the target; that is the next section's problem.

If the copy were wrong (the target one transaction too early, or too late) the cure is cheap at
this point: stop the server, restore again with a different target. Nothing has been decided yet.
Here it is right, so end the recovery:

```
shop=# SELECT pg_wal_replay_resume();
 pg_wal_replay_resume 
----------------------
 
(1 row)
shop=# SELECT pg_is_in_recovery();
 pg_is_in_recovery 
-------------------
 f
(1 row)

shop=# SELECT timeline_id FROM pg_control_checkpoint();
 timeline_id 
-------------
           2
(1 row)
```

`pg_wal_replay_resume()` lets recovery finish, and the server becomes an ordinary one that accepts
writes, **on timeline 2**. The two other actions skip the look: `promote` does this immediately on
arrival, and `shutdown` stops the server at the target, for a restore that will be started somewhere
else.
