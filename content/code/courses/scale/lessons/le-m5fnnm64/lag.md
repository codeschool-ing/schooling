---
title: Replication lag, and reading your own writes
version: 1
---

The primary commits a transaction, tells the client it is done, and sends the change to the
replicas **afterwards**. Until a replica has applied it, the replica answers with the world as it
was before. That gap is **replication lag**, and it is never zero: at best it is the time to send
a few kilobytes and apply them, usually well under a millisecond on one machine.

Under-a-millisecond lags are hard to see, so this section makes one long enough to watch.
`compose.yaml` passes `DELAY` to the replica's `recovery_min_apply_delay`, a PostgreSQL setting
that makes a replica wait before applying each change. Two seconds stands in for a replica that has
fallen behind, which real ones do: under a burst of writes, during a long query on the replica, or
across a slow network to another region.

```
ana@lab:~/tickets$ DELAY=2s docker compose up -d replica
 Container tickets-db-1 Running 
 Container tickets-replica-1 Recreate 
 Container tickets-replica-1 Recreated 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Starting 
 Container tickets-replica-1 Started 
ana@lab:~/tickets$ curl -s -X POST localhost:8080/events/7/tickets; echo
{"event": 7, "seat": 1, "code": "90ae233034a624a3"}
ana@lab:~/tickets$ curl -s localhost:8080/events/7; echo
{"name": "Show 7", "left": 1000000, "host": "b4849ff3119f"}
ana@lab:~/tickets$ sleep 2
ana@lab:~/tickets$ curl -s localhost:8080/events/7; echo
{"name": "Show 7", "left": 999999, "host": "b4849ff3119f"}
```

The sale of seat 1 of show 7 succeeded. The page of show 7, read **immediately afterwards** from
the replica, still says a million seats left; two seconds later it says one fewer. Nothing failed,
and nothing will ever log an error about it. **The buyer has just bought a ticket and the box office
says it was never sold.**

That is the most common surprise replicas cause, and it has a name: the guarantee that was lost is
**read-your-writes**. A user who wrote something expects to see it on their next read, whatever
everybody else sees.

## Keeping it

Four ways, from crudest to most precise:

- **Read your own data from the primary.** After a sale, the buyer's next pages read from the
  primary; everybody else's read from replicas. Simple, and it only works if the program knows which
  reads are "your own".
- **Read from the primary for a while after writing.** Remember the time of the user's last write,
  in their session or a cookie, and send their reads to the primary for the next few seconds. The
  few seconds are a guess about the worst lag.
- **Wait for the replica to catch up.** Every change in the log has a position, and the program can
  check that a replica has applied at least the position of the user's last write before reading
  from it. The next part shows it.
- **Make the primary wait for the replicas.** Lesson 3 does this, and measures what it costs.

## Waiting for a position

The position of a change in the log is its **LSN**, log sequence number. Read the primary's
position right after a write, and ask the replica whether it has replayed that far:

```
ana@lab:~/tickets$ curl -s -X POST localhost:8080/events/8/tickets; echo
{"event": 8, "seat": 1, "code": "47c7c69c20b6f517"}
ana@lab:~/tickets$ docker compose exec db psql -U tickets -Atc 'SELECT pg_current_wal_lsn()'
0/3001778
ana@lab:~/tickets$ docker compose exec replica psql -U tickets -Atc "SELECT pg_last_wal_replay_lsn() >= '0/3001778'"
f
ana@lab:~/tickets$ sleep 2
ana@lab:~/tickets$ docker compose exec replica psql -U tickets -Atc "SELECT pg_last_wal_replay_lsn() >= '0/3001778'"
t
```

The sale was written at `0/3001778`. Asked straight away, the replica has not replayed that far,
`f`; two seconds later, `t`. A program does the same check and either waits a moment, or sends the
read to the primary. It is exact, and it costs one value of state per user: the position of their
last write, carried in their session.

The first three are decisions in the program, not settings in the database. **Replication moves a
consistency problem from the database into the code that reads from it**, which is the trade this
whole lesson keeps making in different forms.

Before going on, put the replica back to no delay by recreating it without the variable:
`docker compose up -d replica`.
