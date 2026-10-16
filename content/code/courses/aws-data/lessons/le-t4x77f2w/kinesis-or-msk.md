---
title: Kinesis or MSK, for one workload
version: 1
---

**Kinesis sells shards and records; MSK sells brokers and disks.** That difference in what is billed
decides most of the comparison, so the comparison starts from the prices:

```
ana@laptop:~/aws$ python3 prices.py kinesis msk
AWS public price list, sa-east-1, USD, excluding tax

Kinesis Data Streams, USD
  provisioned, per shard-hour                           0.03000  hour
  provisioned, per million PUT payload units            0.02800  million
  provisioned, extended retention, per shard-hour       0.04000  hour
  on demand, per stream-hour                            0.08000  hour
  on demand, data written                               0.16000  GB
  on demand, data read                                  0.08000  GB

Data Firehose, USD per GB
  ingested, first 500 TB                                0.05800  GB
  format conversion                                     0.03500  GB
  dynamic partitioning                                  0.03100  GB

MSK, USD
  kafka.t3.small, per broker-hour                       0.07360  hour
  kafka.m7g.large, per broker-hour                      0.32530  hour
  kafka.m7g.xlarge, per broker-hour                     0.65030  hour
  broker storage                                        0.19000  GB-month
  Serverless, per cluster-hour                          1.19500  hour
  Serverless, per partition-hour                        0.00240  hour
  Serverless, data in                                   0.16000  GB
ana@laptop:~/aws$ python3 prices.py transfer | grep zones
  between zones, each direction                         0.01000  GB
```

The workload is the one lessons 20 and 21 priced: Quitanda's order events, 20 GB a day in records of
about 1 KB, read by two consumers, kept for seven days, in a month of 30 days and 730 hours.

## The same month, three ways

| Kinesis, provisioned, 3 shards (lesson 20) | arithmetic | USD per month |
|---|---|---|
| shard-hours | 3 × 730 × 0.03000 | 65.70 |
| PUT payload units | 600 million × 0.02800 per million | 16.80 |
| seven days of retention | 3 × 730 × 0.04000 | 87.60 |
| **total** | | **170.10** |

| MSK, provisioned, 3 × `kafka.m7g.large` in 3 zones | arithmetic | USD per month |
|---|---|---|
| broker-hours | 3 × 730 × 0.32530 | 712.41 |
| storage: 7 days × 20 GB × 3 copies = 420 GB, provisioned as 200 GB a broker | 600 × 0.19000 | 114.00 |
| clients crossing zones: two in three bytes reach a leader in another zone | 1,200 GB × 2 × 0.01000 | 24.00 |
| **total** | | **850.41** |

| MSK Serverless | arithmetic | USD per month |
|---|---|---|
| the cluster | 730 × 1.19500 | 872.35 |
| 3 partitions | 3 × 730 × 0.00240 | 5.26 |
| data in | 600 GB × 0.16000 | 96.00 |
| **total of the lines the sheet prints** | | **973.61** |

**The zone line needs its arithmetic.** Producers write 600 GB a month and two consumers read 1,200
GB; with leaders spread over three zones, two thirds of those 1,800 GB, which is 1,200 GB, cross a zone, and the
crossing is billed in each direction. Replication between the brokers is not billed, as the
replication section said. **The Serverless total is a floor**: MSK Serverless also bills data read and
data stored, and the sheet prints neither line, so the true figure is higher.

**At this size Kinesis is five times cheaper than the provisioned cluster, and the reason is the
fixed part.** Three `m7g.large` brokers cost 712.41 a month before a byte is written, and 20 GB a day
uses a small fraction of what they can carry. A cluster of `kafka.t3.small` brokers would bring it to
3 × 730 × 0.07360 = 161.18 for the brokers and 299.18 in all, which is AWS's development size and not
one to put production on.

## Where the lines cross

Grow the workload and the two bills grow differently. Per GB a day of traffic, from the tables above:

| per GB a day | Kinesis | MSK provisioned |
|---|---|---|
| fixed, whatever the traffic | 0 | 712.41 |
| for each GB a day | 170.10 / 20 = 8.51 | (114.00 + 24.00) / 20 = 6.90 |

**They meet roughly where 8.51 × v = 712.41 + 6.90 × v, at about 440 GB a day**, twenty-two times Quitanda's
volume, and MSK is the cheaper one above it, as long as the same three brokers can carry the load.
Whether they can is a question of broker throughput, partitions and network, which AWS's sizing
guidance for MSK answers and this course did not measure, so read the crossing as where to start
looking rather than as a result. Two more things move it: tiered storage lowers MSK's per-GB line, and
on the Kinesis side records packed several to a payload unit lower the PUT line.

## What the price does not decide

| | Kinesis Data Streams | MSK |
|---|---|---|
| ordering | per shard | per partition, and adding partitions moves keys |
| retention | 24 hours to 365 days, by age only | by time or size, unlimited with tiered storage, or compaction per key |
| many consumers | 2 MB a second per shard shared, or enhanced fan-out per consumer | each group reads at the broker's speed, no per-group charge |
| ecosystem | AWS's own: Firehose, Lambda, the Kinesis Client Library | Kafka's: any Kafka client, Kafka Connect, Kafka Streams, transactions |
| operations | no brokers, a shard count or on demand | broker type and count, disks, partitions, replication settings, upgrades |

**Kinesis wins when the team wants a stream and not a system**: modest volume, AWS consumers, nobody
whose job is Kafka. **MSK wins when Kafka itself is the requirement**: an existing estate of Kafka
clients and connectors, a retention of months, compacted topics used as tables, many consumer groups,
or the transactions of lesson 23. And above a few hundred GB a day, if the brokers carry it, it wins
on price as well.
