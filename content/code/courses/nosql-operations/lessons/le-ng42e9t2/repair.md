---
title: nodetool repair, full and incremental
version: 1
---

Hints and read repair are opportunistic. **`nodetool repair` is the deliberate one: it compares
every replica of every range of a keyspace and copies whatever one has and another lacks.** It is
called anti-entropy because entropy, replicas drifting apart, is what it removes, and it is the only
mechanism that gives the guarantee lesson 18 depends on.

## Comparing without sending everything

Sending every row to every replica to compare them would cost as much as the data. Instead each
replica builds a **Merkle tree** for the range: the range is cut into slices, each slice's rows are
hashed, and pairs of hashes are hashed again up to a single root. Two replicas with equal roots
agree on the whole range. When roots differ, the replicas walk down the tree, and only the slices
whose hashes differ are streamed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"Two Merkle trees side by side, one built by c1 and one by c3, over the same token range. Each tree has a root hash, two middle hashes and four leaf hashes, one leaf per slice of the range. The roots differ. Following the differing hashes down, only one leaf differs, the third slice. Repair streams only that slice between the two nodes.\"><defs><marker id=\"mk19-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"175\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">tree built by c1</text><rect x=\"125\" y=\"34\" width=\"100\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">root</text><line x1=\"175\" y1=\"68\" x2=\"100\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"50\" y=\"108\" width=\"100\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hash A</text><line x1=\"175\" y1=\"68\" x2=\"250\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"200\" y=\"108\" width=\"100\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hash B</text><line x1=\"100\" y1=\"142\" x2=\"54\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"20\" y=\"186\" width=\"68\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"54.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">slice 1</text><line x1=\"100\" y1=\"142\" x2=\"132\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"98\" y=\"186\" width=\"68\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"132.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">slice 2</text><line x1=\"250\" y1=\"142\" x2=\"210\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"176\" y=\"186\" width=\"68\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">slice 3</text><line x1=\"250\" y1=\"142\" x2=\"288\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"254\" y=\"186\" width=\"68\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"288.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">slice 4</text><text x=\"525\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">tree built by c3</text><rect x=\"475\" y=\"34\" width=\"100\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"525.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">root</text><line x1=\"525\" y1=\"68\" x2=\"450\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"400\" y=\"108\" width=\"100\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hash A</text><line x1=\"525\" y1=\"68\" x2=\"600\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"550\" y=\"108\" width=\"100\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hash B</text><line x1=\"450\" y1=\"142\" x2=\"404\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"370\" y=\"186\" width=\"68\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"404.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">slice 1</text><line x1=\"450\" y1=\"142\" x2=\"482\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"448\" y=\"186\" width=\"68\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"482.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">slice 2</text><line x1=\"600\" y1=\"142\" x2=\"560\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"526\" y=\"186\" width=\"68\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"560.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">slice 3</text><line x1=\"600\" y1=\"142\" x2=\"638\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><rect x=\"604\" y=\"186\" width=\"68\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"638.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">slice 4</text><text x=\"350\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">roots differ → hash A equal, hash B differs → slice 3 differs, slice 4 equal</text><line x1=\"230\" y1=\"290\" x2=\"470\" y2=\"290\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#mk19-ah-amber)\" marker-start=\"url(#mk19-ah-amber)\"></line><text x=\"350\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">stream slice 3 only</text></svg>", "caption": "Repair compares trees of hashes instead of the data. Equal hashes end the search for that branch, and only the slices whose leaves differ are streamed."}
```

Building the tree means reading the replica's data for that range, which is called a validation
compaction. That reading is most of what repair costs.

## A full repair that finds something

Make the replicas disagree again on two rows, as in the last section, then repair the whole
keyspace from `c1`:

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
cqlsh> UPDATE shop.stock SET units = 0 WHERE sku = 'MN-330';
cqlsh> UPDATE shop.stock SET units = 10 WHERE sku = 'MS-204';
cqlsh> exit
ana@vm:~$ docker start c3
c3
ana@vm:~$ until docker exec c3 cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done
ana@vm:~$ for n in c1 c2; do docker exec $n nodetool enablehandoff; done
```

```
ana@vm:~$ docker exec c1 nodetool repair -full shop | sed -E "s/for range \[.*\] finished/for range [...] finished/"
[2026-10-10 20:24:22,084] Starting repair command #1 (940c5910-c4e8-11f1-8032-c51f469b786c), repairing keyspace shop with repair options (parallelism: parallel, primary range: false, incremental: false, job threads: 1, ColumnFamilies: [], dataCenters: [], hosts: [], previewKind: NONE, # of ranges: 48, pull repair: false, force repair: false, optimise streams: false, ignore unreplicated keyspaces: false, repairPaxos: true, paxosOnly: false)
[2026-10-10 20:24:23,227] Repair session 94278230-c4e8-11f1-8032-c51f469b786c for range [...] finished (progress: 57%)
[2026-10-10 20:24:23,246] Repair completed successfully
[2026-10-10 20:24:23,255] Repair command #1 finished in 1 second
[2026-10-10 20:24:23,265] condition satisfied queried for parent session status and discovered repair completed.
[2026-10-10 20:24:23,265] Repair completed successfully
ana@vm:~$ docker logs --since 1m c1 2>&1 | grep -oE "(Requesting merkle trees|Received merkle tree|Created [0-9]+ sync tasks|Endpoints .* out of sync|Performing streaming repair|shop\.[a-z_]+ is fully synced).*"
Requesting merkle trees for stock (to [/172.18.0.3:7000, /172.18.0.4:7000, /172.18.0.2:7000])
Requesting merkle trees for orders_by_customer (to [/172.18.0.3:7000, /172.18.0.4:7000, /172.18.0.2:7000])
Received merkle tree for orders_by_customer from /172.18.0.2:7000
Received merkle tree for stock from /172.18.0.2:7000
Received merkle tree for orders_by_customer from /172.18.0.4:7000
Received merkle tree for stock from /172.18.0.3:7000
Received merkle tree for stock from /172.18.0.4:7000
Created 2 sync tasks based on 3 merkle tree responses for 940c5910-c4e8-11f1-8032-c51f469b786c (took: 3ms)
Received merkle tree for orders_by_customer from /172.18.0.3:7000
Created 3 sync tasks based on 3 merkle tree responses for 940c5910-c4e8-11f1-8032-c51f469b786c (took: 1ms)
Endpoints /172.18.0.2:7000 and /172.18.0.3:7000 have 4 range(s) out of sync for orders_by_customer
Performing streaming repair of 4 ranges with /172.18.0.3:7000
Endpoints /172.18.0.2:7000 and /172.18.0.4:7000 have 3 range(s) out of sync for orders_by_customer
Endpoints /172.18.0.3:7000 and /172.18.0.4:7000 have 3 range(s) out of sync for orders_by_customer
Performing streaming repair of 3 ranges with /172.18.0.4:7000
Endpoints /172.18.0.3:7000 and /172.18.0.4:7000 have 2 range(s) out of sync for stock
Endpoints /172.18.0.2:7000 and /172.18.0.4:7000 have 2 range(s) out of sync for stock
Performing streaming repair of 2 ranges with /172.18.0.4:7000
shop.orders_by_customer is fully synced
shop.stock is fully synced
```

`nodetool repair` reports the command and the session; the `sed` only replaces the list of 48
ranges with `[...]`. `-full` and the options line's `incremental: false` say this was a full repair.
The node's log says what it did, and the `grep` keeps the lines that tell the story:

- **`Requesting merkle trees`** for each table, to all three replicas, and **`Received merkle tree`**
  from each;
- **`Created 2 sync tasks`** for `stock`: `c3` disagreed with each of the other two on 2 ranges, the
  two rows changed while it was down;
- **`Created 3 sync tasks`** for `orders_by_customer`, with 3 or 4 ranges out of sync between every
  pair of nodes. Those are lesson 16's orders, written when the keyspace had one copy; lesson 17's
  `ALTER` raised it to three and warned that a full repair was needed. **This is that repair.** Each
  order existed on one node, and now it is on three;
- **`fully synced`** for both tables at the end.

Run it again and there is nothing to do:

```
ana@vm:~$ docker exec c1 nodetool repair -full shop stock | grep -E "Starting repair|Repair completed"
[2026-10-10 20:24:24,823] Starting repair command #2 (95b267f0-c4e8-11f1-8032-c51f469b786c), repairing keyspace shop with repair options (parallelism: parallel, primary range: false, incremental: false, job threads: 1, ColumnFamilies: [stock], dataCenters: [], hosts: [], previewKind: NONE, # of ranges: 48, pull repair: false, force repair: false, optimise streams: false, ignore unreplicated keyspaces: false, repairPaxos: true, paxosOnly: false)
[2026-10-10 20:24:25,260] Repair completed successfully
[2026-10-10 20:24:25,266] Repair completed successfully
ana@vm:~$ docker logs --since 20s c1 2>&1 | grep -oE "(Created [0-9]+ sync tasks|shop\.[a-z_]+ is fully synced).*"
Created 2 sync tasks based on 3 merkle tree responses for 940c5910-c4e8-11f1-8032-c51f469b786c (took: 3ms)
Created 3 sync tasks based on 3 merkle tree responses for 940c5910-c4e8-11f1-8032-c51f469b786c (took: 1ms)
shop.orders_by_customer is fully synced
shop.stock is fully synced
Created 0 sync tasks based on 3 merkle tree responses for 95b267f0-c4e8-11f1-8032-c51f469b786c (took: 1ms)
shop.stock is fully synced
```

The `--since 20s` reached back far enough to catch the first repair's last lines as well, the
ones naming `940c5910-…`. The second repair, `95b267f0-…`, says **`Created 0 sync tasks`**: three
equal trees.

## Incremental repair

Repairing everything every time reads all the data every time. **Incremental repair**, the default
when `-full` is not given, marks the SSTables it has repaired and skips them the next time, so each
run only compares data written since the last one:

```
ana@vm:~$ docker exec c1 nodetool tablestats shop.stock | grep -E "Percent repaired|Bytes (un)?repaired"
		Percent repaired: 0.0
		Bytes repaired: 0B
		Bytes unrepaired: 334B
ana@vm:~$ docker exec c1 nodetool repair shop stock | grep -E "Starting repair|Repair completed"
[2026-10-10 20:24:28,017] Starting repair command #3 (97995060-c4e8-11f1-8032-c51f469b786c), repairing keyspace shop with repair options (parallelism: parallel, primary range: false, incremental: true, job threads: 1, ColumnFamilies: [stock], dataCenters: [], hosts: [], previewKind: NONE, # of ranges: 48, pull repair: false, force repair: false, optimise streams: false, ignore unreplicated keyspaces: false, repairPaxos: true, paxosOnly: false)
[2026-10-10 20:24:28,663] Repair completed successfully
[2026-10-10 20:24:28,675] Repair completed successfully
ana@vm:~$ docker exec c1 nodetool tablestats shop.stock | grep -E "Percent repaired|Bytes (un)?repaired"
		Percent repaired: 100.0
		Bytes repaired: 334B
		Bytes unrepaired: 0B
ana@vm:~$ docker exec c1 sh -c "/opt/cassandra/tools/bin/sstablemetadata /var/lib/cassandra/data/shop/stock-*/*Data.db | grep -E \"^SSTable:|Repaired at\""
SSTable: /var/lib/cassandra/data/shop/stock-4fc84de0c4e811f18032c51f469b786c/nb-1-big
Repaired at: 1791663868031 (10/10/2026 20:24:28)
SSTable: /var/lib/cassandra/data/shop/stock-4fc84de0c4e811f18032c51f469b786c/nb-2-big
Repaired at: 1791663868031 (10/10/2026 20:24:28)
SSTable: /var/lib/cassandra/data/shop/stock-4fc84de0c4e811f18032c51f469b786c/nb-3-big
Repaired at: 1791663868031 (10/10/2026 20:24:28)
```

Before, `Percent repaired: 0.0`: a full repair compares data but marks nothing. After `nodetool
repair shop stock`, whose options line says `incremental: true`, **100.0**, and `sstablemetadata`
shows each SSTable stamped with the time it was repaired. From now on an incremental repair of this
table reads only SSTables without that stamp.

Two cautions come with it. Incremental repair keeps repaired and unrepaired data in separate
SSTables, so it changes how compaction behaves. And it trusts the stamp: data on disk that got
damaged after being marked repaired is not looked at again. The usual practice is incremental
repairs often and a full repair now and then, and the next section is about the "often".
