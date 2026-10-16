---
title: Ordered per shard, and only per shard
version: 1
---

**Kinesis keeps the order of records within a shard and promises nothing across shards.** A reader
who pictures the stream as one line of events, read back in the order they happened, will one day
process a delivery before the order it belongs to. What is ordered is each shard's log, and since a
partition key always lands on the same shard, what is ordered in practice is **each key's events**.
Two programs show it: one writes Quitanda's order events, one reads them back.

## A producer

Copy it into `~/aws/producer.py` with the button on the block:

```schooling-example
{"language": "python", "file": "producer.py", "parts": [{"code": "import json\nimport sys\n\nimport boto3\n\nkinesis = boto3.client('kinesis')\nstream = sys.argv[1]\n\n", "note": "The stream's name comes from the command line, so the same program feeds every stream in this lesson. `boto3` reads the endpoint, the keys and the region from the variables the terminal exported, exactly as `aws` does."}, {"code": "EVENTS = [\n    ('o-101', 'c-17', 'placed'), ('o-102', 'c-02', 'placed'),\n    ('o-101', 'c-17', 'packed'), ('o-103', 'c-05', 'placed'),\n    ('o-102', 'c-02', 'packed'), ('o-101', 'c-17', 'delivered'),\n    ('o-103', 'c-05', 'cancelled'), ('o-104', 'c-03', 'placed'),\n    ('o-102', 'c-02', 'delivered'), ('o-104', 'c-03', 'packed'),\n]\n\n", "note": "Ten events for four orders of four customers. An order is placed, packed and delivered, or cancelled, and the order of those events is what a reader must not get wrong."}, {"code": "for order, customer, status in EVENTS:\n    data = json.dumps({'order_id': order, 'customer_id': customer, 'status': status})\n    r = kinesis.put_record(StreamName=stream, PartitionKey=customer, Data=data.encode())\n    print(f\"{order} {status:<9} key {customer}  {r['ShardId']}  seq {r['SequenceNumber']}\")\n", "note": "**One `PutRecord` per event, keyed by the customer.** The data is bytes, here a line of JSON, and Kinesis never looks inside it. The answer names the shard the record went to and the sequence number it was given there."}]}
```

```
ana@laptop:~/aws$ python3 producer.py orders
o-101 placed    key c-17  shardId-000000000000  seq 1
o-102 placed    key c-02  shardId-000000000001  seq 1
o-101 packed    key c-17  shardId-000000000000  seq 2
o-103 placed    key c-05  shardId-000000000001  seq 2
o-102 packed    key c-02  shardId-000000000001  seq 3
o-101 delivered key c-17  shardId-000000000000  seq 3
o-103 cancelled key c-05  shardId-000000000001  seq 4
o-104 placed    key c-03  shardId-000000000000  seq 4
o-102 delivered key c-02  shardId-000000000001  seq 5
o-104 packed    key c-03  shardId-000000000000  seq 5
```

**Every record went where `shard_of.py` predicted**: `c-17` and `c-03` to shard 0, `c-02` and
`c-05` to shard 1. And each shard numbered its own records from 1, which is the first thing to
notice about a **sequence number**: it is a position in one shard, and two records in different
shards with the same number have nothing to do with each other.

**moto's sequence numbers are small integers, and AWS's are not.** On AWS a sequence number is a long
string of decimal digits, too large for a 64-bit integer, unique within the shard and increasing
over time. Code that stores one should keep it as a string, and code that compares two from the same
shard should compare them as numbers of arbitrary size, never as text: as text, `"9"` sorts after
`"10"`. A test against moto that passes with `int()` on small numbers tells you nothing about that.

## A consumer

Copy it into `~/aws/consumer.py`:

```schooling-example
{"language": "python", "file": "consumer.py", "parts": [{"code": "import json\nimport sys\n\nimport boto3\n\nkinesis = boto3.client('kinesis')\nstream = sys.argv[1]\n\n", "note": "The same start as the producer: one client, and the stream named on the command line."}, {"code": "for shard in kinesis.list_shards(StreamName=stream)['Shards']:\n    sid = shard['ShardId']\n    print(sid)\n", "note": "**A consumer reads shard by shard.** There is no call that reads \"the stream\": `ListShards` names the shards, and each one is read on its own, with its own iterator."}, {"code": "    it = kinesis.get_shard_iterator(StreamName=stream, ShardId=sid,\n                                    ShardIteratorType='TRIM_HORIZON')['ShardIterator']\n", "note": "An iterator is a position in one shard. `TRIM_HORIZON` is the oldest record the shard still keeps, so this reads everything."}, {"code": "    while it:\n        out = kinesis.get_records(ShardIterator=it, Limit=100)\n        for rec in out['Records']:\n            e = json.loads(rec['Data'])\n            print(f\"  seq {rec['SequenceNumber']:>2}  {e['order_id']} {e['status']:<9} {rec['PartitionKey']}\")\n        if not out['Records'] and out['MillisBehindLatest'] == 0:\n            break\n        it = out.get('NextShardIterator')\n", "note": "Each `GetRecords` returns a batch and the iterator for the next one. A real consumer loops for ever and sleeps when a batch is empty; this one stops when a batch is empty and `MillisBehindLatest` says it has reached the end of the shard, so that it can be run and read."}]}
```

```
ana@laptop:~/aws$ python3 consumer.py orders
shardId-000000000000
  seq  1  o-101 placed    c-17
  seq  2  o-101 packed    c-17
  seq  3  o-101 delivered c-17
  seq  4  o-104 placed    c-03
  seq  5  o-104 packed    c-03
shardId-000000000001
  seq  1  o-102 placed    c-02
  seq  2  o-103 placed    c-05
  seq  3  o-102 packed    c-02
  seq  4  o-103 cancelled c-05
  seq  5  o-102 delivered c-02
```

**Within each shard the order is exactly the order of writing.** On shard 0, `o-101` is placed,
packed and delivered, in that order, and `o-104` follows it. On shard 1, `o-102` and `o-103`
interleave just as they were written. Read one customer's events and they make sense.

**Across the shards the order is gone.** The producer wrote `o-102 placed` second, straight after
`o-101 placed`, and the consumer printed it sixth, after everything on shard 0, because it read the
shards one after another. A consumer that reads both shards at once, as a real one does with one
worker per shard, would interleave them some other way, different on every run. Nothing in the
records says what the global order was, apart from `ApproximateArrivalTimestamp`, which is the time
Kinesis received each record and is, as its name says, approximate. **If a question needs the order
of events across keys, the stream cannot answer it**; the events have to carry a timestamp of their
own, and the reader has to sort by it, knowing that some will arrive late.

## What ordering does not survive

Two things break even the order within a key, and both are the producer's doing. The first is
**a retry**: when a `PutRecord` times out, the producer cannot tell whether the record was written, so
it sends it again. The shard may now hold the same event twice, or an event and then an older
one that was retried after it. The second is **writing in parallel**: two threads putting records
for the same key race each other, and the shard keeps whichever arrived first. `PutRecord` accepts a
`SequenceNumberForOrdering`, the sequence number of the record before, to keep one producer's records
strictly in order; `PutRecords`, which writes up to 500 records in one call, makes no ordering promise
even within its own batch. Lesson 23 is about the duplicates and what a consumer does about them.
