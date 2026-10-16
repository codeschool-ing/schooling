---
title: Sinks that do not care how often they are written
version: 1
---

**The dedupe table of the last section is one answer; a sink that is idempotent by its nature is the
cheaper one.** A dedupe table remembers every event so that a write can be refused. An idempotent
sink needs no memory, because writing the same thing twice already lands in the same place with the
same result. The test of a sink is a single question: if this write is repeated, is the result
different? `ADD` to a total answers yes. Two others answer no, and they are the two this course uses
most.

## A key that names the content, not the moment

A consumer that writes batches to S3 needs a key for each object. The tempting key is the time of
writing; the idempotent one is a name derived from what the batch contains, such as the shard and
the first and last sequence numbers in it. One small batch, written twice under each kind of key:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod
make_bucket: quitanda-raw-prod
ana@laptop:~/aws$ printf '%s\n' '{"order_id": "o-301", "cents": 4590}' '{"order_id": "o-302", "cents": 12800}' > batch.json
ana@laptop:~/aws$ aws s3 cp batch.json s3://quitanda-raw-prod/raw/payments-by-time/$(date +%s%N).json
upload: ./batch.json to s3://quitanda-raw-prod/raw/payments-by-time/1792168816735151990.json
ana@laptop:~/aws$ aws s3 cp batch.json s3://quitanda-raw-prod/raw/payments-by-time/$(date +%s%N).json
upload: ./batch.json to s3://quitanda-raw-prod/raw/payments-by-time/1792168817394032117.json
ana@laptop:~/aws$ aws s3 cp batch.json s3://quitanda-raw-prod/raw/payments-by-seq/shardId-000000000000/1-2.json
upload: ./batch.json to s3://quitanda-raw-prod/raw/payments-by-seq/shardId-000000000000/1-2.json
ana@laptop:~/aws$ aws s3 cp batch.json s3://quitanda-raw-prod/raw/payments-by-seq/shardId-000000000000/1-2.json
upload: ./batch.json to s3://quitanda-raw-prod/raw/payments-by-seq/shardId-000000000000/1-2.json
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/raw/ --recursive
2026-10-16 13:40:19         75 raw/payments-by-seq/shardId-000000000000/1-2.json
2026-10-16 13:40:17         75 raw/payments-by-time/1792168816735151990.json
2026-10-16 13:40:18         75 raw/payments-by-time/1792168817394032117.json
```

**The time-named batch is now in the lake twice; the sequence-named one is there once.** The second
`cp` under `1-2.json` overwrote an identical object with identical bytes, which changes nothing, so
a consumer that crashed after writing the object and before its checkpoint can write it again on the
replay with no harm. Under the time-named keys, the same replay leaves two objects with the same two
payments, and every query of the lake counts both. Lesson 1's warning that an overwrite is silent and
final is, here, exactly the property wanted.

This works because a replay reads the **same** records in the same batches. A consumer whose batch
boundaries can move between runs, because it batches by time rather than by position, loses that, and
is back to needing a dedupe step; batching by sequence number keeps it. And Firehose, which names its
objects by time and a random suffix, cannot be made idempotent this way. A duplicate it writes is in the lake until a later job removes it, which is why lake tables built from Firehose deliveries are
deduplicated by the idempotency key when they are compacted into the curated layer.

## An upsert, not an increment

The other form is a write that sets a value instead of changing it:

```
ana@laptop:~/aws$ aws dynamodb update-item --table-name quitanda-totals --key '{"customer_id": {"S": "c-08"}}' --update-expression 'ADD cents :c' --expression-attribute-values '{":c": {"N": "500"}}' --return-values UPDATED_NEW --query Attributes.cents.N --output text
500
ana@laptop:~/aws$ aws dynamodb update-item --table-name quitanda-totals --key '{"customer_id": {"S": "c-08"}}' --update-expression 'ADD cents :c' --expression-attribute-values '{":c": {"N": "500"}}' --return-values UPDATED_NEW --query Attributes.cents.N --output text
1000
ana@laptop:~/aws$ aws dynamodb put-item --table-name quitanda-totals --item '{"customer_id": {"S": "c-09"}, "cents": {"N": "500"}}'
ana@laptop:~/aws$ aws dynamodb put-item --table-name quitanda-totals --item '{"customer_id": {"S": "c-09"}, "cents": {"N": "500"}}'
ana@laptop:~/aws$ aws dynamodb get-item --table-name quitanda-totals --key '{"customer_id": {"S": "c-09"}}' --query Item.cents.N --output text
500
```

**`ADD` twice made 1,000 out of 500; `put-item` twice left 500.** A `put-item` replaces the whole item
with the one given, so repeating it is harmless, and the same is true of SQL's
`INSERT ... ON CONFLICT DO UPDATE` and of `MERGE`, which `sql-databases` covers. The catch is that an
upsert has to carry the **whole state**, the total itself rather than the amount to add to it, and
the consumer has to know that state. That suits a stream of snapshots, such as "customer `c-09`'s
balance is now 500", and does not suit a stream of changes, such as "add 500", which is what
payments are. A stream of changes into a non-idempotent sink is the case that needs the dedupe of
the last section.

**Design the events to make the sink easy.** If a producer can send the new state rather than the
difference, every consumer downstream can upsert and forget about duplicates. When the event has to
be a difference, it carries an id, and the sink either records the id with the effect, as `totals.py`
does, or is rebuilt from the deduplicated history later.
