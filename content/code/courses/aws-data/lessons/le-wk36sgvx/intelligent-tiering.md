---
title: Intelligent-Tiering, and the fee for being watched
version: 1
---

**Intelligent-Tiering is a class that moves each object between tiers by itself**, according to
when it was last read, and charges a monthly fee per object for keeping watch. It is the answer to
"we do not know how this data will be read", and it is the wrong answer for small objects, because
the fee is per object and the saving is per gigabyte.

AWS documents its tiers like this. An object starts in the frequent access tier, priced like
Standard. After 30 consecutive days without being read it moves to an infrequent access tier, and
after 90 days to an archive instant access tier, both cheaper and both read in milliseconds. A read
moves it back to frequent. Two more tiers, archive access and deep archive access, are off unless a
bucket turns them on, and an object there has to be restored like a Glacier one. There is no
retrieval fee, no minimum duration, and no charge for a move between tiers.

The price sheet prints two of its lines:

```
  Intelligent-Tiering, frequent                         0.04050  GB-month
  Intelligent-Tiering monitoring, per 1,000 objects     0.00250  per month
```

The sheet does not print the infrequent and archive tiers' prices, so this course does not quote a
saving. What the two lines above are enough for is the cost of being watched.

## The fee against the object

**Objects under 128 KB are not monitored and not charged the fee**; they stay in the frequent tier
for as long as they exist, at Standard's price. So the smallest object that pays the fee is 128 KB,
and for that object the arithmetic is:

- its storage in the frequent tier: 128 KB is 128 / 1,048,576 GB, and that × 0.04050 is 0.00000494
  USD a month;
- its monitoring: 0.00250 / 1,000 is 0.00000250 USD a month.

**The fee is half the price of keeping the object**, for a 128 KB file that is never read and moves
nowhere. Even if a cheaper tier made the storage free, the fee alone would stop the object from
costing less than half of Standard. At 1 MB the fee falls to about 6% of the frequent price, and at
100 MB to well under a tenth of a per cent. Intelligent-Tiering pays for large objects with an
unknown future: the data lake's Parquet files of lesson 19, not the 10 KB events of a click stream.

## In moto

The class itself is accepted like any other, and the configuration that turns on the two archive
tiers is not:

```
ana@laptop:~/aws$ aws s3 cp export/orders-2026-09.csv s3://quitanda-archive-prod/orders/2026-09/auto.csv --storage-class INTELLIGENT_TIERING
upload: export/orders-2026-09.csv to s3://quitanda-archive-prod/orders/2026-09/auto.csv
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-archive-prod --key orders/2026-09/auto.csv --query StorageClass
"INTELLIGENT_TIERING"
ana@laptop:~/aws$ aws s3api put-bucket-intelligent-tiering-configuration --bucket quitanda-archive-prod --id archive-after-90 --intelligent-tiering-configuration 'Id=archive-after-90,Status=Enabled,Tierings=[{Days=90,AccessTier=ARCHIVE_ACCESS}]'

aws: [ERROR]: An error occurred (IllegalLocationConstraintException) when calling the PutBucketIntelligentTieringConfiguration operation: The unspecified location constraint is incompatible for the region specific endpoint this request was sent to.
```

**`IllegalLocationConstraintException` is not an answer about Intelligent-Tiering**: it is the error
for creating a bucket in the wrong region. moto 5.2.3 does not implement this call, and the request,
a `PUT` on the bucket's address, reached the code that creates buckets. Nothing about the archive
tiers can be practised here, and nothing in this section depends on it. moto does not move an object
between tiers either, since nothing in moto ever happens on its own as time passes.
