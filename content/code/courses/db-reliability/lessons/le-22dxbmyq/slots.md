---
title: The slot, and what it keeps for a standby that is gone
version: 1
---

Without a slot, the primary recycles old segments on its own schedule, and a standby that falls far
enough behind (a network outage, a long maintenance, a slow disk) asks for a segment that no longer
exists and can never catch up. A **replication slot** prevents that: the primary keeps every segment
from the slot's `restart_lsn` onwards, until the standby confirms it has them.

```
shop=# SELECT slot_name, slot_type, active, restart_lsn, wal_status FROM pg_replication_slots;
 slot_name | slot_type | active | restart_lsn | wal_status 
-----------+-----------+--------+-------------+------------
 standby1  | physical  | t      | 0/4006608   | reserved
(1 row)
```

One physical slot, `active` because the standby is connected, and `wal_status: reserved`: the log it
needs is within what the primary keeps anyway.

## A standby that stops

The promise has no expiry. Stop the standby, and let the primary carry on working:

```
ana@vm:~$ sudo pg_ctlcluster 16 standby stop
shop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 50001

shop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 50001

shop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 50001

shop=# CHECKPOINT;
CHECKPOINT

shop=# SELECT slot_name, active, wal_status, pg_size_pretty(pg_current_wal_lsn() - restart_lsn) AS held FROM pg_replication_slots;
 slot_name | active | wal_status | held  
-----------+--------+------------+-------
 standby1  | f      | reserved   | 49 MB
(1 row)
ana@vm:~$ sudo du -sh /var/lib/postgresql/16/main/pg_wal
81M	/var/lib/postgresql/16/main/pg_wal
```

The slot is no longer active, and it holds **49 MB** of log the primary cannot recycle, because the
standby might come back for it. A real primary writes gigabytes an hour; a standby that died on
Friday, with its slot still on the primary, holds the whole weekend's log by Monday. It is lesson 4's
broken archive command again, and lesson 4's `pg_receivewal` slot: the same pile, with the same
ending, **a full disk and a primary that stops**.

The two defences are the ones from lesson 4, applied to slots:

- **Watch them.** `pg_replication_slots` with `active = f`, or with `pg_current_wal_lsn() -
  restart_lsn` growing, is an alert, and a slot nobody can explain is dropped with
  `pg_drop_replication_slot`.
- **Cap them**, which the next section does.
