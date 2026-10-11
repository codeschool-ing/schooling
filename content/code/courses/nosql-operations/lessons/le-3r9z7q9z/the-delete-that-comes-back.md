---
title: The delete that comes back
version: 1
---

The rule of the last section, repair every node within `gc_grace_seconds`, sounds like
housekeeping. This section breaks it on purpose and watches a deleted row come back. **Two settings
were shortened so that it happens in minutes rather than days, and the lesson says which**:

- the table is created **`WITH gc_grace_seconds = 60`**, one minute instead of ten days;
- hinted handoff is **switched off on every node** with `nodetool disablehandoff`. That stands in for
  a node that stayed down longer than `max_hint_window`, three hours by default, after which nobody
  keeps its missed writes for it any more.

Everything else is the ordinary behaviour of Cassandra 5.0.9.

## The row, the delete, and a node that missed it

A wish list for Ana with two items, written at `ALL` so that all three nodes have both, and hints
switched off:

```
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE TABLE shop.wishlist (customer text, sku text, PRIMARY KEY (customer, sku)) WITH gc_grace_seconds = 60;
cqlsh> CONSISTENCY ALL
Consistency level set to ALL.
cqlsh> INSERT INTO shop.wishlist (customer, sku) VALUES ('ana@example.com', 'KB-101');
cqlsh> INSERT INTO shop.wishlist (customer, sku) VALUES ('ana@example.com', 'MN-330');
cqlsh> exit
ana@vm:~$ for n in c1 c2 c3; do docker exec $n nodetool disablehandoff; done
ana@vm:~$ docker exec c1 nodetool statushandoff
Hinted handoff is not running
```

Stop `c3`, and delete one item at `QUORUM`, which succeeds with `c1` and `c2`:

```
ana@vm:~$ docker stop c3
c3
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CONSISTENCY QUORUM
Consistency level set to QUORUM.
cqlsh> DELETE FROM shop.wishlist WHERE customer = 'ana@example.com' AND sku = 'MN-330';
cqlsh> SELECT * FROM shop.wishlist WHERE customer = 'ana@example.com';

 customer        | sku
-----------------+--------
 ana@example.com | KB-101

(1 rows)
cqlsh> exit
```

Ana removed the monitor and the shop shows one item. On `c1` and `c2` the monitor now has a
tombstone. On `c3`, which was down, the monitor's row is still there, and with hints off nothing
will tell it.

## Past the grace period

Wait longer than the table's 60 seconds, then flush and compact the two nodes that saw the delete:

```
ana@vm:~$ sleep 70
ana@vm:~$ for n in c1 c2; do docker exec $n nodetool flush shop wishlist; docker exec $n nodetool compact shop wishlist; done
ana@vm:~$ docker exec c1 sh -c "/opt/cassandra/tools/bin/sstabledump /var/lib/cassandra/data/shop/wishlist-*/*Data.db"
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
        "liveness_info" : { "tstamp" : "2026-10-10T19:59:26.214390Z" },
        "cells" : [ ]
      }
    ]
  }
]
```

**The dump of `c1` holds the keyboard and nothing else.** The monitor's row and its tombstone were
merged by compaction, the tombstone was older than `gc_grace_seconds`, and both were dropped. `c1`
no longer knows that the monitor was ever in Ana's wish list, or that it was removed. `c2` is the
same.

## The node comes back

Start `c3` and wait for it to answer with a loop like lesson 1's:

```sh
until docker exec c3 cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done
```

```
ana@vm:~$ docker start c3
c3
ana@vm:~$ until docker exec c3 cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CONSISTENCY ONE
Consistency level set to ONE.
cqlsh> SELECT * FROM shop.wishlist WHERE customer = 'ana@example.com';

 customer        | sku
-----------------+--------
 ana@example.com | KB-101

(1 rows)
cqlsh> exit
```

A read at `ONE` from `c1` shows one item, the right answer, because it asked `c1`. Then the repair that the rules of this course say to run:

```
ana@vm:~$ docker exec c1 nodetool repair -full shop wishlist | grep -E "Starting repair|Repair completed"
[2026-10-10 20:01:25,369] Starting repair command #1 (5f764f60-c4e5-11f1-831b-f95588ceb72a), repairing keyspace shop with repair options (parallelism: parallel, primary range: false, incremental: false, job threads: 1, ColumnFamilies: [wishlist], dataCenters: [], hosts: [], previewKind: NONE, # of ranges: 48, pull repair: false, force repair: false, optimise streams: false, ignore unreplicated keyspaces: false, repairPaxos: true, paxosOnly: false)
[2026-10-10 20:01:26,371] Repair completed successfully
[2026-10-10 20:01:26,404] Repair completed successfully
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CONSISTENCY ONE
Consistency level set to ONE.
cqlsh> SELECT * FROM shop.wishlist WHERE customer = 'ana@example.com';

 customer        | sku
-----------------+--------
 ana@example.com | KB-101
 ana@example.com | MN-330

(2 rows)
cqlsh> exit
```

**The monitor is back.** The repair compared the three replicas, found that `c3` had a row the other
two lacked, and, with no tombstone anywhere to say it had been deleted, did what repair does with a
row one replica has and the others do not: it copied it to them. Ana's wish list now holds an item
she removed, on all three nodes, and nothing in any log calls it an error. In an earlier run of the
same steps, a read at `ALL` before any repair brought the row back in the same way, through the read
repair of lesson 19.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 380\" role=\"img\" aria-label=\"A grid in time, one row per step and one column per node, c1, c2 and c3. Step 1: the wish-list row is on all three. Step 2: c3 is stopped and the delete at QUORUM writes a tombstone on c1 and c2, while c3, down, keeps the row. Step 3: gc_grace_seconds passes. Step 4: compaction on c1 and c2 drops the tombstone and the row under it, leaving nothing. Step 5: c3 returns with the row, and a repair copies it to c1 and c2, so the deleted row is back on all three.\"><text x=\"312\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c1</text><text x=\"457\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c2</text><text x=\"602\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c3</text><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1. written at ALL</text><rect x=\"250\" y=\"44\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"312.5\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">row</text><rect x=\"395\" y=\"44\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"457.5\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">row</text><rect x=\"540\" y=\"44\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"602.5\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">row</text><text x=\"20\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2. c3 stops; DELETE at QUORUM</text><rect x=\"250\" y=\"108\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"312.5\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tombstone</text><rect x=\"395\" y=\"108\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"457.5\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tombstone</text><rect x=\"540\" y=\"108\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"602.5\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">row, while down</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3. gc_grace_seconds passes</text><rect x=\"250\" y=\"172\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"312.5\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tombstone</text><rect x=\"395\" y=\"172\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"457.5\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tombstone</text><rect x=\"540\" y=\"172\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"602.5\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">row, while down</text><text x=\"20\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4. flush and compact c1, c2</text><rect x=\"250\" y=\"236\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"312.5\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nothing</text><rect x=\"395\" y=\"236\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"457.5\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nothing</text><rect x=\"540\" y=\"236\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"602.5\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">row, while down</text><text x=\"20\" y=\"318\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5. c3 starts; repair</text><rect x=\"250\" y=\"300\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"312.5\" y=\"318.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">row again</text><rect x=\"395\" y=\"300\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"457.5\" y=\"318.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">row again</text><rect x=\"540\" y=\"300\" width=\"125\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"602.5\" y=\"318.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">row</text><text x=\"20\" y=\"362\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the old row on c3 meets no tombstone, so it wins</text></svg>", "caption": "The delete that comes back. Once the tombstone is purged on the nodes that saw the delete, nothing is left to tell the returning node's old row that it was deleted."}
```

## What actually went wrong

Not the repair: it did its job with what it was given. Not the delete either. **The failure is that
the tombstone expired before it reached every replica**, and in production that happens when one of
these is true for longer than `gc_grace_seconds`:

- a node is down and is then started again with its old data;
- repair does not run, or runs on some nodes and not others, or fails every night without anyone
  noticing;
- `gc_grace_seconds` was lowered to make tombstones go away faster, and the repair schedule was not
  tightened with it.

With the defaults the lab shortened, ten days and three hours, the window is wide but the mechanism
is the same. A shop would see a cancelled order reappear, a customer's deleted address come back, or
a sold item return to stock. Lesson 19 is about the machinery that prevents it, and about keeping
repair running so that it does.

Before going on, put the cluster back: `for n in c1 c2 c3; do docker exec $n nodetool enablehandoff;
done` switches hints on again. A node restart does the same, since `disablehandoff` lasts only until
the process restarts.
