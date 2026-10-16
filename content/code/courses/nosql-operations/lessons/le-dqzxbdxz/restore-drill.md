---
title: The restore drill
version: 1
---

A backup file proves that a backup command ran. It does not prove that the data can be brought
back, by you, on a bad day, in a time anybody would accept. **The only backup that counts is one
that has been restored**, which is the whole of lesson 1 of `db-reliability`. It holds here for the
same reasons: a dump comes out empty because a credential was wrong, an archive is cut off by a
full disk, and a restore takes ten times longer than anybody guessed.

## Into a fresh server

The drill uses a container that has never seen the shop, so that nothing on it can make the
restore look better than it is. Start it, wait a second or two until it answers, copy the archive
in and restore it:

```
ana@vm:~$ docker run -d --name mongo-restore --network nosql mongo:8.0
b96c9fd9230ac1b9e69ea7969d8b61068a8b34afa6f8041cfb4409ae33862d18
ana@vm:~$ docker cp shop.archive.gz mongo-restore:/tmp/shop.archive.gz
ana@vm:~$ time docker exec mongo-restore mongorestore --oplogReplay --gzip --archive=/tmp/shop.archive.gz
2026-10-10T20:15:36.244+0000	preparing collections to restore from
2026-10-10T20:15:36.246+0000	don't know what to do with subdirectory `shop`, skipping...
2026-10-10T20:15:36.246+0000	don't know what to do with subdirectory ``, skipping...
2026-10-10T20:15:36.246+0000	don't know what to do with subdirectory `admin`, skipping...
2026-10-10T20:15:36.286+0000	reading metadata for `shop.orders` from "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:36.286+0000	reading metadata for `shop.customers` from "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:36.286+0000	reading metadata for `shop.payments` from "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:36.286+0000	reading metadata for `shop.products` from "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:36.302+0000	restoring `shop.products` from "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:36.313+0000	finished restoring `shop.products` (4 documents, 0 failures)
2026-10-10T20:15:36.320+0000	restoring `shop.payments` from "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:36.340+0000	finished restoring `shop.payments` (119 documents, 0 failures)
2026-10-10T20:15:36.348+0000	restoring `shop.customers` from "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:36.360+0000	finished restoring `shop.customers` (5 documents, 0 failures)
2026-10-10T20:15:36.369+0000	restoring `shop.orders` from "archive `/tmp/shop.archive.gz`"
2026-10-10T20:15:37.618+0000	finished restoring `shop.orders` (100000 documents, 0 failures)
2026-10-10T20:15:37.618+0000	replaying oplog
2026-10-10T20:15:37.629+0000	applied 26 oplog entries
2026-10-10T20:15:37.629+0000	restoring indexes for collection `shop.orders` from metadata
2026-10-10T20:15:37.629+0000	index: &idx.IndexDocument{Options:bson.M{"name":"customer_1_placedAt_-1", "v":2}, Key:bson.D{bson.E{Key:"customer", Value:1}, bson.E{Key:"placedAt", Value:-1}}, PartialFilterExpression:(*bson.D)(nil)}
2026-10-10T20:15:37.629+0000	index: &idx.IndexDocument{Options:bson.M{"name":"sku_1", "v":2}, Key:bson.D{bson.E{Key:"sku", Value:1}}, PartialFilterExpression:(*bson.D)(nil)}
2026-10-10T20:15:37.629+0000	restoring indexes for collection `shop.customers` from metadata
2026-10-10T20:15:37.629+0000	index: &idx.IndexDocument{Options:bson.M{"name":"email_1", "unique":true, "v":2}, Key:bson.D{bson.E{Key:"email", Value:1}}, PartialFilterExpression:(*bson.D)(nil)}
2026-10-10T20:15:37.629+0000	no indexes to restore for collection `shop.payments`
2026-10-10T20:15:37.629+0000	no indexes to restore for collection `shop.products`
2026-10-10T20:15:37.934+0000	100128 document(s) restored successfully. 0 document(s) failed to restore.

real	0m1.924s
user	0m0.036s
sys	0m0.014s
ana@vm:~$ docker exec mongo-restore mongosh --quiet shop --eval 'for (const c of db.getCollectionNames().sort()) print(c, db[c].countDocuments(), db[c].getIndexes().map(i => i.name).join(" "))'
customers 5 _id_ email_1
orders 100000 _id_ customer_1_placedAt_-1 sku_1
payments 142 _id_
products 4 _id_
ana@vm:~$ docker exec mongo mongosh --quiet shop --eval 'for (const c of db.getCollectionNames().sort()) print(c, db[c].countDocuments(), db[c].getIndexes().map(i => i.name).join(" "))'
customers 5 _id_ email_1
orders 100000 _id_ customer_1_placedAt_-1 sku_1
payments 500 _id_
products 4 _id_
```

`--gzip` and `--archive` match how the dump was written. `--oplogReplay` applies the 26 entries
the dump captured, after the collections and before the indexes, and the log says each step:
documents first, then `applied 26 oplog entries`, then `restoring indexes`, one line per index
definition read from the metadata. The whole restore took 1.924 seconds.

## Checking it, against the original

The last two commands run the same check on the restored server and on the original, and the
lines are the verdict. Customers, orders and products match, count for count and index for index.
**The payments do not, and they are not supposed to:** the restore holds 142, the original 500.
The dump copied 119 payments, and replaying the oplog brought the collection up to the moment the
dump ended; the remaining payments were written after that moment, and no backup taken then
could contain them.

That is what a drill is for. "142 against 500" is a fact you want to have discovered on a
Tuesday afternoon: it measures what a restore loses, the writes after the last backup, and it says
how often backups have to run for that loss to be acceptable.

## What a drill writes down

A drill is finished when somebody has recorded four things, because next time they are what is
compared:

| | in this lesson |
|---|---|
| which backup was restored | the archive from `mongodump --oplog`, 810,350 bytes |
| how long the restore took | 1.924 s |
| what was checked | every collection's count and index names, against the source |
| what did not match, and why | `payments`, 142 against 500: written after the dump ended |

Remove the two servers the drill and the snapshot started, and the volume the snapshot was unpacked
into. Keep `mongo` and its volume `mongo-data`: stopping it gives the VM its memory back, and
`docker start mongo` brings the shop back with its data, because the data lives in the volume:

```sh
docker rm -f mongo-copy mongo-restore
docker volume rm mongo-copy
docker stop mongo
```
