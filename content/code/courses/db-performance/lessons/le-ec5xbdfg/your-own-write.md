---
title: Reading your own write
version: 1
---

Lag is harmless for most reads. A product page that shows a price from two seconds ago, a report
that misses the last minute: nobody can tell. The read that cannot be behind is the one that comes
**straight after the same person's write**. A customer cancels an order, the page reloads, and the
order is still pending. They click cancel again. To them the shop is broken, and they are right. The
property they expected has a name, **read-your-own-writes**, and a replica does not give it.

The wrong belief here is that lag is small enough to ignore if it is usually a few milliseconds.
"Usually" is the problem: a page reload takes a hundred milliseconds, and the first time a large
`UPDATE` or a slow network puts the replica a second behind, every user who wrote something in that
second sees the past.

## Stale, in three commands

The replica is ten seconds behind, from the last section. Order 1999990 is pending. Cancel it on the
primary and read it back from the replica at once, then again after ten seconds:

```
ana@vm:~$ psql market -c "SELECT id, status FROM orders WHERE id = 1999990"
   id    | status  
---------+---------
 1999990 | pending
(1 row)

Time: 1.212 ms
ana@vm:~$ psql market -c "UPDATE orders SET status = 'cancelled' WHERE id = 1999990"
UPDATE 1
Time: 2.516 ms
ana@vm:~$ psql -p 5433 market -c "SELECT id, status FROM orders WHERE id = 1999990"
   id    | status  
---------+---------
 1999990 | pending
(1 row)

Time: 3.713 ms
ana@vm:~$ psql -p 5433 market -c "SELECT id, status FROM orders WHERE id = 1999990"
   id    |  status   
---------+-----------
 1999990 | cancelled
(1 row)

Time: 0.985 ms
```

The `UPDATE` reported success, and **the replica answered `pending`** on the very next command. Ten
seconds on, it says `cancelled`. Nothing failed and nothing was lost: the replica was right about a
moment that had passed, and a user looking at it would have been wrong about the present.

## Two ways to give it back

**Read from the primary for a while after writing.** The application remembers, per user, when they
last wrote, in their session or a cookie, and sends that user's reads to the primary for a window
afterwards: a few seconds, longer than the lag you expect. It is simple and it is the common answer.
Its weakness is the window: it is a guess about the lag, and the day the lag outgrows it, the stale
read comes back. It also sends to the primary exactly the reads of the most active users.

**Wait until the replica has replayed the write.** Every commit has a position in the WAL, and the
primary can say what it is with `pg_current_wal_lsn()` right after the write. A replica can say how
far it has replayed with `pg_last_wal_replay_lsn()`. When the second is at or past the first, the
replica has the write, and a read there is safe. The script below does exactly that: it cancels an
order on the primary, keeps the position, and polls the replica until it has caught up, before
reading:

```sh
cat > ~/read-your-write.sh <<'SH'
#!/bin/sh
# read-your-write.sh ORDER_ID: cancel an order on the primary, then read it
# back from the replica, but only once the replica has replayed the write.
set -e
lsn=$(psql -XAtq market \
        -c "UPDATE orders SET status = 'cancelled' WHERE id = $1" \
        -c "SELECT pg_current_wal_lsn()")
echo "written at $lsn"
checks=0
until [ "$(psql -XAtq -p 5433 market \
             -c "SELECT pg_last_wal_replay_lsn() >= '$lsn'")" = t ]; do
    checks=$((checks + 1))
    sleep 0.2
done
echo "replica caught up after $checks checks, 0.2 s apart"
psql -XAtq -p 5433 market -c "SELECT id, status FROM orders WHERE id = $1"
SH
chmod +x ~/read-your-write.sh
```


`-XAtq` is four `psql` options together: no `~/.psqlrc` (so no `Time:` lines), unaligned, rows only,
quiet. That makes the output a bare value a shell can compare. Run it on another pending order:

```
ana@vm:~$ ~/read-your-write.sh 1999991
written at 1A/7003B68
replica caught up after 42 checks, 0.2 s apart
1999991|cancelled
```

**42 checks, 0.2 seconds apart**: the script waited a little under ten seconds, which is the delay,
and then the replica returned `cancelled`, never the stale value. The cost is that waiting. With
ordinary lag it is one check; with ten seconds of lag the user waits ten seconds, and a real
application needs a limit, after which it gives up on the replica and reads from the primary.

The position does not have to be checked from a script. An application can return it to the
browser with the response to a write, and send it back with the next read. That read then waits for
it or goes to the primary: the same idea, carried by the user's own requests, with no guess about how
long the lag is.

## Which reads may go to a replica

The two answers fix a read after a write by one person. They do not make a replica safe for reads
that **decide** something. Checking stock before selling the last unit, checking a balance before a
withdrawal, checking that an email is free before creating an account: those read and then act, and
acting on a moment that has passed sells the same unit twice. They belong on the primary, in the
same transaction as the write, where lesson 14's isolation levels apply.

What a replica is good for is the rest, which is most of a shop's traffic: browsing, searching,
reports, dashboards, and everything a user reads that they did not just change. Sort the reads into
those two kinds before you point anything at a replica, because the code that sends a query
somewhere is the only place the decision can live.
