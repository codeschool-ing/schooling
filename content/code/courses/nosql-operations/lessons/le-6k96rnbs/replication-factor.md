---
title: Three copies of every partition
version: 1
---

Lesson 16 kept one copy of each partition, so the node that owned a token was the only place its
rows existed. Stop that node and those rows are gone until it returns. **The replication factor is
the number of copies, and it belongs to the keyspace, not to the table or the query.** This lesson
raises it to three, the usual production choice, and then spends the rest of its time on the other
number, the one each query chooses: how many of those copies have to answer.

This lesson needs the three nodes of lesson 16, running, with the keyspace `shop`. If you removed
them, lesson 16's loop builds them again in a few minutes, and `CREATE KEYSPACE shop` from its
`orders.cql` makes the keyspace.

## Raising it, and the warning that comes with it

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> ALTER KEYSPACE shop WITH replication = {'class': 'NetworkTopologyStrategy', 'dc1': 3};

Warnings :
When increasing replication factor you need to run a full (-full) repair to distribute the data.

cqlsh> exit
ana@vm:~$ docker exec c1 nodetool status shop
Datacenter: dc1
===============
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load        Tokens  Owns (effective)  Host ID                               Rack 
UN  172.18.0.3  80.02 KiB   16      100.0%            4e6c6943-bad2-4a89-a579-c61d93c795b4  rack1
UN  172.18.0.2  114.69 KiB  16      100.0%            4f53c005-bbb3-41b0-85b5-e123a1c42d23  rack1
UN  172.18.0.4  119.66 KiB  16      100.0%            1480b2b6-2542-4292-8efe-6389e94e299a  rack1
```

`NetworkTopologyStrategy` takes a number of copies **per data centre**, by the name each node gave
itself with `CASSANDRA_DC`: here, three copies in `dc1`. With three nodes and three copies, every
node holds every partition, which is what `Owns (effective)` now says, `100.0%` each.

**The warning is the important line.** Changing the replication factor changes where Cassandra
looks for data, and nothing else. It does not copy the rows that already exist. The orders of lesson
16 were written when each had one copy, and after this `ALTER` two of the three nodes that are now
supposed to hold each partition have never seen it. A read that happens to ask one of those nodes
alone finds nothing. The full repair the warning asks for is what copies them, and lesson 19 runs it.

`SimpleStrategy`, which lesson 2 used on one node, ignores data centres and places copies on the
next nodes round the ring. It is fine for a single data centre in a lab; the reason to learn the
other one is that a cluster that grows a second data centre has to be on it, and changing strategy
later is another `ALTER` followed by another repair.

## A table for this lesson

The question lesson 1 asked about two cities and one monitor is the one this lesson answers in
practice, so the table is stock:

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE TABLE shop.stock (sku text PRIMARY KEY, name text, units int);
cqlsh> CONSISTENCY
Current consistency level is ONE.
cqlsh> CONSISTENCY ALL
Consistency level set to ALL.
cqlsh> INSERT INTO shop.stock (sku, name, units) VALUES ('MN-330', '27-inch monitor', 1);
cqlsh> SELECT * FROM shop.stock WHERE sku = 'MN-330';

 sku    | name            | units
--------+-----------------+-------
 MN-330 | 27-inch monitor |     1

(1 rows)
cqlsh> exit
ana@vm:~$ docker exec c1 nodetool getendpoints shop stock MN-330
172.18.0.2
172.18.0.4
172.18.0.3
```

Two lines before the `INSERT` matter. `CONSISTENCY` with no argument shows the current level, and
**`cqlsh` starts at `ONE`**: unless you say otherwise, one replica's answer is enough. `CONSISTENCY
ALL` changes it for this session, and the write that follows was acknowledged by all three. Then
`getendpoints` lists three addresses for `MN-330`: all three nodes.

Three copies change what can fail. **With one copy, any node down is some data unavailable. With
three, a node can be down and every partition still has two copies up**, and whether a query
succeeds then depends on how many copies it insists on hearing from. That is the consistency level,
and the next section stops nodes to watch it decide.
