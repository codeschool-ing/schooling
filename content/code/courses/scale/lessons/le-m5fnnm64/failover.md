---
title: When the primary is lost
version: 1
---

The second reason to run a replica is that it can take over. Here the primary is stopped, as if its
machine had died, and the box office is asked to sell and to read:

```
ana@lab:~/tickets$ docker compose stop db
 Container tickets-db-1 Stopping 
 Container tickets-db-1 Stopped 
ana@lab:~/tickets$ curl -s -o /dev/null -w "%{http_code}\n" -X POST localhost:8080/events/1/tickets
502
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "ea1537135dcf"}
ana@lab:~/tickets$ docker compose exec replica psql -U tickets -c 'SELECT pg_promote()'
 pg_promote 
------------
 t
(1 row)

ana@lab:~/tickets$ docker compose exec replica psql -U tickets -c "UPDATE events SET sold = sold + 1 WHERE id = 1 RETURNING sold"
 sold 
------
    1
(1 row)

UPDATE 1
```

**The sale fails**, with nginx's 502, because the box office's connection to the primary is gone.
**The read works**: it goes to the replica, which still has every row it had applied. A box office
that reads from replicas keeps showing shows while it cannot sell them, which is a far better
failure than a blank page, and lesson 11 makes a deliberate design of it.

Then the replica is **promoted**: `pg_promote()` tells it to stop following and become a primary.
It answers `t`, and from then on it accepts writes, as the `UPDATE` shows.

## What a promotion does not do

That took two commands, and in production it is the most dangerous operation in this course. Three
reasons:

- **The program still points at the old primary.** `DATABASE_URL` says `db`, and `db` is dead.
  Something has to redirect the writes: a change of configuration, a name in DNS moved to the new
  server, or a proxy in front of the databases that knows which one is the primary. Tools like
  Patroni exist to do the whole sequence, detecting, promoting and redirecting, with a consensus
  between several machines about who decides.
- **The replica was behind.** With asynchronous replication, the transactions the primary had
  committed and not yet sent are on a dead machine. A buyer who was told "your ticket is sold" may
  have bought a ticket that no longer exists. How much can be lost is the lag at the moment of
  failure; lesson 3 is about making that zero, and what it costs.
- **The old primary may come back.** If it does and still thinks it is the primary, two servers
  accept writes for the same rows, and their histories disagree from that moment on. This is
  **split brain**, and the defence is to make sure, before promoting, that the old primary cannot
  accept writes again; it is called **fencing**.

**A replica makes a failover possible; it does not make one safe.** Rehearse it on the lab, where
losing data costs nothing, and put the stack back afterwards with `docker compose down` and
`docker compose up -d`.
