---
title: Cassandra, through nodetool
version: 1
---

Cassandra's trouble rarely arrives as an error. **It arrives as latency at the high percentiles, as
work queuing inside a node, and as reads that do far more work than the rows they return**, and a
node in that state still answers every query. `nodetool` is the window onto all of it, and five of
its commands carry most of what an operator reads. One node is enough to see them, so this section
uses lesson 1's `cassandra` container rather than the three-node cluster of lessons 16 to 19.

```sh
docker rm -f redis redis-replica
docker start cassandra
until docker exec cassandra cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done
```

If lesson 1's container is gone, its `docker run` line with the two `-e` settings makes a new one.

## `nodetool status`: the first command, every time

```
ana@vm:~$ docker exec cassandra nodetool status
Datacenter: datacenter1
=======================
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address     Load        Tokens  Owns (effective)  Host ID                               Rack 
UN  172.18.0.2  124.48 KiB  16      100.0%            bd4227b0-b32f-4436-af79-8b01b4bfc7cf  rack1

```

**Two letters per node, and anything but `UN` is news**: `U` or `D` for up or down as this node's
gossip sees it, then `N`, `L`, `J` or `M` for normal, leaving, joining or moving. In a cluster, a
`DN` line is a node the others cannot reach, and every write meant for it becomes a hint (lesson 19).
`Load` is the data on disk; very different loads on nodes that own equal shares is a partition key
that spreads the data unevenly (lesson 16).

## A table that reads badly on purpose

The shop's basket: one partition per customer, one row per item. Ana adds 2,000 USB-C cables and
removes 1,990 of them, the queue-like pattern lesson 18 warns about; Bruno keeps 50,000 mice, a
partition far larger than the others; three customers hold a sane 20 items each.

```
ana@vm:~$ docker exec -it cassandra cqlsh
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CREATE KEYSPACE shop WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
cqlsh> CREATE TABLE shop.basket (customer text, item int, sku text, PRIMARY KEY (customer, item));
cqlsh> exit
```

The rows are generated as a CSV file in the VM and copied into the container:

```sh
{ seq 1 2000 | sed 's/.*/ana@example.com,&,CB-012/'
  seq 1 50000 | sed 's/.*/bruno@example.com,&,MS-204/'
  for c in carla diego elisa; do seq 1 20 | sed "s/.*/$c@example.com,&,KB-101/"; done
} > basket.csv
docker cp basket.csv cassandra:/basket.csv
```

`COPY ... FROM` is `cqlsh`'s bulk loader. It prints a progress line as it goes, and `tail -1`
keeps its summary:

```
ana@vm:~$ docker exec cassandra cqlsh -e "COPY shop.basket (customer, item, sku) FROM '/basket.csv'" | tail -1
52060 rows imported from 1 files in 0 day, 0 hour, 0 minute, and 1.339 seconds (0 skipped).
```

Then 1,990 deletes, one per removed cable, generated the same way and fed to `cqlsh` on its input:

```sh
seq 1 1990 | sed "s/.*/DELETE FROM shop.basket WHERE customer = 'ana@example.com' AND item = &;/" > emptied.cql
docker exec -i cassandra cqlsh < emptied.cql
```

```
ana@vm:~$ wc -l basket.csv emptied.cql
  52060 basket.csv
   1990 emptied.cql
  54050 total
```

Now read the baskets, Ana's twice:

```
ana@vm:~$ docker exec -it cassandra cqlsh
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> SELECT count(*) FROM shop.basket WHERE customer = 'ana@example.com';

 count
-------
    10

(1 rows)

Warnings :
Read 10 live rows and 1990 tombstone cells for query SELECT * FROM shop.basket WHERE customer = 'ana@example.com' LIMIT 100 ALLOW FILTERING; token 8413089589345688709 (see tombstone_warn_threshold)

cqlsh> SELECT count(*) FROM shop.basket WHERE customer = 'bruno@example.com';

 count
-------
 50000

(1 rows)
cqlsh> SELECT count(*) FROM shop.basket WHERE customer = 'ana@example.com';

 count
-------
    10

(1 rows)

Warnings :
Read 10 live rows and 1990 tombstone cells for query SELECT * FROM shop.basket WHERE customer = 'ana@example.com' LIMIT 100 ALLOW FILTERING; token 8413089589345688709 (see tombstone_warn_threshold)

cqlsh> exit
ana@vm:~$ docker exec cassandra nodetool flush shop basket
```

**Ten rows answered, 1,990 tombstones read to find them.** The warning appears because the read
passed `tombstone_warn_threshold`, 1,000 by default; at `tombstone_failure_threshold`, 100,000, the
read is refused instead. The client sees the warning only if somebody prints it, and most drivers do
not. The node keeps count either way, and `nodetool flush` writes the memtable out to an SSTable so
the per-partition sizes below have something on disk to measure.

## `tablestats` and `tablehistograms`: the table's own story

`tablestats` prints some forty lines per table; these are the ones about this table's health:

```
ana@vm:~$ docker exec cassandra nodetool tablestats shop.basket | grep -E "SSTable count|Number of partitions|Local read latency|Compacted partition|tombstones per slice"
		SSTable count: 1
		Old SSTable count: 0
		Number of partitions (estimate): 5
		Local read latency: 0.163 ms
		Compacted partition minimum bytes: 373
		Compacted partition maximum bytes: 1131752
		Compacted partition mean bytes: 232523
		Average tombstones per slice (last five minutes): 10.137176938369782
		Maximum tombstones per slice (last five minutes): 2299
```

**`Maximum tombstones per slice` is 2,299, and a slice is one read of one partition.** The read
counted 1,990; the figure is 2,299 because these statistics are kept in histograms with fixed
buckets, and 2,299 is the upper edge of the bucket 1,990 falls into. The average, 10.1, is spread
over every read of the last five minutes, which is why it hides the problem and the maximum shows
it. Lesson 18 says what to do about a table that reads like this.

**`Compacted partition maximum bytes` is 1,131,752, against a mean of 232,523 and a minimum of
373.** That maximum is Bruno's partition, 50,000 rows in about a megabyte. A partition of a megabyte
is fine; the number to fear is one heading for hundreds of megabytes, which every read and every
compaction of it has to carry. The histograms say the same per percentile:

```
ana@vm:~$ docker exec cassandra nodetool tablehistograms shop basket
shop/basket histograms
Percentile      Read Latency     Write Latency          SSTables    Partition Size        Cell Count
                    (micros)          (micros)                             (bytes)                  
50%                    86.00             72.00              0.00               446                20
75%                   124.00            124.00              0.00             29521                20
95%                   310.00            310.00              0.00           1131752             51012
98%                   535.00           9887.00              0.00           1131752             51012
99%                   924.00          24601.00              0.00           1131752             51012
Min                    21.00              4.00              0.00               373                 9
Max                 14237.00         219342.00              0.00           1131752             51012

```

Half the partitions are 446 bytes or less and the largest holds 51,012 cells by the same bucketing.
The `SSTables` column is how many SSTables each read had to open, 0 here because every read was
served from the memtable before the flush; on a table that is read after many flushes, a median
climbing past a handful is compaction falling behind.

## `proxyhistograms`: latency as the client sees it

`tablehistograms` times the local work on one table. `proxyhistograms` times the whole request at
the node that coordinated it, which in a cluster includes waiting for the other replicas:

```
ana@vm:~$ docker exec cassandra nodetool proxyhistograms
proxy histograms
Percentile       Read Latency      Write Latency      Range Latency   CAS Read Latency  CAS Write Latency View Write Latency
                     (micros)           (micros)           (micros)           (micros)           (micros)           (micros)
50%                    258.00             535.00            6866.00               0.00               0.00               0.00
75%                    372.00            1109.00           14237.00               0.00               0.00               0.00
95%                   1331.00           29521.00           20501.00               0.00               0.00               0.00
98%                   2299.00           61214.00           42510.00               0.00               0.00               0.00
99%                   4768.00          105778.00           42510.00               0.00               0.00               0.00
Min                     61.00             104.00            1332.00               0.00               0.00               0.00
Max                  14237.00          219342.00           42510.00               0.00               0.00               0.00

```

**Read the 99th percentile, never the median.** Reads have a median of 258 µs and a p99 of
4,768 µs, almost twenty times more; writes have a median of 535 µs and a p99 of 105,778 µs, because
the bulk load sent large batches. The median says how most requests feel, and the p99 is what one
page in a hundred waits for. These numbers are kept since the node started, so watch them as a
rate over time from an exporter rather than reading the totals.

## `tpstats` and `compactionstats`: work waiting

```
ana@vm:~$ docker exec cassandra nodetool tpstats | grep -E "^(Pool Name|ReadStage|MutationStage|Native-Transport-Requests|CompactionExecutor|Message type|READ_REQ|MUTATION_REQ) "
Pool Name                      Active Pending Completed Blocked All time blocked
MutationStage                  0      0       2661      0       0               
ReadStage                      0      0       610       0       0               
CompactionExecutor             0      0       58        0       0               
Native-Transport-Requests      0      0       4743      0       0               
Message type                      Dropped     50%      95%      99%      Max
MUTATION_REQ                      0           0.0      0.0      0.0      0.0
READ_REQ                          0           0.0      0.0      0.0      0.0
ana@vm:~$ docker exec cassandra nodetool compactionstats
concurrent compactors            2          
pending tasks                    0          
compactions completed            4          
data compacted                   81003      
compressed data compacted        22194      
compactions aborted              0          
compactions reduced              0          
sstables dropped from compaction 0          
15 minute rate                   0.26/minute
mean rate                        183.75/hour
compaction throughput (MiB/s)    64.0       
```

Each stage of a node is a thread pool with a queue in front of it. **`Pending` that stays above zero
means a stage cannot keep up; `Blocked` means its queue is full and work is being held back
upstream.** The second table is the one that matters most: a **dropped** `MUTATION_REQ` is a write
that waited longer than its timeout and was thrown away by this replica. The client may still have
been told the write succeeded, at a consistency level other replicas satisfied, and the copy on this
node is now missing until repair puts it back (lesson 19).

`pending tasks` in `compactionstats` is the compactions waiting to run. Zero, as here, is a node
keeping up; a number that grows hour after hour is a node writing faster than it can merge, and the
SSTable count per read and the read latency follow it upwards a day later.

Everything here is zero because one node with this load has nothing to queue. That is the honest
picture of a healthy node, and the reason these are the counters an alert watches: they stay at
zero until the day they do not.
