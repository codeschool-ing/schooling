---
title: Read repair, fixing what a read happens to notice
version: 1
---

When a read asks more than one replica, the coordinator compares their answers. **If they disagree,
it returns the newest value to the client and writes that value to the replicas that were behind.**
That is read repair: it fixes exactly the rows somebody reads, at the moment they read them.

## Making two replicas disagree

Hints would hide the difference, so switch them off on `c1` and `c2`, stop `c3`, change the
keyboard's stock at `QUORUM`, and start `c3` again:

```
ana@vm:~$ for n in c1 c2; do docker exec $n nodetool disablehandoff; done
ana@vm:~$ docker stop c3
c3
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CONSISTENCY QUORUM
Consistency level set to QUORUM.
cqlsh> UPDATE shop.stock SET units = 4 WHERE sku = 'KB-101';
cqlsh> exit
ana@vm:~$ docker start c3
c3
ana@vm:~$ until docker exec c3 cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done
ana@vm:~$ for n in c1 c2; do docker exec $n nodetool enablehandoff; done
```

`c1` and `c2` say the keyboard has 4 units; `c3` still says 5, the value from before. Nothing is
wrong as far as any monitoring can tell.

## The read that notices

A read at `ALL`, traced, with `grep` keeping the lines about which replica sent what, then the same
read again:

```
ana@vm:~$ docker exec c1 cqlsh -e "CONSISTENCY ALL; TRACING ON; SELECT units FROM shop.stock WHERE sku = 'KB-101';" | grep -oE 'units|^ +[0-9]+$|reading (digest|data) from /[0-9.:]+|Digest mismatch|Sending read-repair-mutation to [^ ]+|READ_REPAIR_RSP message received from /[0-9.:]+'
units
     4
units
reading data from /172.18.0.4:7000
reading digest from /172.18.0.3:7000
Digest mismatch
Sending read-repair-mutation to Full(/172.18.0.4:7000,(4216882464000968657,4585225655627743975])
READ_REPAIR_RSP message received from /172.18.0.4:7000
ana@vm:~$ docker exec c1 cqlsh -e "CONSISTENCY ALL; TRACING ON; SELECT units FROM shop.stock WHERE sku = 'KB-101';" | grep -oE 'units|^ +[0-9]+$|reading (digest|data) from /[0-9.:]+|Digest mismatch|Sending read-repair-mutation to [^ ]+|READ_REPAIR_RSP message received from /[0-9.:]+'
units
     4
units
reading digest from /172.18.0.4:7000
reading digest from /172.18.0.3:7000
```

The first trace reads like a sentence. The coordinator asked **`c3` for the data and `c2` for a
digest**, a hash of its answer, which is cheaper to send than the data. The two did not match:
**`Digest mismatch`**. So it fetched the full data, kept the newest, `4`, and sent a
**`read-repair-mutation`** to `c3`, which answered `READ_REPAIR_RSP`. The client was told 4, the
right value, and `c3` holds it now. The repeated `units` lines are the column header and the query's
own text in the trace.

The second read, a moment later, asked two digests, found them equal, and repaired nothing.

## What read repair can and cannot do

The table setting that governs it is `read_repair`, which `DESCRIBE TABLE` shows as `'BLOCKING'`
unless somebody changed it: **the client waits until the repair is written**, so a later read at the same level
cannot return the older value. That is what makes `QUORUM` reads after `QUORUM` writes safe even
when a replica was behind.

Its limit is in its name. **It repairs what is read, and only at levels that ask more than one
replica.** A read at `ONE` compares nothing. A row that nobody reads stays wrong until something
else fixes it, and a deleted row on a stale replica is exactly such a row: nobody reads what they
believe they deleted. Lesson 18 showed where that leads. The tool that visits every row whether or
not anyone reads it is the next section.
