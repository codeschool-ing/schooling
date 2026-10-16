---
title: Memtables, SSTables and compaction
version: 1
---

A relational database updates a row where it lies on disk. **Cassandra never does.** A write goes
to an in-memory table, the memtable, and to the commit log for safety; when the memtable is full,
or when you ask, it is written out as a new file, an SSTable, and that file is never changed again.
An `UPDATE` is a new version of some cells in a newer file, and a `DELETE`, the next section shows,
is a new file too. Reading a row means merging every SSTable that holds a piece of it, newest
timestamp winning, and **compaction** is the background job that merges SSTables into fewer, larger
ones so that reads do not have to.

This lesson uses the three nodes of lesson 16 with the keyspace `shop` at three copies, as lesson 17
left it. If you rebuilt the cluster, lesson 16 has the loop and lesson 17 the `ALTER KEYSPACE`.

## Watching the files appear

A table for baskets, two rows, and the table's directory on `c1`:

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE TABLE shop.baskets (customer text, sku text, qty int, PRIMARY KEY (customer, sku));
cqlsh> INSERT INTO shop.baskets (customer, sku, qty) VALUES ('ana@example.com', 'KB-101', 1);
cqlsh> INSERT INTO shop.baskets (customer, sku, qty) VALUES ('ana@example.com', 'CB-012', 2);
cqlsh> exit
ana@vm:~$ docker exec c1 sh -c "ls /var/lib/cassandra/data/shop/baskets-*/"
ana@vm:~$ docker exec c1 nodetool flush shop baskets
ana@vm:~$ docker exec c1 sh -c "ls /var/lib/cassandra/data/shop/baskets-*/"
nb-1-big-CompressionInfo.db
nb-1-big-Data.db
nb-1-big-Digest.crc32
nb-1-big-Filter.db
nb-1-big-Index.db
nb-1-big-Statistics.db
nb-1-big-Summary.db
nb-1-big-TOC.txt
```

**The first `ls` printed nothing**: the two rows existed only in the memtable and the commit log.
`nodetool flush` wrote the memtable out, and the directory now holds one SSTable, which is eight
files sharing the prefix `nb-1-big`. `Data.db` holds the rows; the others are its index, a summary
of the index, a Bloom filter that lets a read skip a file which cannot contain a key, statistics,
compression offsets, a checksum and a table of contents. `nb` is the file format version and `1` the
generation, the order in which the node wrote them.

Two more writes, each flushed on its own. The second is an `UPDATE` of a row that is already in
`nb-1`:

```
ana@vm:~$ docker exec c1 cqlsh -e "INSERT INTO shop.baskets (customer, sku, qty) VALUES ('bruno@example.com', 'MN-330', 1);"
ana@vm:~$ docker exec c1 nodetool flush shop baskets
ana@vm:~$ docker exec c1 cqlsh -e "UPDATE shop.baskets SET qty = 3 WHERE customer = 'ana@example.com' AND sku = 'CB-012';"
ana@vm:~$ docker exec c1 nodetool flush shop baskets
ana@vm:~$ docker exec c1 sh -c "ls /var/lib/cassandra/data/shop/baskets-*/ | grep Data"
nb-1-big-Data.db
nb-2-big-Data.db
nb-3-big-Data.db
ana@vm:~$ docker exec c1 nodetool tablestats shop.baskets | grep "SSTable count"
		SSTable count: 3
		Old SSTable count: 0
```

Three SSTables now, and Ana's `CB-012` exists in two of them: quantity 2 in `nb-1`, quantity 3 in
`nb-3`. Nothing went back to change `nb-1`. A read of Ana's basket opens both files and keeps the
cell with the newer timestamp.

## Compaction

Compaction runs by itself when enough similar SSTables pile up, and `nodetool compact` forces a full
one now:

```
ana@vm:~$ docker exec c1 nodetool compact shop baskets
ana@vm:~$ docker exec c1 sh -c "ls /var/lib/cassandra/data/shop/baskets-*/ | grep Data"
nb-4-big-Data.db
ana@vm:~$ docker exec c1 sh -c "/opt/cassandra/tools/bin/sstabledump /var/lib/cassandra/data/shop/baskets-*/*Data.db"
[
  {
    "table kind" : "REGULAR",
    "partition" : {
      "key" : [ "bruno@example.com" ],
      "position" : 31
    },
    "rows" : [
      {
        "type" : "row",
        "position" : 31,
        "clustering" : [ "MN-330" ],
        "liveness_info" : { "tstamp" : "2026-10-10T19:58:52.270805Z" },
        "cells" : [
          { "name" : "qty", "value" : 1 }
        ]
      }
    ]
  },
  {
    "table kind" : "REGULAR",
    "partition" : {
      "key" : [ "ana@example.com" ],
      "position" : 81
    },
    "rows" : [
      {
        "type" : "row",
        "position" : 81,
        "clustering" : [ "CB-012" ],
        "liveness_info" : { "tstamp" : "2026-10-10T19:58:49.088621Z" },
        "cells" : [
          { "name" : "qty", "value" : 3, "tstamp" : "2026-10-10T19:58:54.207711Z" }
        ]
      },
      {
        "type" : "row",
        "position" : 104,
        "clustering" : [ "KB-101" ],
        "liveness_info" : { "tstamp" : "2026-10-10T19:58:48.075283Z" },
        "cells" : [
          { "name" : "qty", "value" : 1 }
        ]
      }
    ]
  }
]
```

Three files became **one, `nb-4`**, and `sstabledump` prints it as JSON. Each partition appears
once, its rows sorted by clustering key, and Ana's `CB-012` has a single value, `3`, with two
timestamps: the row's `liveness_info` from the first `INSERT`, and the cell's own from the
`UPDATE`. The older value of 2 is gone; compaction kept only the newest version of each cell. The
partitions are in token order, not alphabetical, which is lesson 16's ring once more.

## Which strategy, and how to check

How compaction chooses what to merge is the table's **compaction strategy**, and the honest way to
know which one a table has is to ask it:

```
ana@vm:~$ docker exec c1 cqlsh -e "DESCRIBE TABLE shop.baskets" | grep -E "compaction|gc_grace"
    AND compaction = {'class': 'org.apache.cassandra.db.compaction.SizeTieredCompactionStrategy', 'max_threshold': '32', 'min_threshold': '4'}
    AND gc_grace_seconds = 864000
ana@vm:~$ docker exec c1 grep -A2 "^default_compaction" /etc/cassandra/cassandra_latest.yaml
default_compaction:
  class_name: UnifiedCompactionStrategy
  parameters:
```

The table got **`SizeTieredCompactionStrategy`**, STCS, which merges SSTables of similar size once
there are `min_threshold` of them, four here. That is the default of the `cassandra.yaml` the
official image ships. The same directory carries `cassandra_latest.yaml`, Cassandra 5.0's
recommended settings for new clusters, and there the default is **`UnifiedCompactionStrategy`**,
UCS, new in 5.0. A cluster only uses it if somebody chooses it, for the cluster or per table with
`ALTER TABLE … WITH compaction = {'class': 'UnifiedCompactionStrategy'}`.

The strategies in one table:

| strategy | merges | suits |
| --- | --- | --- |
| `SizeTieredCompactionStrategy` | SSTables of similar size, in tiers | write-heavy tables; it can leave old versions of a row spread over many files |
| `LeveledCompactionStrategy` | into levels where each partition is in at most one file per level | read-heavy tables that update rows often; it costs more disk writes |
| `TimeWindowCompactionStrategy` | SSTables of the same time window, and never across windows | time series written once and expired by TTL, such as lesson 16's page views |
| `UnifiedCompactionStrategy` | configurable to behave like either of the first two, per level | new clusters on 5.0, as `cassandra_latest.yaml` recommends |

The `gc_grace_seconds = 864000` beside it in the `DESCRIBE` output is the subject of the section
after next. First, what a delete writes.
