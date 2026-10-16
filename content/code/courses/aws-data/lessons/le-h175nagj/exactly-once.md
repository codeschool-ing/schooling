---
title: Ordering, duplicates and Kafka's exactly once
version: 1
---

**Ordering and duplicates are separate problems, and solving one does not solve the other.** A
consumer can see every record exactly once in the wrong order, or in the right order twice. The
tools are different too, and one of them is cheaper than the dedupe table, in the one case where it
applies.

## The sequence number as a watermark

**Within a shard, a replay re-reads records in the same order with the same sequence numbers.** So a
consumer that stores the highest sequence number it has applied, per shard, in the same write as the
effect, can skip any record at or below it. That is exactly a replay, and it costs one number per
shard rather than one item per event. It is the checkpoint moved into the sink. **It catches the
consumer's duplicates and not the producer's**, because a producer's retry is a new record with a
higher sequence number, as the second section showed with numbers 1 and 2. A stream with retrying
producers still needs the idempotency key; the watermark is the cheaper half for the other kind.

**And ordering needs its own field.** When the same order's events can arrive out of order, after a
retry or across a reshard, the event carries a version or a timestamp from the producer. The sink applies a write only if it is newer than what it holds: a conditional write on the version, the same
`ConditionExpression` mechanism as the dedupe, comparing a number instead of testing existence.

## Kafka's idempotent producer

**Kafka removes the producer's duplicates at the broker**, which Kinesis does not. With
`enable.idempotence=true`, the default since Kafka 3.0, each producer gets an id from the broker and
numbers every record it sends to each partition. When a retry arrives with a number the partition has
already written, the broker acknowledges it without writing it again, and a number out of sequence is
refused. So the case of the second section, a lost acknowledgement and a resend, writes the record
once. It covers one producer session and its retries; a producer that restarts and sends its
records again from its own source is a new session, and those are new records.

## Kafka's transactions

**A transaction makes the work and the checkpoint one atomic write, as long as both are in Kafka.**
A consumer that reads from one topic and writes to another can, with a `transactional.id`, write its
output records and commit its input offsets in a single transaction. Either the outputs and the new offsets become visible together, or neither does. Consumers downstream that read with
`isolation.level=read_committed` see only committed transactions. This is Kafka's exactly-once, and
Kafka Streams uses it with one setting.

**It stops at Kafka's edge.** The moment the work leaves Kafka, a row in DynamoDB, an object in S3,
a charge on a card, the external write is not in the transaction, and a crash between it and the
commit repeats it. That is the sentence of this lesson's first section again: exactly once is end to
end or nothing, and the end is wherever the effect lands. None of this was run, since one broker
running console tools cannot show it; the behaviour is from Kafka's documentation. What was run, the
replay of the last two sections, is what a pipeline does at that edge whichever stream it reads.

| duplicate from | caught by |
|---|---|
| a producer's retry, Kinesis | an idempotency key in the data |
| a producer's retry, Kafka | the idempotent producer, at the broker |
| a consumer's replay | an idempotency key, or a sequence-number watermark per shard |
| a Firehose or Lambda retry | an idempotent sink, or a dedupe when the lake is compacted |
| a read-process-write inside Kafka | Kafka transactions |
