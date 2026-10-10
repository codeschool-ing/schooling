---
title: Cassandra, the query it refuses
version: 1
---

Lesson 4 said a wide-column table answers the queries it was designed for and refuses the others.
Here is the refusal, then a consistency level, then what the node costs:

```
ana@lab:~/tickets$ docker exec cassandra cqlsh -e "SELECT ticket FROM tickets.scans WHERE gate = 'B'"
<stdin>:1:InvalidRequest: Error from server: code=2200 [Invalid query] message="Cannot execute this query as it might involve data filtering and thus may have unpredictable performance. If you want to execute this query despite the performance unpredictability, use ALLOW FILTERING"
ana@lab:~/tickets$ docker exec cassandra cqlsh -e "CONSISTENCY QUORUM; SELECT count(*) FROM tickets.scans WHERE show_id = 'show-1'"
Consistency level set to QUORUM.

 count
-------
     5

(1 rows)
ana@lab:~/tickets$ docker stats --no-stream --format "{{.Name}} {{.MemUsage}}" cassandra
cassandra 802.7MiB / 1.5GiB
ana@lab:~/tickets$ docker rm -f cassandra
cassandra
```

**"Every scan at gate B" is refused**, with a message that is a design lesson in one sentence: the
query "might involve data filtering and thus may have unpredictable performance". `gate` is not part
of the key, so answering would mean reading every partition on every node. `ALLOW FILTERING` would
make Cassandra do it anyway. On six rows that is harmless; on a cluster holding a year of scans it
is a query that reads the whole cluster, and the refusal exists so that nobody does it by accident.
The right answer is lesson 4's: a second table, keyed by gate, written alongside the first.

## Choosing the consistency of a read

`CONSISTENCY QUORUM` sets the level for the commands after it in the session, and the count that
follows is read at that level: from a majority of the replicas of the partition. With one node and
one replica, a majority is one, so nothing changes here. In a cluster with three replicas, this is
lesson 3's W + R > N set per query: writing and reading at `QUORUM` overlaps in at least one
replica, and `ONE` on either side gives up that guarantee for speed and availability.

## What it cost

`docker stats` shows the node using **803 MB** with six rows in it. Cassandra is built for many
machines with a lot of memory each; most of that is the heap and caches it reserves at start, not
data. On a laptop it is the heaviest of the five, which is one reason this lesson runs them one at a
time. Remove it before the next section; the last command above did.
