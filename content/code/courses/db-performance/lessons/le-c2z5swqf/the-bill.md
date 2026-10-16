---
title: The bill, which arrives every month
version: 1
---

The section before this one counted what sharding costs a query. Those costs are visible, they are
in a plan, and a careful team can design around most of them. The larger bill is not in any plan.
It is the work that used to be one operation on one server and is now one operation per shard,
forever, with a new way to fail at every step. The belief to put down is that sharding is a
project with an end. **It is a running cost**, and the items below are why.

## Rebalancing

Two shards fill up. You add two more, and with hash routing that means the modulus goes from 2 to
4. PostgreSQL's hash partitioning was designed so that each old partition splits cleanly into two
new ones, which is the best case there is. Ask how many orders would land on the two new shards:

```
market=# SELECT count(*) FILTER (WHERE satisfies_hash_partition('sharded_orders'::regclass, 4, 2, customer_id) OR satisfies_hash_partition('sharded_orders'::regclass, 4, 3, customer_id)) AS moving, count(*) AS total FROM orders;
 moving |  total  
--------+---------
 999306 | 2000000
(1 row)

Time: 450.232 ms
```

**999306 of 2000000.** Half the table moves, while the application is writing to it. Every one of
those rows has to be copied to its new shard, the copy kept up to date with writes that arrive
during the move, the routing switched at one instant, and the old copy deleted. Done in place with
plain SQL, this is days of careful work and a window in which a bug loses orders. With modulo
routing on a number that does not double, moving from 2 shards to 3, most rows change shards, which
is why nobody routes that way.

The standard way out is to **split into many more pieces than you have servers** from the start:
say 64 logical shards on 2 machines, 32 each. Adding machines then moves whole logical shards,
untouched inside, rather than rehashing rows. It is the reason products built for this create dozens
of shards on a cluster of two.

## Every schema change, N times

Adding a column used to be one statement. Now it is one per shard, plus one on the coordinator,
and the parts do not know about each other:

```
ana@vm:~$ for s in shard1 shard2; do psql $s -c 'ALTER TABLE orders ADD COLUMN coupon text'; done
ALTER TABLE
Time: 7.081 ms
ALTER TABLE
Time: 3.156 ms
market=# SELECT coupon FROM sharded_orders WHERE customer_id = 42;
ERROR:  column "coupon" does not exist
LINE 1: SELECT coupon FROM sharded_orders WHERE customer_id = 42;
               ^
Time: 15.852 ms

market=# ALTER TABLE sharded_orders ADD COLUMN coupon text;
ALTER TABLE
Time: 4.058 ms

market=# SELECT count(coupon) FROM sharded_orders WHERE customer_id = 42;
 count 
-------
     0
(1 row)

Time: 22.595 ms
```

The column exists on both shards, and the coordinator still answers **`column "coupon" does not
exist`**, because its foreign tables describe the shards as they were. Only after the third
statement does the query work. With two shards this is a loop and a moment of confusion. With
forty, it is a deployment that can stop halfway, shard 23 refusing because of a lock while 22 shards
already have the column and the application is about to start writing to it. Every migration tool
you use has to learn that the database is now plural, and every migration needs a plan for the
state where only some shards have run it.

## Backups that are not one moment

A backup of one server is a consistent picture of one moment: restore it and every order has its
lines, every payment its order. Two shards backed up separately are **two pictures taken at two
moments**, and between them some transactions committed on one shard and not yet on the other. The
half-committed transaction in section 04 is the same problem seen from the other side. Restoring a
sharded database to a point in time means restoring every shard to the same instant, which needs
the WAL of every shard archived and a recovery target they all reach. `db-reliability` lessons 3 to
6 are about backups and point-in-time recovery on one server; every word of them now applies N
times, plus the coordination.

## Ids

On one server, `GENERATED ALWAYS AS IDENTITY` hands out ids from one sequence and no two orders
share one. Section 04 showed what happens when that guarantee is gone: two orders with the id 1.
Each shard's own sequence would produce the same numbers as every other shard's, so the ids have to
be made unique by construction, not by a constraint. The usual answers:

| scheme | how | what it costs |
|---|---|---|
| a UUID | `gen_random_uuid()`, 16 random bytes | larger indexes, rows inserted all over the index rather than at its end |
| interleaved sequences | shard 1 counts 1, 3, 5…; shard 2 counts 2, 4, 6… with `START` and `INCREMENT BY` | the number of shards is baked into the ids |
| the shard in the id | the high bits say which shard, the low bits count | an id that encodes a location that rebalancing may change |
| one central allocator | a service, or the coordinator, hands out blocks of ids | a single point that every write depends on |

None of them is free, and the choice has to be made before the first sharded row is written,
because ids are what other systems store.

## And the rest of the list

**Monitoring** is N servers whose busiest statements differ: the hot shard is found by comparing
shards, not by reading one. **Reports** that read everything, the accountants' year and the
operations screen, become the slow fan-out queries of section 04, and usually move to a separate
warehouse fed from every shard. **Support** tickets that say "my order is missing" start with
working out which shard it should be on.

## Products that carry part of it

You do not have to build the coordinator yourself, and should not. **Citus**, an open-source
extension to PostgreSQL, turns one server into a coordinator over many workers. It distributes a
table by a column you choose and co-locates tables distributed by the same key. It copies reference
tables to every worker and pushes joins and aggregates down to the shards. It commits across shards
with two-phase commit, and it moves shards between machines while the application runs. It carries much of
the bill above in its own code. It does not choose the shard key, and it does not make a query that
ignores the key cheap. Other databases are built sharded from the start, with the same trade under
different names. The questions in this lesson are the ones to ask of any of them.

## Put the machine back

Close every `psql` session, so that the coordinator's connections to the shards end. Then drop the
two shard databases, take the password off your role, and run the script lesson 2 gave you:

```
ana@vm:~$ dropdb shard1
ana@vm:~$ dropdb shard2
ana@vm:~$ psql market -c 'ALTER ROLE ana PASSWORD NULL'
ALTER ROLE
Time: 1.321 ms
```

```sh
~/reset-market.sh
```

`~/reset-market.sh` drops `market` with everything the coordinator added to it, the extension, the
two servers and `sharded_orders`, and makes it again from `market_base`.
