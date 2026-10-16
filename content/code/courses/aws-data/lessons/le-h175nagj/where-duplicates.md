---
title: Where the duplicates come from
version: 1
---

**A duplicate is not a bug in the stream; it is what a correct retry produces.** Four places make
them in the pipelines of this course, and each one is doing the right thing when it does.

## The producer that retries

A producer sends `PutRecord` and waits for the answer. If the answer is lost, because the connection
dropped or the call timed out, the producer cannot tell a record that was never written from one that
was written and whose acknowledgement went missing. The only safe move is to send it again, and if
the first one had been written, the shard now holds it twice. The AWS SDKs retry on their own, so
this happens without a line of the producer's code asking for it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A producer and a shard over time. The producer sends PutRecord for o-301; the shard writes it as sequence number 1 and sends an acknowledgement, which is lost on the way back. The producer times out, cannot tell whether the record was written, and sends it again; the shard writes it as sequence number 2 and this acknowledgement arrives. The shard now holds o-301 twice, under two sequence numbers.\" data-fig=\"l23-retry\"><text x=\"160.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">producer</text><text x=\"560.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">shard</text><line x1=\"160.0\" y1=\"30.0\" x2=\"160.0\" y2=\"235.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><line x1=\"560.0\" y1=\"30.0\" x2=\"560.0\" y2=\"235.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><line x1=\"160.0\" y1=\"50.0\" x2=\"554.0\" y2=\"69.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></line><polygon points=\"560.0,70.0 554.2,66.7 553.9,72.7\" fill=\"var(--phosphor)\" stroke=\"none\"></polygon><text x=\"180.0\" y=\"48.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PutRecord o-301</text><rect x=\"570.0\" y=\"60.0\" width=\"130.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">written: seq 1</text><line x1=\"560.0\" y1=\"90.0\" x2=\"380.0\" y2=\"104.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><text x=\"380.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">acknowledgement lost</text><rect x=\"10.0\" y=\"120.0\" width=\"140.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"80.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">timeout: written or not?</text><line x1=\"160.0\" y1=\"160.0\" x2=\"554.0\" y2=\"179.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></line><polygon points=\"560.0,180.0 554.2,176.7 553.9,182.7\" fill=\"var(--phosphor)\" stroke=\"none\"></polygon><text x=\"180.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PutRecord o-301</text><text x=\"300.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the same record, again</text><rect x=\"570.0\" y=\"170.0\" width=\"130.0\" height=\"24.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">written: seq 2</text><line x1=\"560.0\" y1=\"200.0\" x2=\"166.0\" y2=\"219.7\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></line><polygon points=\"160.0,220.0 166.1,222.7 165.8,216.7\" fill=\"var(--phosphor)\" stroke=\"none\"></polygon><text x=\"190.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">acknowledged</text></svg>", "caption": "A lost acknowledgement and a correct retry: one payment, two records."}
```

moto never loses an answer, so the lab cannot make the timeout happen. It can show the result, which
is the same as sending one record twice:

```
ana@laptop:~/aws$ aws kinesis create-stream --stream-name orders --shard-count 1
ana@laptop:~/aws$ aws kinesis put-record --stream-name orders --partition-key c-17 --cli-binary-format raw-in-base64-out --data '{"order_id": "o-301", "cents": 4590}' --query SequenceNumber --output text
1
ana@laptop:~/aws$ aws kinesis put-record --stream-name orders --partition-key c-17 --cli-binary-format raw-in-base64-out --data '{"order_id": "o-301", "cents": 4590}' --query SequenceNumber --output text
2
ana@laptop:~/aws$ IT=$(aws kinesis get-shard-iterator --stream-name orders --shard-id shardId-000000000000 --shard-iterator-type TRIM_HORIZON --query ShardIterator --output text) && aws kinesis get-records --shard-iterator "$IT" --query 'Records[].[SequenceNumber,PartitionKey,Data]' --output text
1	c-17	eyJvcmRlcl9pZCI6ICJvLTMwMSIsICJjZW50cyI6IDQ1OTB9
2	c-17	eyJvcmRlcl9pZCI6ICJvLTMwMSIsICJjZW50cyI6IDQ1OTB9
```

**Two records, two sequence numbers, identical data.** Kinesis does not compare records and has no
way to know that the second is a copy: to the stream they are two events. That settles which kind
of key can catch this duplicate. A sequence number cannot, because the copy got a new one; only
something inside the data, put there by the producer, can. That is an **idempotency key**, and for a
payment it is the order id, because an order is paid once.

## The consumer that crashes

The consumer of the last section's at-least-once ordering processes a batch and then checkpoints.
If it dies between the two, the restart reads the batch again. With the Kinesis Client Library this
also happens without a crash, when a worker loses its lease on a shard to another worker during a
rebalance: the new owner starts from the last checkpoint, which is behind what the old owner had
done. Kafka's consumer groups do the same when a rebalance moves a partition before its offsets were
committed. **These duplicates keep their sequence numbers**, because they are the same records read
twice, which makes them easier to catch than the producer's.

## The service that retries for you

Data Firehose retries a delivery into S3 that did not confirm, and a retried delivery whose first
attempt had in fact succeeded writes the same records into the bucket twice; AWS documents this as
the at-least-once nature of the service. Lambda, reading a Kinesis stream through an event source
mapping, retries a batch whose invocation failed, whole, including the records the function had
already handled before it failed. Lesson 21's transformation Lambda is in the same position. None of
this was run here, because moto runs no Lambda and Firehose in moto writes once, immediately.

## Two that are not duplicates

**A second event that looks like the first is not a duplicate.** Two orders by `c-17` for the same
amount on the same day are two orders; a key built from customer, amount and day would merge them and
lose money in the other direction. The idempotency key has to identify the event, not describe it,
which is why it is an id the producer assigns once, when the event happens, and never derives later.

And **a record out of order is not a duplicate either**. Lesson 20 showed that a retry can put an
older event after a newer one; the dedupe below removes copies and does nothing about order. A
consumer that cares about both needs the idempotency key for the copies and a version or timestamp
in the data for the order, a point the last section of this lesson comes back to.
