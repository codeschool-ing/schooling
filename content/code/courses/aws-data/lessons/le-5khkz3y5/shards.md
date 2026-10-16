---
title: A stream is a set of shards
version: 1
---

**A Kinesis data stream is not one queue.** It is a fixed number of **shards**, and each shard is an
ordered log of its own: records are appended at its end and read from any point in it. A record
written to the stream goes into exactly one shard, and which one is decided by arithmetic on a
string the producer supplies, the **partition key**. Everything else in this lesson, the ordering,
the limits and the price, is a property of the shard and not of the stream, so the shard is where
to start.

The terminal is the one from lesson 1: moto running in its own terminal and the four lines of
lesson 1's "Your lab, in brief" typed in this one. moto starts empty, and this lesson builds its
streams from nothing. A stream with two shards for Quitanda's order events:

```
ana@laptop:~/aws$ aws kinesis create-stream --stream-name orders --shard-count 2
ana@laptop:~/aws$ aws kinesis describe-stream-summary --stream-name orders --query 'StreamDescriptionSummary.[StreamStatus,OpenShardCount,RetentionPeriodHours]' --output text
ACTIVE	2	24
ana@laptop:~/aws$ aws kinesis list-shards --stream-name orders --query 'Shards[].[ShardId,HashKeyRange.StartingHashKey,HashKeyRange.EndingHashKey]' --output text
shardId-000000000000	0	170141183460469231731687303715884105727
shardId-000000000001	170141183460469231731687303715884105728	340282366920938463463374607431768211455
```

**The two shards split one number line between them.** Kinesis takes the partition key, computes
its MD5, and reads the 16 bytes of the digest as one unsigned integer, a number from 0 to 2^128 − 1.
That range is the stream's **hash key space**, and every shard owns a contiguous piece of it. Shard
`0` owns everything below 2^127, which is `170141183460469231731687303715884105728`, and shard `1`
owns 2^127 and everything above it. moto split the space exactly in half, which is also what AWS does
when a stream is created with a shard count.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"The hash key space of the stream orders, a line from 0 to 2^128 minus 1, split at 2^127 into two shards. Shard 0 owns the lower half and shard 1 the upper half. The MD5 of four partition keys is marked on the line: c-03 and c-17 fall in the lower half, in shard 0; c-02 and c-05 fall in the upper half, in shard 1.\" data-fig=\"l20-hashspace\"><text x=\"20.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">MD5 of the partition key</text><rect x=\"60.0\" y=\"80.0\" width=\"300.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"360.0\" y=\"80.0\" width=\"300.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shardId-000000000000</text><text x=\"510.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shardId-000000000001</text><line x1=\"215.8\" y1=\"48.0\" x2=\"215.8\" y2=\"73.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"215.8,79.0 218.8,73.0 212.8,73.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"215.8\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-03</text><line x1=\"317.6\" y1=\"48.0\" x2=\"317.6\" y2=\"73.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"317.6,79.0 320.6,73.0 314.6,73.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"317.6\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-17</text><line x1=\"508.4\" y1=\"48.0\" x2=\"508.4\" y2=\"73.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"508.4,79.0 511.4,73.0 505.4,73.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"508.4\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-02</text><line x1=\"645.7\" y1=\"48.0\" x2=\"645.7\" y2=\"73.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><polygon points=\"645.7,79.0 648.7,73.0 642.7,73.0\" fill=\"var(--amber)\" stroke=\"none\"></polygon><text x=\"649.7\" y=\"38.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-05</text><line x1=\"60.0\" y1=\"120.0\" x2=\"60.0\" y2=\"132.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"60.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><line x1=\"360.0\" y1=\"120.0\" x2=\"360.0\" y2=\"132.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"360.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2^127</text><line x1=\"660.0\" y1=\"120.0\" x2=\"660.0\" y2=\"132.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"660.0\" y=\"144.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2^128 - 1</text><text x=\"210.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shard 0: the lower half</text><text x=\"510.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">shard 1: the upper half</text></svg>", "caption": "A partition key's MD5 is a point on one line, and the shard is whichever range the point falls in."}
```

## Predicting the shard

Because the rule is MD5 and a range, you can work out where a key will land before writing
anything. The program below reads the stream's open shards and does the arithmetic for each key on
its command line. Save it as `~/aws/shard_of.py`, the same way you saved `prices.py` in lesson 1.
`boto3`, the AWS library for Python, came with moto:

`shard_of.py`:

```python
import hashlib
import sys

import boto3

shards = boto3.client('kinesis').list_shards(StreamName=sys.argv[1])['Shards']
for key in sys.argv[2:]:
    h = int(hashlib.md5(key.encode()).hexdigest(), 16)
    for s in shards:
        r, open_ = s['HashKeyRange'], 'EndingSequenceNumber' not in s['SequenceNumberRange']
        if open_ and int(r['StartingHashKey']) <= h <= int(r['EndingHashKey']):
            print(f'{key:<6} {h:>40}  {s["ShardId"]}')
```

```
ana@laptop:~/aws$ python3 shard_of.py orders c-17 c-03 c-02 c-05
c-17    146071825190439638704466073634825402563  shardId-000000000000
c-03     88352402212612476087593936981806328046  shardId-000000000000
c-02    254303140926280561521588452831818067638  shardId-000000000001
c-05    332192223557910061300396319758440839601  shardId-000000000001
```

**`c-17` and `c-03` go to shard 0, and `c-02` and `c-05` to shard 1**, and the next section writes
real records under those keys and finds them where the arithmetic said. The `open_` test matters
after a stream is resharded, later in this lesson: a shard that has been closed still lists its old
range, and nothing new goes into it.

## What the partition key decides

**The key decides two things at once, and they pull in opposite directions.** Every record with the
same key goes to the same shard, so the key is the unit of ordering: Quitanda keys its order events by
customer, so one customer's events are read back in the order they were written. And the key is the
unit of spread: the shards share the load only as evenly as the keys share the hash space.

A key with many values spreads well. Customer ids number in the tens of thousands, and their digests
are scattered across the line. A key with few values does not: keyed by store, with Quitanda's three
stores in São Paulo, the stream has three hash values in total, and however many shards it has, at
most three of them receive anything. A key with one value, such as the constant `orders`, puts the
whole stream on one shard and makes the others decoration. **Choose the key as the smallest thing
whose events must stay in order**, never as the largest.

A producer can also bypass the hash and name a point on the line directly, with `ExplicitHashKey`
in `PutRecord`. It is the tool for spreading a known set of keys by hand, and it is rarely needed;
the default arithmetic is what the rest of this course relies on.
