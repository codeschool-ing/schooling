---
title: A delete is a write
version: 1
---

Since SSTables are never changed, a `DELETE` cannot remove a row from the file that holds it. **It
writes a marker, a tombstone, in a newer file, saying "this row is deleted as of this timestamp".**
A read that meets the old row and the tombstone keeps whichever is newer, the tombstone, and returns
nothing. The row's bytes are still on disk until compaction merges the two files.

## The marker on disk

Delete Ana's keyboard from her basket, flush, and dump the new SSTable:

```
ana@vm:~$ docker exec c1 cqlsh -e "DELETE FROM shop.baskets WHERE customer = 'ana@example.com' AND sku = 'KB-101';"
ana@vm:~$ docker exec c1 nodetool flush shop baskets
ana@vm:~$ docker exec c1 sh -c "ls /var/lib/cassandra/data/shop/baskets-*/ | grep Data"
nb-4-big-Data.db
nb-5-big-Data.db
ana@vm:~$ docker exec c1 sh -c "/opt/cassandra/tools/bin/sstabledump /var/lib/cassandra/data/shop/baskets-*/nb-5-big-Data.db"
[
  {
    "table kind" : "REGULAR",
    "partition" : {
      "key" : [ "ana@example.com" ],
      "position" : 29
    },
    "rows" : [
      {
        "type" : "row",
        "position" : 29,
        "clustering" : [ "KB-101" ],
        "deletion_info" : { "marked_deleted" : "2026-10-10T19:59:03.455773Z", "local_delete_time" : "2026-10-10T19:59:03Z" },
        "cells" : [ ]
      }
    ]
  }
]
```

`nb-5` holds **one row with no cells and a `deletion_info`**: the time it was marked deleted and the
local time of the delete. That is the whole tombstone. The keyboard with quantity 1 is still in
`nb-4`, untouched; the two files together mean "deleted". A delete of a single cell, a whole
partition or a range of clustering keys writes the same kind of marker at that scope.

## A queue made of deletes

The way tombstones hurt is in numbers. The classic case is a table used as a **queue**: a job
inserts work items into one partition and a worker deletes each one after handling it. Here it is
with 1500 emails to send, 1499 of them already sent. The two files of statements are written by two
shell loops:

```sh
for i in $(seq 1 1500); do echo "INSERT INTO shop.outbox (queue, id, body) VALUES ('emails', $i, 'order confirmation');"; done > fill.cql
for i in $(seq 1 1499); do echo "DELETE FROM shop.outbox WHERE queue = 'emails' AND id = $i;"; done > drain.cql
```

```
ana@vm:~$ docker exec c1 cqlsh -e "CREATE TABLE shop.outbox (queue text, id int, body text, PRIMARY KEY (queue, id));"
ana@vm:~$ for i in $(seq 1 1500); do echo "INSERT INTO shop.outbox (queue, id, body) VALUES ('emails', $i, 'order confirmation');"; done > fill.cql
for i in $(seq 1 1499); do echo "DELETE FROM shop.outbox WHERE queue = 'emails' AND id = $i;"; done > drain.cql
ana@vm:~$ wc -l fill.cql drain.cql
  1500 fill.cql
  1499 drain.cql
  2999 total
ana@vm:~$ docker exec -i c1 cqlsh < fill.cql
ana@vm:~$ docker exec -i c1 cqlsh < drain.cql
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> SELECT id, body FROM shop.outbox WHERE queue = 'emails';

 id   | body
------+--------------------
 1500 | order confirmation

(1 rows)
cqlsh> exit
ana@vm:~$ docker exec c1 cqlsh -e "TRACING ON; SELECT id FROM shop.outbox WHERE queue = 'emails';" | grep -oE 'Read [0-9]+ live rows and [0-9]+ tombstone cells'
Read 0 live rows and 0 tombstone cells
Read 1 live rows and 1499 tombstone cells
Read 1 live rows and 1499 tombstone cells
ana@vm:~$ docker exec c1 grep -E "^tombstone_(warn|failure)_threshold" /etc/cassandra/cassandra.yaml
tombstone_warn_threshold: 1000
tombstone_failure_threshold: 100000
```

The `SELECT` returned one row, which is correct, and looks cheap. **The trace shows what it cost:
the replicas that read the partition each read 1 live row and stepped over 1499 tombstone cells to
find it.** The queue's partition holds 1500 rows' worth of history for one row of answer, and every
poll of the queue pays it again until compaction can drop the tombstones, which, the next section
explains, takes at least `gc_grace_seconds`. The third trace line, a read that found nothing at all,
is part of the same request; the trace does not say more about it.

The last command shows the two limits that guard against this. A read that meets **more than 1000
tombstones** is logged as a warning naming the query and the partition; a read that meets **more than
100000** is aborted with an error, because by then the node would spend its memory on markers for
data that no longer exists. A partition that crosses the first number is a modelling problem, and
the usual fixes are the ones lesson 16 gave for size: a time bucket in the partition key so old
partitions stop being read, or a design where the worker remembers how far it got instead of
deleting what it handled.

So deletes are not free in Cassandra. They are writes, they are read, and they stay for a minimum
time that the next section explains.
