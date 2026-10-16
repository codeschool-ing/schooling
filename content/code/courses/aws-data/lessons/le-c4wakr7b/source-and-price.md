---
title: A Kinesis stream as the source, and what it costs
version: 1
---

**A delivery stream can read a Kinesis data stream instead of being written to directly**, and that
is the usual way the two meet. The stream of lesson 20 serves the programs that need each event in
seconds; Firehose becomes one more consumer of it, and its whole job is to keep a copy of everything
in S3, long after the stream's retention has removed it. Lesson 20 ended on that: the answer to
"replay last month" is not a longer retention, it is the lake.

The source is given at creation, with the stream's ARN and a role Firehose may read it with:

```
ana@laptop:~/aws$ aws kinesis create-stream --stream-name orders --shard-count 1
ana@laptop:~/aws$ aws firehose create-delivery-stream --delivery-stream-name orders-from-stream --delivery-stream-type KinesisStreamAsSource --kinesis-stream-source-configuration KinesisStreamARN=arn:aws:kinesis:sa-east-1:123456789012:stream/orders,RoleARN=arn:aws:iam::123456789012:role/quitanda-firehose --extended-s3-destination-configuration RoleARN=arn:aws:iam::123456789012:role/quitanda-firehose,BucketARN=arn:aws:s3:::quitanda-raw-prod,Prefix=raw/orders-from-stream/
{
    "DeliveryStreamARN": "arn:aws:firehose:sa-east-1:123456789012:deliverystream/orders-from-stream"
}
ana@laptop:~/aws$ aws kinesis put-record --stream-name orders --partition-key c-17 --cli-binary-format raw-in-base64-out --data '{"order_id": "o-206"}'
{
    "ShardId": "shardId-000000000000",
    "SequenceNumber": "1"
}
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/raw/orders-from-stream/ --recursive
ana@laptop:~/aws$ aws firehose put-record --delivery-stream-name orders-from-stream --cli-binary-format raw-in-base64-out --record '{"Data": "{\"order_id\": \"o-207\"}"}'
{
    "RecordId": "f383c9d0-1712-4940-97a2-e4fb97647365",
    "Encrypted": false
}
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/raw/orders-from-stream/ --recursive
2026-10-16 13:11:02         21 raw/orders-from-stream/2026/10/16/16/orders-from-stream-1-2026-10-16-16-11-02-a9dd7281-348b-4cab-b031-0bc8fd1b7f28
```

**moto connected nothing.** The record put into the Kinesis stream never reached the bucket, whose
listing came back empty; moto keeps the source in the configuration and does not read from it. Then
it accepted a `put-record` sent straight to the delivery stream and delivered that one. AWS does the
opposite on both counts, from its documentation: a delivery stream with a Kinesis source reads the
stream continuously, and refuses `PutRecord` and `PutRecordBatch`, because its records may only come
from the stream. So the pairing can be configured in the lab and not observed.

On AWS the delivery stream reads the stream as a consumer like any other, so it shares the shards'
2 MB a second of reading with the other ordinary consumers of lesson 20, and it reads each shard in
order. Ordering inside an object is therefore the order of a shard, and records from different shards
interleave, as they did in lesson 20's consumer.

## The bill

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

**Ingestion is billed per gigabyte, but not per gigabyte sent.** AWS's pricing page, which this
sheet reads the price from but not the rule, says that each record is rounded up to the next 5 KB
before it is counted. For Quitanda's order events, 20 million records a day of about 1 KB each, that
rule is the whole bill:

| ingestion, one event per record | arithmetic | USD per month |
|---|---|---|
| billed size | 20 million × 5 KB = 100 GB a day, × 30 days = 3,000 GB | |
| ingestion | 3,000 × 0.05800 | 174.00 |

**Five times the data that was sent**, because each 1 KB record is counted as 5 KB. Packing five
events into one record of 5 KB, which the producer can do by joining five JSON lines with their
newlines, sends the same bytes as 4 million records a day:

| ingestion, five events per record | arithmetic | USD per month |
|---|---|---|
| billed size | 4 million × 5 KB = 20 GB a day, × 30 days = 600 GB | |
| ingestion | 600 × 0.05800 | 34.80 |
| format conversion to Parquet | 600 × 0.03500 | 21.00 |
| dynamic partitioning by store | 600 × 0.03100 | 18.60 |
| **total** | | **74.40** |

**The packing costs one line of the producer and saves 139.20 a month**, and it is invisible in the
lab, where moto counts nothing. The two optional lines are each billed on the same gigabytes;
dynamic partitioning also has charges per object written and per hour of `jq` processing that the
sheet does not print, so its real line is somewhat higher than 18.60. And the S3 the objects land in is
billed separately, at the storage prices of lesson 2.

Beside lesson 20, the shape is clear: a provisioned Kinesis stream for the same events cost 82.50 a
month, and it delivers nothing anywhere on its own. Firehose costs about as much again and writes the
lake, already partitioned and in Parquet, with no program of yours running. When the only consumer
would have been a program that copies the stream into S3, the delivery stream is that program,
already written, and a producer can put records into it directly, with no Kinesis stream at all.
