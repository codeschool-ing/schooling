---
title: Iterators, and how long a shard remembers
version: 1
---

**Reading a record does not remove it.** A queue hands a message to one reader and forgets it; a
shard keeps every record for its **retention period** whoever has read it, and each reader keeps its
own position. That is what lets two programs read the same stream for different purposes, and what
lets one program read it again after a bug. The position is a **shard iterator**, and where it starts
is the first choice every consumer makes.

## Five places to start

`consumer.py` asked for `TRIM_HORIZON`. The command line can ask for the others. Each command below
takes an iterator on shard 0, which holds the five records of `c-17` and `c-03` from the last
section, and passes it straight to `get-records`. The first shows one record whole, the second
decodes its data, and from the third on each answer is just the sequence numbers that came back:

```
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text) && aws kinesis get-records --shard-iterator "$IT" --limit 1
{
    "Records": [
        {
            "SequenceNumber": "1",
            "ApproximateArrivalTimestamp": "2026-10-16T12:49:57.155000-03:00",
            "Data": "eyJvcmRlcl9pZCI6ICJvLTEwMSIsICJjdXN0b21lcl9pZCI6ICJjLTE3IiwgInN0YXR1cyI6ICJwbGFjZWQifQ==",
            "PartitionKey": "c-17"
        }
    ],
    "NextShardIterator": "b3JkZXJzOnNoYXJkSWQtMDAwMDAwMDAwMDAwOjE=\n",
    "MillisBehindLatest": 49
}
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text) && aws kinesis get-records --shard-iterator "$IT" --limit 1 --query 'Records[0].Data' --output text | base64 -d; echo
{"order_id": "o-101", "customer_id": "c-17", "status": "placed"}
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text) && aws kinesis get-records --shard-iterator "$IT" --query 'Records[].SequenceNumber' --output text
1	2	3	4	5
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type LATEST --query ShardIterator --output text) && aws kinesis get-records --shard-iterator "$IT" --query 'Records[].SequenceNumber' --output text
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type AT_SEQUENCE_NUMBER --starting-sequence-number 3 --query ShardIterator --output text) && aws kinesis get-records --shard-iterator "$IT" --query 'Records[].SequenceNumber' --output text
3	4	5
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type AFTER_SEQUENCE_NUMBER --starting-sequence-number 3 --query ShardIterator --output text) && aws kinesis get-records --shard-iterator "$IT" --query 'Records[].SequenceNumber' --output text
4	5
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type AT_TIMESTAMP --timestamp $(date -d '10 minutes ago' +%s) --query ShardIterator --output text) && aws kinesis get-records --shard-iterator "$IT" --query 'Records[].SequenceNumber' --output text
1	2	3	4	5
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type LATEST --query ShardIterator --output text) && aws kinesis put-record --stream-name orders --partition-key c-17 --cli-binary-format raw-in-base64-out --data '{"order_id": "o-105", "customer_id": "c-17", "status": "placed"}' --query SequenceNumber --output text && aws kinesis get-records --shard-iterator "$IT" --query 'Records[].SequenceNumber' --output text
6
6
```

| type | starts at | for |
|---|---|---|
| `TRIM_HORIZON` | the oldest record the shard still keeps | reading everything, or reprocessing |
| `LATEST` | just after the newest record | a consumer that cares only about what happens from now on |
| `AT_SEQUENCE_NUMBER` | that record | resuming at a record you have not finished |
| `AFTER_SEQUENCE_NUMBER` | the record after that one | resuming after the last record you finished |
| `AT_TIMESTAMP` | the first record that arrived at or after the time | "replay everything since 09:00" |

**`LATEST` answered nothing, and that is its meaning**: the iterator points after the newest record,
so it sees only what is written once it exists. The last command proves it: it took an iterator, wrote
a record, which `put-record` numbered 6, and the iterator returned exactly that record. A consumer that starts
with `LATEST` after a restart skips everything written while it was down, which is why a consumer
that must not lose records stores the last sequence number it finished and resumes with
`AFTER_SEQUENCE_NUMBER`. That stored position is a **checkpoint**, and lesson 23 shows what happens
when a consumer crashes between doing its work and writing one down.

The `Data` of a record is base64 when the command line prints it, which is why the second command
pipes it through `base64 -d`. And an iterator is short-lived: AWS documents that one
expires five minutes after it was issued if it is not used, and a consumer that sleeps longer than
that has to ask for a new one from its checkpoint. moto keeps iterators for as long as it runs, so
that expiry was not seen here.

## Retention

**A record stays in its shard for the retention period and is then deleted, read or not.** The
default is 24 hours. It can be raised to 7 days, 168 hours, and beyond that up to 365 days:

```
ana@laptop:~/aws$ aws kinesis increase-stream-retention-period --stream-name orders --retention-period-hours 168
ana@laptop:~/aws$ aws kinesis describe-stream-summary --stream-name orders --query StreamDescriptionSummary.RetentionPeriodHours
168
ana@laptop:~/aws$ aws kinesis increase-stream-retention-period --stream-name orders --retention-period-hours 9000

aws: [ERROR]: An error occurred (InvalidArgumentException) when calling the IncreaseStreamRetentionPeriod operation: Maximum allowed retention period is 8760 hours. Requested retention period (9000 hours) is too long.
ana@laptop:~/aws$ aws kinesis decrease-stream-retention-period --stream-name orders --retention-period-hours 12

aws: [ERROR]: An error occurred (InvalidArgumentException) when calling the DecreaseStreamRetentionPeriod operation: Minimum allowed retention period is 24 hours. Requested retention period (12 hours) is too short.
```

**8,760 hours is 365 days, and moto refused 9,000 with AWS's own limit in the message.** It also
refused to go below 24. What moto does not do is delete anything: its records stay until it stops,
whatever the retention says, so the deletion itself was not run here. On AWS, a record older than
the retention period is gone, and a consumer that falls further behind than that loses records with
no error at all. Its next `GetRecords` simply starts at the oldest record that is left, and
`TRIM_HORIZON` silently means a later point than it did yesterday.

**Retention is the size of your second chance.** At 24 hours, a bug found on Monday morning in a
consumer deployed on Friday cannot be fixed by reprocessing, because the records it mishandled no
longer exist. At 7 days it can. The last section of this lesson prices that difference, and
lesson 21 shows the usual answer for history older than any retention: a copy of the stream in S3.
