---
title: On demand or provisioned, in dollars
version: 1
---

**A provisioned stream is billed for its shards, whether anything is written or not; an on-demand
stream is billed for the stream and for every gigabyte through it.** The first is cheap when you know
the load and size the shards to it. The second costs more per gigabyte and buys you the right not to
know: AWS adds and removes shards behind it as traffic changes. Neither is cheaper in general, and the
way to decide is to put a workload through both. The prices, from the sheet of lesson 1:

```
ana@laptop:~/aws$ python3 prices.py kinesis
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
```

**Two lines of the provisioned half need reading carefully.** A shard-hour is one shard for one hour,
so a month of one shard is 730 of them. And a **PUT payload unit** is 25 KB of one record: a record of
1 KB costs one unit, the same as a record of 25 KB, and a record of 30 KB costs two. The on-demand half
charges by the gigabyte instead, written and read separately, and every consumer that reads the
stream pays the read line again.

moto keeps the two modes apart in its answers, and charges for neither, as it never does. The stream
of this lesson beside a new on-demand one:

```
ana@laptop:~/aws$ aws kinesis create-stream --stream-name orders-od --stream-mode-details StreamMode=ON_DEMAND
ana@laptop:~/aws$ aws kinesis describe-stream-summary --stream-name orders --query 'StreamDescriptionSummary.[StreamName,StreamModeDetails.StreamMode,OpenShardCount]' --output text
orders	PROVISIONED	4
ana@laptop:~/aws$ aws kinesis describe-stream-summary --stream-name orders-od --query 'StreamDescriptionSummary.[StreamName,StreamModeDetails.StreamMode,OpenShardCount]' --output text
orders-od	ON_DEMAND	4
```

## A steady month

Quitanda's order events, all of them: 20 million records a day, about 1 KB each, which is 20 GB a
day, read by two consumers, a fraud check and the copy to S3 of lesson 21. Traffic is not flat: at
lunch and dinner it runs at five times the day's average. A month here is 30 days and 730 hours.

**Sizing the provisioned stream comes first.** The average is 20 million records over 86,400 seconds,
about 231 a second; the peak is five times that, about 1,157 records a second, which is more than one
shard's 1,000. In bytes the peak is about 1.2 MB a second, also above one shard. Two shards would be
exactly full at peak; three leave room.

| provisioned, 3 shards | arithmetic | USD per month |
|---|---|---|
| shard-hours | 3 × 730 × 0.03000 | 65.70 |
| PUT payload units | 20 million × 30 days = 600 million, × 0.02800 per million | 16.80 |
| **total** | | **82.50** |

| on demand | arithmetic | USD per month |
|---|---|---|
| the stream | 730 × 0.08000 | 58.40 |
| data written | 20 GB × 30 = 600 GB, × 0.16000 | 96.00 |
| data read, two consumers | 2 × 600 GB × 0.08000 | 96.00 |
| **total** | | **250.40** |

**Three times the price for the same records**, and the gap grows with every consumer added, since
each one pays the read line on demand and nothing extra on a provisioned stream until the shards'
2 MB a second of reading runs out. For a load that is known and steady, provisioned wins on price,
and the cost of winning is that somebody watches the traffic and reshards when it grows.

**Keeping a week rather than a day** is the extended-retention line, paid per shard-hour on top of the
shard itself: 3 × 730 × 0.04000 = 87.60 a month, which more than doubles the provisioned bill to
170.10. On demand, the same retention is billed per gigabyte stored, a line the sheet does not print,
so it is not priced here.

## A month with a promotion in it

Now give the same month one Friday on which a promotion sends 30 MB a second for an hour. **A
provisioned stream has to be sized for its peak or resharded in time for it.** Sized for the peak, it
needs 30 shards for the whole month, 30 × 730 × 0.03000 = 657.00 in shard-hours alone, eight times the
steady bill, for capacity used one hour in 730. Resharding to 30 before the promotion and back after
it keeps the bill near 82.50, and makes the promotion depend on someone remembering to do it, and on
the reshard finishing in time.

The on-demand stream needs no decision about capacity. The promotion's hour is 30 MB × 3,600 seconds,
108 GB, which costs 108 × 0.16000 = 17.28 written and 2 × 108 × 0.08000 = 17.28 read, and the month
becomes 250.40 + 34.56 = 284.96, less than half the stream sized for the peak. **What on demand sells
is not a lower price; it is not having to know the peak in advance.**

It does not know the peak in advance either, and this part comes from AWS's documentation rather than
from a run: an on-demand stream absorbs at once up to double the highest write rate it has seen in the
previous 30 days, and grows beyond that over some minutes. A jump to twenty-five times the usual peak
is throttled while it grows, unless the stream has seen such a peak before. A new stream whose traffic
nobody can predict starts on demand; a stream whose traffic has been watched for a few months is
usually moved to provisioned, and a stream can be switched between the two modes while it runs.
