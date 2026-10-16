---
title: A stream of the table's changes
version: 1
---

**A DynamoDB stream is the table's changes, item by item and in the order they happened, kept for 24
hours.** It is not a copy of the table, and it is not a queue that keeps what nobody read. Each write
that changes an item adds one record: what kind of change it was, the item's key, and, depending on
the stream's view type, the item before and after. Something outside the table reads those records and
acts on them: keeps a total, feeds a search index, sends the warehouse of lessons 14 to 19 its new
rows. That is change-driven processing, and the table does not need to know who is listening.

**A stream is switched on for a table, and starts empty.** Changes made before it existed are not in
it. This lesson rebuilds lesson 9's table: moto running in its own terminal, the four lines of lesson
1's "Your lab, in brief" typed in this one, and the first command of lesson 9's "The partition key and
the sort key". Then the stream, before any item is written:

```sh
aws dynamodb update-table --table-name quitanda \
  --stream-specification StreamEnabled=true,StreamViewType=NEW_AND_OLD_IMAGES > /dev/null
```

```
ana@laptop:~/aws$ aws dynamodb describe-table --table-name quitanda --query 'Table.[StreamSpecification,LatestStreamLabel]'
[
    {
        "StreamEnabled": true,
        "StreamViewType": "NEW_AND_OLD_IMAGES"
    },
    "2026-10-16T16:28:10.507132"
]
ana@laptop:~/aws$ aws dynamodbstreams describe-stream --stream-arn "$ARN" --query "StreamDescription.[StreamStatus,StreamViewType,length(Shards),Shards[0].ShardId]"
[
    "ENABLED",
    "NEW_AND_OLD_IMAGES",
    1,
    "shardId-00000001541626099285-f35f62ef"
]
```

**The stream has a label, the time it was created, and one shard.** A shard is a piece of the stream,
read on its own. On AWS the shards follow the table's partitions, and DynamoDB opens and closes them on its own. When a shard is closed, its items' later records continue in a child shard, which a reader
must not start until it has finished the parent. moto keeps a single shard
for the whole stream and never closes it, and none of that was run here. Two variables keep the
commands short from here on:

```sh
ARN=$(aws dynamodb describe-table --table-name quitanda --query Table.LatestStreamArn --output text)
SHARD=$(aws dynamodbstreams describe-stream --stream-arn "$ARN" \
  --query 'StreamDescription.Shards[0].ShardId' --output text)
```

## Records, in the order of the writes

Lesson 9's `seed.py`, saved in `~/aws`, writes the thirty items; the stream records each one. A
**shard iterator** is a position in a shard, and `TRIM_HORIZON` asks for the oldest record still kept:

```
ana@laptop:~/aws$ python3 seed.py
3 customers: 3 profiles, 9 orders, 18 order lines, 30 items
ana@laptop:~/aws$ aws dynamodbstreams get-records --shard-iterator "$(aws dynamodbstreams get-shard-iterator --stream-arn "$ARN" --shard-id "$SHARD" --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text)" --query 'Records[:4].[eventName,dynamodb.SequenceNumber,dynamodb.Keys.sk.S]' --output text
INSERT	1100000000017454423009	PROFILE
INSERT	1100000000017454423010	ORDER#2026-10-03#o-10001#LINE#1
INSERT	1100000000017454423011	ORDER#2026-10-03#o-10001#LINE#2
INSERT	1100000000017454423012	ORDER#2026-10-03#o-10001#LINE#3
```

**Every record is an `INSERT`, with a sequence number that only grows.** They come in the order the
items were written, and that is the seed's order: c-17's profile first, then the three lines of its
first order, then the order itself. Now three changes to c-17: a third line on the order of 12 October
with its total raised to match, and the order of 3 October deleted with its three lines.

```sh
aws dynamodb put-item --table-name quitanda --item '{"pk": {"S": "CUSTOMER#c-17"},
  "sk": {"S": "ORDER#2026-10-12#o-10003#LINE#3"}, "product": {"S": "eggs-12"},
  "qty": {"N": "1"}, "price_cents": {"N": "1590"}}'
aws dynamodb update-item --table-name quitanda \
  --key '{"pk": {"S": "CUSTOMER#c-17"}, "sk": {"S": "ORDER#2026-10-12#o-10003"}}' \
  --update-expression 'SET total_cents = total_cents + :p, line_count = line_count + :one' \
  --expression-attribute-values '{":p": {"N": "1590"}, ":one": {"N": "1"}}' > /dev/null
for sk in ORDER#2026-10-03#o-10001 ORDER#2026-10-03#o-10001#LINE#{1,2,3}; do
  aws dynamodb delete-item --table-name quitanda \
    --key "{\"pk\": {\"S\": \"CUSTOMER#c-17\"}, \"sk\": {\"S\": \"$sk\"}}"
done
```

```
ana@laptop:~/aws$ aws dynamodbstreams get-records --shard-iterator "$(aws dynamodbstreams get-shard-iterator --stream-arn "$ARN" --shard-id "$SHARD" --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text)" --query 'Records[30:].[eventName,dynamodb.SequenceNumber,dynamodb.Keys.sk.S]' --output text
INSERT	1100000000017454423039	ORDER#2026-10-12#o-10003#LINE#3
MODIFY	1100000000017454423040	ORDER#2026-10-12#o-10003
REMOVE	1100000000017454423041	ORDER#2026-10-03#o-10001
REMOVE	1100000000017454423042	ORDER#2026-10-03#o-10001#LINE#1
REMOVE	1100000000017454423043	ORDER#2026-10-03#o-10001#LINE#2
REMOVE	1100000000017454423044	ORDER#2026-10-03#o-10001#LINE#3
```

**Six writes, six records, each of the right kind.** The put of a new line is an `INSERT`, the update
of the order's total a `MODIFY`, and the four deletes four `REMOVE`s. **The order is guaranteed for
each item and not across the table**: two changes to `ORDER#2026-10-12#o-10003` always reach a reader
in the order they were made, because one item's records are always in one shard.
Records of two items in two shards may be read in either order. One shard in moto makes everything look ordered; a
reader that relies on it works here and not on AWS.

**24 hours, then gone.** AWS removes a record a day after it was written, read or not, and a reader
that falls more than a day behind loses changes for good. moto keeps every record until it stops, which
is a different way of losing them all.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Two shards over time. Shard 1 holds INSERT then MODIFY for order o-10003, and is closed; its child shard continues with the REMOVE of o-10003, so that item&#x27;s three records stay in order, parent before child. Shard 2 holds INSERT and MODIFY of o-10007 and INSERT of o-10008, interleaved in time with shard 1, with no order between the two shards. Every record is kept 24 hours.\" data-fig=\"l12-shards\"><defs><marker id=\"l12-shards-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><text x=\"20\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shard 1, closed</text><line x1=\"140\" y1=\"64\" x2=\"700\" y2=\"64\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"/><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">its child</text><line x1=\"140\" y1=\"124\" x2=\"700\" y2=\"124\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"/><text x=\"20\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shard 2</text><line x1=\"140\" y1=\"184\" x2=\"700\" y2=\"184\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"2 4\"/><rect x=\"150\" y=\"50\" width=\"110\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"/><text x=\"205\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">INSERT</text><text x=\"205\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">o-10003</text><rect x=\"330\" y=\"50\" width=\"110\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"/><text x=\"385\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">MODIFY</text><text x=\"385\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">o-10003</text><line x1=\"470\" y1=\"44\" x2=\"470\" y2=\"84\" stroke=\"var(--paper-dim)\" stroke-width=\"2\"/><rect x=\"560\" y=\"110\" width=\"110\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"/><text x=\"615\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">REMOVE</text><text x=\"615\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">o-10003</text><rect x=\"240\" y=\"170\" width=\"110\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"/><text x=\"295\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">INSERT</text><text x=\"295\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">o-10007</text><rect x=\"420\" y=\"170\" width=\"110\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"/><text x=\"475\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">MODIFY</text><text x=\"475\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">o-10007</text><rect x=\"580\" y=\"170\" width=\"110\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\"/><text x=\"635\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">INSERT</text><text x=\"635\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">o-10008</text><path d=\"M260,64 L328,64\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#l12-shards-ah)\"/><path d=\"M440,64 C500,64 500,124 558,124\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#l12-shards-ah)\"/><text x=\"330\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">one item: always in this order</text><text x=\"450\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">two shards: either order</text><line x1=\"140\" y1=\"225\" x2=\"700\" y2=\"225\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l12-shards-ah)\"/><text x=\"140\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text><text x=\"700\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kept 24 hours, then gone</text></svg>", "caption": "Drawn for illustration: moto keeps one shard that never closes. Order holds within an item, whose records follow it from a parent shard to its child; between shards it does not."}
```
