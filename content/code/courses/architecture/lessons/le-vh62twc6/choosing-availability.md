---
title: Choosing availability: asynchronous replication
version: 1
---

With **asynchronous replication**, the default, the primary commits locally, tells the client at once,
and streams the change to the standby afterwards. Switch back to it, cut the standby off again, and sell
another bag:

```
ana@vm:~/lab/cap$ $P -c "ALTER SYSTEM RESET synchronous_standby_names" -c "SELECT pg_reload_conf()"
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@vm:~/lab/cap$ docker network disconnect cap_default cap-standby-1
ana@vm:~/lab/cap$ time $P -c "UPDATE stock SET units = 10 WHERE sku = 'coffee'"
UPDATE 1

real	0m0.240s
user	0m0.083s
sys	0m0.056s
ana@vm:~/lab/cap$ $P -c "SELECT * FROM stock"
  sku   | units 
--------+-------
 coffee |    10
(1 row)

ana@vm:~/lab/cap$ $S -c "SELECT * FROM stock"
  sku   | units 
--------+-------
 coffee |    11
(1 row)
```

This time the update returned immediately: `UPDATE 1`, in a fraction of a second, with the standby
unreachable. **The primary stayed available for writes**, and the price is visible in the next two
lines: the primary says 10 and the standby, still answering reads, says 11. A client reading from the
standby during the partition is told there are 11 bags of coffee, which stopped being true a moment
ago.

That is the **A** choice: every node keeps answering, and the answers can disagree. Reconnect:

```
ana@vm:~/lab/cap$ docker network connect cap_default cap-standby-1
ana@vm:~/lab/cap$ $S -c "SELECT * FROM stock"
  sku   | units 
--------+-------
 coffee |    10
(1 row)
```

The standby replayed what it had missed and agrees again, which is the **eventual** in eventual
consistency: once the partition ends and the changes stop, the copies converge. Lesson 9 is about what
happens in between, when a customer is looking.

## The other cost: what a failover loses

Asynchronous replication has a second price that the lab did not show, and it is the one people find
out about the hard way. If the primary is lost for good while the standby is behind, and the standby is
promoted to be the new primary, **every change the old primary had acknowledged and not yet streamed is
gone**. Clients were told those writes were committed. The amount at risk is the replication lag at the
moment of failure, which lesson 10 shows how to measure.

| | synchronous | asynchronous |
| --- | --- | --- |
| a write during a partition | waits, possibly for ever | succeeds at once |
| reads from the standby during a partition | the same value as the primary | possibly old |
| the primary lost for good | nothing a client was told is lost | up to the replication lag is lost |
| a write with no partition | one more round trip | no extra wait |

The last row is the next section.
