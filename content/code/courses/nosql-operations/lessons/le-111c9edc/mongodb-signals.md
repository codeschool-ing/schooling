---
title: MongoDB, the handful of numbers among hundreds
version: 1
---

The first instinct is to watch the machine: processor, memory, disk. Those graphs matter, but a
database in trouble often looks calm from outside. **The numbers that say a database is in trouble
are the ones the database reports about itself**, and `db.serverStatus()` returns several hundred of
them. This section picks the six that decide something, and makes each one move on purpose.

## The set to watch

The signals worth watching on MongoDB are the ones of a replica set, so this section rebuilds the
three-member set of lesson 9 with one addition. Lesson 1's containers are stopped first, to give the
VM their memory back:

```sh
docker stop mongo redis cassandra
for n in 1 2 3; do
  docker run -d --name mongo$n --network nosql mongo:8.0 mongod --replSet rs0 --bind_ip_all --wiredTigerCacheSizeGB 0.25
done
```

```sh
docker exec mongo1 mongosh --quiet --eval 'rs.initiate({ _id: "rs0", members: [
  { _id: 0, host: "mongo1:27017" }, { _id: 1, host: "mongo2:27017" }, { _id: 2, host: "mongo3:27017" } ] })'
```

**The addition is `--wiredTigerCacheSizeGB 0.25`.** WiredTiger, MongoDB's storage engine, keeps a
cache of its own, and by default sizes it at half of the memory minus 1 GB, or 256 MB if that is
larger. On the lab's 15.7 GiB machine that would be over 7 GB, and nothing in this lesson would
come close to filling it. A quarter of a gigabyte fills in seconds, which is the point.

Give the election a few seconds and check the roles:

```
ana@vm:~$ docker exec mongo1 mongosh --quiet --eval 'rs.status().members.map(m => m.name + " " + m.stateStr)'
[
  'mongo1:27017 PRIMARY',
  'mongo2:27017 SECONDARY',
  'mongo3:27017 SECONDARY'
]
```

## A load to watch it under

A database at rest reports zeros. This script writes 600,000 orders of the shop in batches of a
thousand. Each carries a 200-byte note, so that the data outgrows the small cache:

```javascript
// load.js: the shop's orders, written in batches of 1,000
const customers = ["ana", "bruno", "carla", "diego", "elisa"];
const products = [["KB-101", 34990], ["MS-204", 18900], ["MN-330", 149900], ["CB-012", 3990]];
for (let b = 0; b < 600; b++) {
  const batch = [];
  for (let i = 1; i <= 1000; i++) {
    const n = b * 1000 + i;
    const [sku, cents] = products[n % 4];
    batch.push({ n: n, customer: customers[n % 5] + "@example.com",
                 items: [{ sku: sku, qty: 1 + (n % 3), cents: cents }],
                 note: "x".repeat(200) });
  }
  db.orders.insertMany(batch);
}
```

Save it as `load.js`, copy it into the primary's container, and start it in the background with
`-d`, so the terminal is free to watch:

```sh
docker cp load.js mongo1:/load.js
docker exec -d mongo1 mongosh --quiet shop /load.js
```

## `mongostat`: one line a second

`mongostat` ships in the image and prints a line of rates every second; `-n 5` stops after five:

```
ana@vm:~$ docker exec mongo1 mongostat -n 5
insert query update delete getmore command dirty  used flushes vsize  res qrw arw net_in net_out conn set repl                time
 51858    *0     *0     *0     382   539|0  6.5% 38.2%       0 3.90G 323M 0|0 0|0  18.0m   45.6m   18 rs0  SLV Oct 10 07:41:19.111
 46366    *0     *0     *0     335   518|0  9.6% 48.3%       0 3.90G 343M 0|0 0|0  16.1m   40.8m   18 rs0  SLV Oct 10 07:41:20.081
 60935    *0     *0     *0     455   715|0  2.3% 54.7%       0 3.90G 374M 0|0 0|0  21.2m   53.6m   18 rs0  SLV Oct 10 07:41:21.082
 58988    *0     *0     *0     445   692|0  4.4% 66.3%       0 3.90G 395M 0|0 0|0  20.6m   51.9m   18 rs0  SLV Oct 10 07:41:22.083
 56810    *0     *0     *0     435   670|0  2.6% 70.4%       0 3.90G 415M 0|0 0|0  19.8m   50.0m   18 rs0  SLV Oct 10 07:41:23.086
ana@vm:~$ docker exec mongo1 mongosh --quiet --eval 'rs.status().members.map(m => m.name + " " + m.stateStr)'
[
  'mongo1:27017 PRIMARY',
  'mongo2:27017 SECONDARY',
  'mongo3:27017 SECONDARY'
]
```

Between 46,366 and 60,935 inserts a second, and the `used` column climbing from 38.2% to 70.4% of
the cache in five seconds. `qrw` and `arw` are operations queued and active, readers before the bar
and writers after it; **a queue that stays above zero is the first sign of a server that cannot keep
up**, and here it is `0|0` throughout.

**Read the `repl` column with suspicion.** It says `SLV`, secondary, on every line, and the command
right after it shows `mongo1` is the primary. This version of the tool reports the role wrongly
against an 8.0 server. A monitoring tool is software with bugs of its own, and the role of a member
is taken from `rs.status()`, which is the replica set's own answer.

## `db.serverStatus()`: the same numbers, from inside

`mongostat` is a reader of `serverStatus`. Asking directly gives the counters it turns into rates,
and the cache figures it rounds:

```
ana@vm:~$ docker exec -it mongo1 mongosh --quiet shop
rs0 [direct: primary] shop> const s = db.serverStatus()

rs0 [direct: primary] shop> s.connections.current
19
rs0 [direct: primary] shop> s.opcounters
{
  insert: Long('543002'),
  query: Long('42'),
  update: Long('0'),
  delete: Long('0'),
  getmore: Long('4016'),
  command: Long('6313')
}
rs0 [direct: primary] shop> const c = s.wiredTiger.cache

rs0 [direct: primary] shop> const max = c["maximum bytes configured"]

rs0 [direct: primary] shop> max / 1024 / 1024
256
rs0 [direct: primary] shop> (100 * c["bytes currently in the cache"] / max).toFixed(1)
68.7
rs0 [direct: primary] shop> (100 * c["tracked dirty bytes in the cache"] / max).toFixed(1)
4.2
rs0 [direct: primary] shop> exit
```

What each one is for:

| field | what it is | when it means trouble |
|---|---|---|
| `connections.current` | open client connections, 19 here | a steady climb towards `available`: a pool that leaks, or an application scaled out without anyone sizing the connections |
| `opcounters` | operations since the server started, by kind | never on its own. It only ever goes up; the signal is the rate, which is what `mongostat` prints |
| cache used | 68.7% of the 256 MB | held above 95%, where WiredTiger makes the threads serving your queries stop and evict pages themselves |
| cache dirty | 4.2%, changes not yet written to disk | held above 20%, the same stall for writes |

The two cache thresholds are WiredTiger's defaults: it starts evicting in the background at 80% used
and 5% dirty, and drafts the application's own threads at 95% and 20%. **A cache at 80% is a cache
doing its job.** One that sits at 95% is a server whose every query now waits for housekeeping, and
the latency graph shows it before anything else does.

## Replication lag, made on purpose

A secondary that falls behind is invisible to the application until there is a failover, and then
the writes it never applied are lost or rolled back (lesson 9). To make one fall behind, lock
`mongo3` for writes the way a filesystem snapshot does in lesson 11, and run the load again:

```
ana@vm:~$ docker exec mongo3 mongosh --quiet --eval 'db.fsyncLock().lockCount'
Long('1')
ana@vm:~$ docker exec mongo1 mongosh --quiet shop /load.js
ana@vm:~$ docker exec mongo1 mongosh --quiet --eval 'rs.printSecondaryReplicationInfo()'
source: mongo2:27017
{
  syncedTo: 'Sat Oct 10 2026 07:41:44 GMT+0000 (Coordinated Universal Time)',
  replLag: '0 secs (0 hrs) behind the primary '
}
---
source: mongo3:27017
{
  syncedTo: 'Sat Oct 10 2026 07:41:26 GMT+0000 (Coordinated Universal Time)',
  replLag: '18 secs (0.01 hrs) behind the primary '
}
ana@vm:~$ docker exec mongo3 mongosh --quiet --eval 'db.fsyncUnlock().lockCount'
Long('0')
ana@vm:~$ docker exec mongo1 mongosh --quiet --eval 'rs.printSecondaryReplicationInfo()'
source: mongo2:27017
{
  syncedTo: 'Sat Oct 10 2026 07:41:44 GMT+0000 (Coordinated Universal Time)',
  replLag: '0 secs (0 hrs) behind the primary '
}
---
source: mongo3:27017
{
  syncedTo: 'Sat Oct 10 2026 07:41:44 GMT+0000 (Coordinated Universal Time)',
  replLag: '0 secs (0 hrs) behind the primary '
}
```

`mongo3` was **18 seconds behind** while it was locked, and caught up within seconds of the unlock.
The writes went on succeeding the whole time, because the default write concern needs a majority
and `mongo1` and `mongo2` were a majority. Nothing the application saw would have told it.

**The lag is measured in the primary's time, not the clock's.** `syncedTo` is the time of the last
write the secondary has applied, and the lag is how far that sits behind the primary's own last
write. On a primary that has not been written to for a while, a stuck secondary looks less far
behind than it is. The times are UTC because the containers keep UTC, whatever the VM's zone.

## The slow operation, while it is running

A query that examines every document in a collection is the commonest slow operation there is.
This one is slow on purpose: a `$where` runs JavaScript for every document, and `sleep(5)` makes
each one cost five milliseconds. Over the 1,200,000 orders the two loads wrote, that is 6,000
seconds, an hour and forty minutes. Start it in the background, and find it from another shell:

```
ana@vm:~$ docker exec -d mongo1 mongosh --quiet shop --eval 'db.orders.find({ $where: "sleep(5) || false" }).itcount()'
ana@vm:~$ docker exec -it mongo1 mongosh --quiet shop
rs0 [direct: primary] shop> const slow = db.currentOp({ ns: "shop.orders", secs_running: { $gte: 2 } }).inprog

rs0 [direct: primary] shop> slow.map(o => ({ opid: o.opid, secs_running: o.secs_running, planSummary: o.planSummary, filter: o.command.filter }))
[
  {
    opid: 118785,
    secs_running: Long('5'),
    planSummary: 'COLLSCAN',
    filter: { '$where': 'sleep(5) || false' }
  }
]
rs0 [direct: primary] shop> db.killOp(slow[0].opid).info
attempting to kill op
rs0 [direct: primary] shop> db.getProfilingStatus().slowms
100
rs0 [direct: primary] shop> db.adminCommand({ getLog: "global" }).log.map(JSON.parse).filter(l => l.msg == "Slow query" && l.attr.command.find).map(l => ({ ns: l.attr.ns, planSummary: l.attr.planSummary, durationMillis: l.attr.durationMillis, errName: l.attr.errName }))
[
  {
    ns: 'shop.orders',
    planSummary: 'COLLSCAN',
    durationMillis: 7283,
    errName: 'Interrupted'
  }
]
rs0 [direct: primary] shop> exit
```

`db.currentOp()` takes a filter like a query does, and this one asks for anything on `shop.orders`
running for two seconds or more. **`COLLSCAN` in `planSummary` is the word to look for**: a scan of
the whole collection, the thing lesson 7's indexes exist to avoid. `db.killOp()` ends it.

The second half is the **slow query log**. Every operation that takes longer than `slowms`, 100
milliseconds by default, is written to the server's log as a `Slow query` line, profiler on or off.
`getLog` returns the last lines of that log as JSON, and the killed query is there with its 7,283
milliseconds and `Interrupted`. Outside the shell the same lines are in `docker logs mongo1`, one
long JSON object each; a log collector is what turns them into a list of the worst queries of the
day.
