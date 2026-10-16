---
title: What a shard can take, and changing the number of shards
version: 1
---

**A shard is a unit of capacity as well as a unit of order.** AWS documents what one shard accepts
and serves, and a provisioned stream's capacity is that figure times the number of shards:

| per shard | limit |
|---|---|
| writes | 1 MB per second, or 1,000 records per second, whichever comes first |
| reads, shared by every ordinary consumer | 2 MB per second, and 5 `GetRecords` calls per second |
| reads, with enhanced fan-out | 2 MB per second for each registered consumer, pushed to it |

A write beyond the limit is refused with `ProvisionedThroughputExceededException`, and the producer
is expected to wait and retry. **The limit is per shard, not per stream**, and that brings back the
partition key of the first section. A stream of ten shards whose busiest key puts 1.5 MB
per second on one of them is throttled on that shard while the other nine are idle. That is a **hot
shard**, and adding shards does not cure it, because the key still hashes to one place.

## moto never throttles

This is the clearest case in the lesson of moto answering a question AWS would answer differently.
A stream with one shard, and 2,000 records written as fast as one loop can send them:

```
ana@laptop:~/aws$ aws kinesis create-stream --stream-name orders-test --shard-count 1
ana@laptop:~/aws$ python3 -c "import boto3, time; k = boto3.client('kinesis'); t = time.time(); f = sum(k.put_records(StreamName='orders-test', Records=[{'PartitionKey': f'c-{i}', 'Data': b'x' * 900} for i in range(500)])['FailedRecordCount'] for _ in range(4)); print(f, 'failed of 2000 in', round(time.time() - t, 2), 's')"
0 failed of 2000 in 0.16 s
```

**Nothing failed, in well under a second**, where a single shard on AWS accepts 1,000 records a
second and would have refused part of that. moto checks the shape of a request and keeps the records
in order; it has no clock for capacity. So nothing in this course shows a throttle happening, and a
producer that works against moto has not been tested against the limit at all. The retry it needs
is the subject of lesson 23.

## Resharding

**The number of shards can change while the stream is in use, and the old shards are closed rather
than resized.** `update-shard-count` asks Kinesis to do the arithmetic; here it doubles the stream of
the earlier sections from two shards to four:

```
ana@laptop:~/aws$ aws kinesis update-shard-count --stream-name orders --target-shard-count 4 --scaling-type UNIFORM_SCALING
{
    "StreamName": "orders",
    "CurrentShardCount": 2,
    "TargetShardCount": 4
}
ana@laptop:~/aws$ aws kinesis list-shards --stream-name orders --query 'Shards[].[ShardId,ParentShardId,HashKeyRange.StartingHashKey,SequenceNumberRange.EndingSequenceNumber]' --output text
shardId-000000000000	None	0	6
shardId-000000000001	None	170141183460469231731687303715884105728	5
shardId-000000000002	shardId-000000000000	0	None
shardId-000000000003	shardId-000000000000	85070591730234615865843651857942052864	None
shardId-000000000004	shardId-000000000001	170141183460469231731687303715884105728	None
shardId-000000000005	shardId-000000000001	255211775190703847597530955573826158592	None
ana@laptop:~/aws$ python3 shard_of.py orders c-17 c-03 c-02 c-05
c-17    146071825190439638704466073634825402563  shardId-000000000003
c-03     88352402212612476087593936981806328046  shardId-000000000003
c-02    254303140926280561521588452831818067638  shardId-000000000004
c-05    332192223557910061300396319758440839601  shardId-000000000005
```

**Six shards are listed, and only four are open.** Shards 0 and 1 now have an
`EndingSequenceNumber`: they are **closed**, they accept no writes, and they keep their records until
the retention period removes them. Each was split in two: shards 2 and 3 name shard 0 as their parent
and divide its half of the hash space between them, and shards 4 and 5 do the same for shard 1. The
last command is `shard_of.py` again, which skips the closed shards and finds the keys' new homes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The shards of the stream orders after update-shard-count from 2 to 4. On the top row, the two closed parents: shard 0, from 0 to 2^127, whose last sequence number is 6, and shard 1, from 2^127 to 2^128, whose last is 5. On the bottom row, four open children, each a quarter of the hash key space: shards 2 and 3 split shard 0, shards 4 and 5 split shard 1. The key c-17 sits in shard 0 before the reshard and in shard 3 after it, so its events are read from the parent first and the child second.\" data-fig=\"l20-lineage\"><text x=\"20.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">closed</text><text x=\"20.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no new writes</text><text x=\"20.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">open</text><text x=\"20.0\" y=\"188.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">writes go here</text><rect x=\"112.0\" y=\"50.0\" width=\"286.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"255.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shard 0</text><text x=\"255.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">last sequence number 6</text><rect x=\"402.0\" y=\"50.0\" width=\"286.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"545.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shard 1</text><text x=\"545.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">last sequence number 5</text><rect x=\"112.0\" y=\"160.0\" width=\"141.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"182.5\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shard 2</text><line x1=\"255.0\" y1=\"90.0\" x2=\"182.5\" y2=\"160.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"257.0\" y=\"160.0\" width=\"141.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"327.5\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shard 3</text><line x1=\"255.0\" y1=\"90.0\" x2=\"327.5\" y2=\"160.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"402.0\" y=\"160.0\" width=\"141.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"472.5\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shard 4</text><line x1=\"545.0\" y1=\"90.0\" x2=\"472.5\" y2=\"160.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"547.0\" y=\"160.0\" width=\"141.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"617.5\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">shard 5</text><line x1=\"545.0\" y1=\"90.0\" x2=\"617.5\" y2=\"160.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"110.0\" y1=\"202.0\" x2=\"110.0\" y2=\"212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"110.0\" y=\"224.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><line x1=\"255.0\" y1=\"202.0\" x2=\"255.0\" y2=\"212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"255.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2^126</text><line x1=\"400.0\" y1=\"202.0\" x2=\"400.0\" y2=\"212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"400.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2^127</text><line x1=\"545.0\" y1=\"202.0\" x2=\"545.0\" y2=\"212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"545.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 x 2^126</text><line x1=\"690.0\" y1=\"202.0\" x2=\"690.0\" y2=\"212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"690.0\" y=\"224.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2^128</text><circle cx=\"359.0\" cy=\"84.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><circle cx=\"359.0\" cy=\"166.0\" r=\"3.5\" fill=\"var(--amber)\" stroke=\"none\"></circle><line x1=\"359.0\" y1=\"88.0\" x2=\"359.0\" y2=\"162.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"2 2\"></line><text x=\"367.0\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">c-17</text><text x=\"400.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">read each parent to its end before its children</text></svg>", "caption": "Resharding closes the parents and opens children over the same ranges; a key's history runs from parent to child."}
```

**A consumer must finish a parent before it reads its children**, or the order of a key breaks at
the moment of resharding. The last events of `c-17` before the split are in shard 0, the first ones
after it are in shard 3, and reading shard 3 first puts them backwards. The Kinesis Client Library,
AWS's library for consumers, follows `ParentShardId` and does this for you; `consumer.py` happens to
get it right only because `ListShards` returned the parents first and it reads one shard at a time.

`update-shard-count` is the convenient form. Underneath it are two operations that can be called
directly, on any shard, with any split point:

```
ana@laptop:~/aws$ aws kinesis split-shard --stream-name orders-test --shard-to-split shardId-000000000000 --new-starting-hash-key 170141183460469231731687303715884105728
ana@laptop:~/aws$ aws kinesis list-shards --stream-name orders-test --query 'Shards[].[ShardId,ParentShardId,SequenceNumberRange.EndingSequenceNumber]' --output text
shardId-000000000000	None	2000
shardId-000000000001	shardId-000000000000	None
shardId-000000000002	shardId-000000000000	None
ana@laptop:~/aws$ aws kinesis merge-shards --stream-name orders-test --shard-to-merge shardId-000000000001 --adjacent-shard-to-merge shardId-000000000002
ana@laptop:~/aws$ aws kinesis list-shards --stream-name orders-test --query 'Shards[].[ShardId,ParentShardId,AdjacentParentShardId,SequenceNumberRange.EndingSequenceNumber]' --output text
shardId-000000000000	None	None	2000
shardId-000000000001	shardId-000000000000	None	0
shardId-000000000002	shardId-000000000000	None	0
shardId-000000000003	shardId-000000000001	shardId-000000000002	None
```

**`split-shard` closed shard 0 and made two children at the hash key given**, and `merge-shards`
closed those two and made one child with both parents, `ParentShardId` and `AdjacentParentShardId`.
Merging takes two shards whose ranges touch; splitting takes any point inside a shard's range. On
AWS each of these takes some seconds, during which the stream reports `UPDATING`. AWS also documents
limits on how often a stream may be rescaled and by how much at once; moto applied both on the same
line, so neither was seen here. On-demand streams, in the next section, do this splitting and merging
on their own.
