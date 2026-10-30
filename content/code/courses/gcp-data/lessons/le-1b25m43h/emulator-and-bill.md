---
title: Where the emulator is weaker, and the bill
version: 1
---

**The emulator answers every call Pub/Sub has and implements only some of what the calls mean.** It
is easy to read a green run against it as a run against Google, and this section exists so that
nobody does. Some things it does exactly as the service documents, some it accepts and then ignores,
and some it has no notion of at all. Everything below was run in this lesson unless it says
otherwise.

## What it did as the service does

- **Fan-out and filters.** Each subscription received its own copy, and `billing` received only what
  its filter selected.
- **Redelivery.** A nack, or a 5xx from a push endpoint, brought the same message id back.
- **Dead letters.** After five attempts it forwarded the message, with the service's own
  `CloudPubSubDeadLetterSource…` attributes, and it refused a policy naming a topic that did not
  exist.
- **Seek and snapshots.** Seeking to a time replayed the acknowledged messages it had retained, and
  seeking to a snapshot replayed what came after it.
- **Some bounds.** It refused a retention under ten minutes or over 31 days, and an ack deadline over
  600 seconds.
- **Exactly-once acknowledgement**, which lesson 20 shows: it refuses an expired ack id on a
  subscription with exactly-once delivery, with the service's own reason.

## What it accepted and did differently

```
ana@laptop:~/gcp$ gcloud pubsub subscriptions describe billing
ackDeadlineSeconds: 10
deadLetterPolicy:
  deadLetterTopic: projects/planner-dev/topics/app-events-dead
  maxDeliveryAttempts: 5
filter: attributes.type = "payment"
messageRetentionDuration: 604800s
name: projects/planner-dev/subscriptions/billing
pushConfig: {}
topic: projects/planner-dev/topics/app-events
ana@laptop:~/gcp$ gcloud pubsub subscriptions create quick --topic=app-events --ack-deadline=5 && gcloud pubsub subscriptions describe quick --format='value(ackDeadlineSeconds)'
Created subscription [projects/planner-dev/subscriptions/quick].
5
ana@laptop:~/gcp$ gcloud pubsub subscriptions create billing-retry --topic=app-events --min-retry-delay=20s --max-retry-delay=60s
Created subscription [projects/planner-dev/subscriptions/billing-retry].
ana@laptop:~/gcp$ gcloud pubsub topics publish app-events --message=retry-me > /dev/null && A=$(gcloud pubsub subscriptions pull billing-retry --format='value(ackId)') && gcloud pubsub subscriptions modify-message-ack-deadline billing-retry --ack-ids=$A --ack-deadline=0 > /dev/null 2>&1 && time gcloud pubsub subscriptions pull billing-retry --format='value(message.data)'
retry-me

real	0m1.535s
user	0m0.602s
sys	0m0.063s
ana@laptop:~/gcp$ gcloud pubsub topics create kept --message-retention-duration=1d && gcloud pubsub topics publish kept --message=before > /dev/null && gcloud pubsub subscriptions create kept-late --topic=kept && gcloud pubsub subscriptions pull kept-late --auto-ack --format='value(message.data)'
Created topic [projects/planner-dev/topics/kept].
Created subscription [projects/planner-dev/subscriptions/kept-late].
before
ana@laptop:~/gcp$ gcloud pubsub subscriptions create to-warehouse --topic=app-events --bigquery-table=planner-dev:quitanda.app_events
Created subscription [projects/planner-dev/subscriptions/to-warehouse].
ana@laptop:~/gcp$ gcloud pubsub subscriptions describe to-warehouse --format='yaml(bigqueryConfig,state)'
bigqueryConfig:
  table: planner-dev:quitanda.app_events
ana@laptop:~/gcp$ gcloud pubsub topics publish app-events --message=to-the-warehouse > /dev/null && gcloud pubsub subscriptions pull to-warehouse --auto-ack --format='value(message.data)'
to-the-warehouse
```

**Five settings, all of them stored, and only the first applied as Google documents it.** The
dead-letter policy of the fourth section is there in the description, and it was honoured. The rest
were not. An ack deadline of 5 seconds was accepted and stored, where the service's lowest is 10. A
retry policy of 20 to 60 seconds was stored too, and the nacked message came back in 1.5 seconds,
the time the command itself takes. A subscription created on a topic that retains messages received
`before`, a message published before the subscription existed; on the service a new subscription
starts empty and reaches back only with a seek. And a BigQuery subscription was accepted with its
table, wrote nowhere, because there is no BigQuery here, and handed its message to a plain pull
instead.

And one that takes eleven minutes, because the emulator's clock is the one being tested. A
subscription that keeps messages for the minimum of ten minutes, one message, and a pull after
eleven:

```
ana@laptop:~/gcp$ gcloud pubsub topics create ten-minutes && gcloud pubsub subscriptions create ten-minutes --topic=ten-minutes --message-retention-duration=10m && gcloud pubsub topics publish ten-minutes --message=old
Created topic [projects/planner-dev/topics/ten-minutes].
Created subscription [projects/planner-dev/subscriptions/ten-minutes].
messageIds:
- '47'
ana@laptop:~/gcp$ sleep 660; gcloud pubsub subscriptions pull ten-minutes --auto-ack --format='value(message.data)'
old
```

**The message was still there eleven minutes after a retention of ten.** The emulator stores the
retention, enforces its bounds and never deletes anything by it, so a consumer that falls further
behind than its retention loses nothing here and everything on Google, where the backlog past it is
thrown away with no error at all.

| | Google documents | the emulator, here |
|---|---|---|
| order after a nack | the message again, then the key's later messages | the key's later messages first |
| retry policy | waits between 20 and 60 seconds before redelivering | redelivered at once |
| ack deadline | 10 to 600 seconds | accepted 5 |
| a new subscription on a retaining topic | starts empty, and can seek back | received the message published before it |
| retention | deletes a message when it expires | still delivered after the retention |
| BigQuery and Cloud Storage subscriptions | write rows or files | accepted, written nowhere, and pullable |
| updating a filter | not a flag of `gcloud pubsub subscriptions update` | the API call refused, by name |
| message ids | long strings, in no order | 1, 2, 3 |

## What it has no notion of

**Permissions, quotas and money.** The emulator checks no credential and no IAM role, so the grants a
dead-letter topic needs, the publisher and subscriber roles on a topic, and a push endpoint's token
are all untested here. It has no quota and never throttles, so a publisher that works against it has
never met a `RESOURCE_EXHAUSTED`. It has no regions, so "ordered within a region" and the
message storage policy that pins messages to regions cannot be tried. And it bills nothing, which is
the rest of this section.

## The bill

Pub/Sub charges for three things, and the prices come from cloud.google.com/pubsub/pricing, read on
2026-10-30. **Throughput is $40 per TiB, in all Google Cloud regions**, `southamerica-east1` included,
after the first 10 GiB of each month, which are free. Throughput counts bytes published and bytes
delivered, once for every subscription, and the size of a message is its data, its attributes, 20
bytes of timestamp and its message id. **Storage is $0.27 per GiB-month**, for topic retention,
retained acknowledged messages, snapshots, and a backlog kept past its first day. A BigQuery or Cloud
Storage subscription costs **$50 per TiB** instead of the delivery price, with no free 10 GiB. Moving
messages between regions is billed as network transfer, and between zones the page charges nothing.

Two lines on that page shape the design more than the prices do. **Filtered messages are billed as
delivered**: Pub/Sub acknowledges what a filter turns away and charges the throughput anyway. And **a
request is billed at 1 KB at least**, so small messages sent one per request cost more than their
size. A short program does the arithmetic for Quitanda's app events, saved as `~/gcp/bill.py`:

```schooling-example
{"language": "python", "file": "bill.py", "parts": [{"code": "GiB, TiB = 2**30, 2**40\nevents_a_day, size, days = 5_000_000, 600, 30\npublished = events_a_day * size * days\n\n", "note": "Quitanda's app: five million events a day, 600 bytes each once the attributes, the 20 bytes of timestamp and the message id are counted, as the pricing page counts them. A month of 30 days."}, {"code": "throughput = published * (1 + 2)\nbilled = max(throughput - 10 * GiB, 0)\nprint(f'published        {published / GiB:8.2f} GiB')\nprint(f'throughput       {throughput / TiB:8.4f} TiB, {billed / TiB:.4f} TiB after the free 10 GiB')\nprint(f'throughput       ${billed / TiB * 40:7.2f}')\n\n", "note": "**Throughput is published bytes plus delivered bytes, once per subscription**: one publish and two deliveries, to `billing` and `analytics`. The filter on `billing` does not lower it, because filtered messages are billed as delivered. The first 10 GiB of a month are free and the rest is $40 per TiB."}, {"code": "kept = events_a_day * size * 7\nprint(f'a week kept      {kept / GiB:8.2f} GiB, ${kept / GiB * 0.27:.2f} a month')\n\n", "note": "Seven days of topic retention keeps a week of events at all times, at $0.27 per GiB-month."}, {"code": "alone = (events_a_day * 1000 * days + published * 2 - 10 * GiB) / TiB * 40\nprint(f'one per request  ${alone:7.2f}')\nprint(f'to BigQuery      ${published / TiB * 50:7.2f}')\n", "note": "**The same events published one per request**: each request is counted as at least 1 KB, so each 600-byte event is billed at 1,000 bytes on the way in. The last line prices analytics as a BigQuery subscription instead: its share, at $50 per TiB and with no free 10 GiB."}]}
```

```
ana@laptop:~/gcp$ python3 bill.py
published           83.82 GiB
throughput         0.2456 TiB, 0.2358 TiB after the free 10 GiB
throughput       $   9.43
a week kept         19.56 GiB, $5.28 a month
one per request  $  11.61
to BigQuery      $   4.09
```

**$9.43 a month moves every event to both services**, and a week of topic retention adds $5.28. The
filter on `billing` saved nothing: it receives two events in eight and is billed for all eight, so a
billing service on a topic of its own, fed only payments, would cut a third of the throughput line.
Publishing each event in its own request raises the bill from $9.43 to $11.61, because every 600-byte
event is counted as 1,000 on the way in, which is what the publisher's batching avoids. And had
analytics been a BigQuery subscription, its share of 83.82 GiB would be billed at $50 per TiB with no
free tier, about $4.09 instead of the delivery price, with no consumer of Quitanda's to run.
