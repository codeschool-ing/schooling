---
title: Exactly-once delivery, and what it covers
version: 1
---

**Pub/Sub has a setting called exactly-once delivery, and it is narrower than its name.** `gcloud`'s
help for `--enable-exactly-once-delivery` says what it promises, for a given message id on that
subscription: the message is not sent again before its acknowledgement deadline expires, and an
acknowledged message is not sent again. Both are promises about **the redelivery of one message id**.
Neither covers the publisher's copies, which have ids of their own, and neither covers what the
consumer's work did before it acked.

## Two subscriptions side by side

One topic, an ordinary subscription and one with the setting, and one receipt published to both:

```
ana@laptop:~/gcp$ gcloud pubsub topics create receipts
Created topic [projects/planner-dev/topics/receipts].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create receipts-plain --topic=receipts
Created subscription [projects/planner-dev/subscriptions/receipts-plain].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create receipts-once --topic=receipts --enable-exactly-once-delivery
Created subscription [projects/planner-dev/subscriptions/receipts-once].
ana@laptop:~/gcp$ gcloud pubsub subscriptions describe receipts-once --format='value(enableExactlyOnceDelivery)'
True
ana@laptop:~/gcp$ gcloud pubsub topics publish receipts --message='{"order_id": "o-307", "cents": 3100}'
messageIds:
- '10'
```

The check, saved as `~/gcp/eo_check.py`, holds a message past its deadline, as a slow consumer does,
and then acks with the ack id it was first given:

```schooling-example
{"language": "python", "file": "eo_check.py", "parts": [{"code": "import sys\nimport time\n\nfrom google.api_core.exceptions import InvalidArgument\nfrom google.cloud import pubsub_v1\n\nsubscriber = pubsub_v1.SubscriberClient()\npath = subscriber.subscription_path('planner-dev', sys.argv[1])\n\n\ndef pull():\n    return subscriber.pull(subscription=path, max_messages=1, timeout=5).received_messages\n\n\n", "note": "The same check against whichever subscription is named, so that the two kinds can be compared line by line."}, {"code": "first = pull()[0]\nprint(f'pulled id {first.message.message_id}, not acked; waiting 12 s')\ntime.sleep(12)\nsecond = pull()[0]\nprint(f'pulled id {second.message.message_id} again, with a new ack id')\n", "note": "**A consumer that is too slow**: it holds a message past the 10-second deadline, so the message is delivered again, under a new ack id."}, {"code": "try:\n    subscriber.acknowledge(subscription=path, ack_ids=[first.ack_id])\n    print('ack with the first, expired ack id: accepted')\nexcept InvalidArgument as e:\n    print(f'ack with the first, expired ack id: refused, {e.reason}')\n", "note": "Then it finishes its work and acks with the ack id it was first given, which has expired. **This is the line where the two kinds of subscription part.**"}, {"code": "subscriber.acknowledge(subscription=path, ack_ids=[second.ack_id])\nprint('ack with the second: accepted')\ntime.sleep(12)\nprint(f'after another 12 s: {len(pull())} message(s)')\n", "note": "The ack with the current ack id, and a last pull after the deadline to see whether the message is still there."}]}
```

```
ana@laptop:~/gcp$ python3 eo_check.py receipts-plain
pulled id 10, not acked; waiting 12 s
pulled id 10 again, with a new ack id
ack with the first, expired ack id: accepted
ack with the second: accepted
after another 12 s: 0 message(s)
ana@laptop:~/gcp$ python3 eo_check.py receipts-once
pulled id 10, not acked; waiting 12 s
pulled id 10 again, with a new ack id
ack with the first, expired ack id: refused, EXACTLY_ONCE_ACKID_FAILURE
ack with the second: accepted
after another 12 s: 0 message(s)
```

**The two subscriptions behaved the same in every line but one.** Both redelivered message 10 once
its deadline ran out: exactly-once delivery does not stop a redelivery after the deadline, it only
promises none before it. The difference is the ack with the expired id. The ordinary subscription
accepted it and said nothing, so a consumer cannot tell an ack that worked from one that did nothing.
The exactly-once subscription **refused it, with the reason `EXACTLY_ONCE_ACKID_FAILURE`**, which is
the service's own error, and the emulator reproduces it. That refusal is what the guarantee rests on:
a consumer that gets a successful answer to its ack knows the message will not come back, and one that
gets a failure knows its work may be repeated by whoever holds the newer delivery.

**In the streaming client the answer comes from `message.ack_with_response()`**, which returns a
future. The library's documentation says that on an exactly-once subscription the future succeeding
means the message is guaranteed not to be delivered again, and failing means it may be; on an
ordinary subscription it succeeds at once whatever happened, because the ack is best effort. A
consumer that wants the guarantee waits on that future before it treats the message as finished.

## What it does not remove

The publisher's retry of the second section, on the exactly-once subscription:

```
ana@laptop:~/gcp$ gcloud pubsub topics publish receipts --message='{"order_id": "o-308", "cents": 2750}' && gcloud pubsub topics publish receipts --message='{"order_id": "o-308", "cents": 2750}'
messageIds:
- '11'
messageIds:
- '12'
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull receipts-once --auto-ack --limit=10 --format='table(message.messageId:label=ID,message.data.decode(base64).decode(utf-8):label=DATA)'
ID  DATA
11  {"order_id": "o-308", "cents": 2750}
12  {"order_id": "o-308", "cents": 2750}
```

**Two message ids, one payment, both delivered.** Exactly-once delivery is about one id at a time, and
these are two. The idempotency key in the data is still the only thing that catches them, which is the
order-id dedupe of the replay section.

Four more limits are from Google's documentation of the feature, cloud.google.com/pubsub/docs/exactly-once-delivery,
and none of them can be seen on the emulator:

- **Pull only.** Push subscriptions and the BigQuery and Cloud Storage subscriptions of lesson 19 do
  not offer it.
- **Within one region.** The guarantee holds for consumers that connect to the same region; a
  consumer in another region gets the ordinary behaviour.
- **Slower.** Every ack becomes a round trip whose answer the consumer waits for, and Google documents
  a higher publish-to-subscribe latency on such subscriptions.
- **Nothing beyond the ack.** A consumer that adds a payment, then fails to ack, adds it again when the
  redelivery comes, exactly as `totals.py` did in `plain` mode. The guarantee is about Pub/Sub's side of
  the handshake, and the effect is still the consumer's.

## Ordering and duplicates are two problems

**A consumer can see every message once in the wrong order, or in the right order twice**, and
solving one does nothing for the other. The tools are different too:

| the problem | what answers it |
|---|---|
| a publisher's retry: two ids, one event | an idempotency key in the data, recorded with the effect |
| a redelivery: one id, delivered twice | the same key, or exactly-once delivery with acks that are waited on |
| a replay with seek | the same key, or an idempotent sink |
| a status that must not go backwards | a version or timestamp in the event, and a write that applies only if newer |
| a key's order after a failure | an ordering key, with the duplicates its redelivery brings |

**The last two rows need a field the publisher writes.** When the same order's events can arrive out of
order, the event carries a version or a time from the moment it happened, and the sink applies a write
only if it is newer than what it holds: in SQL, an `UPDATE ... WHERE version < ?`; in Firestore, a
transaction that reads the version first. That is the same idea as the dedupe, comparing a number
instead of testing existence.

**Exactly once is end to end or nothing, and the end is wherever the effect lands.** Dataflow, in
lesson 21, reads Pub/Sub and offers exactly-once processing inside the pipeline, by recording what it
has applied in its own durable state; lesson 21 says what that covers and where its edge is. Past the
edge, a row in a database, an object in a bucket, a charge on a card, the sink has to be idempotent or
keyed as this lesson's was. What ran here, the crash and the replay, is what every pipeline does at that
edge, whichever stream it reads.
