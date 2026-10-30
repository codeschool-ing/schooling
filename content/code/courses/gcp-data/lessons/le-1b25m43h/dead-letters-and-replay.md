---
title: Dead letters, retention and seek
version: 1
---

**A message that can never be processed does not go away on its own.** The consumer nacks it, Pub/Sub
delivers it again, the consumer nacks it again, and the loop lasts until the subscription's retention
throws the message away, seven days later by default. Meanwhile the message costs a delivery every
time and, on an ordered subscription, holds back its whole key. That is a **poison message**, and the
answer is a **dead-letter topic**: after a set number of delivery attempts, Pub/Sub stops delivering
the message to the subscription and publishes it to another topic instead, where somebody can look at
it. The second half of this section is the opposite problem, a message that was processed and has
to be processed again.

## A dead-letter topic for billing

Quitanda's billing service receives a payment whose amount somebody typed as `"23,50"`, with a
Brazilian decimal comma, where the service expects whole cents. First the dead-letter policy, which
names a topic that has to exist already:

```
ana@laptop:~/gcp$ gcloud pubsub subscriptions update billing --dead-letter-topic=app-events-dead --max-delivery-attempts=5
ERROR: (gcloud.pubsub.subscriptions.update) NOT_FOUND: Dead letter topic not found
ana@laptop:~/gcp$ gcloud pubsub topics create app-events-dead
Created topic [projects/planner-dev/topics/app-events-dead].
ana@laptop:~/gcp$ gcloud pubsub subscriptions update billing --dead-letter-topic=app-events-dead --max-delivery-attempts=3 2>&1 | head -1
ERROR: (gcloud.pubsub.subscriptions.update) argument --max-delivery-attempts: Value must be greater than or equal to 5; received: 3
ana@laptop:~/gcp$ gcloud pubsub subscriptions update billing --dead-letter-topic=app-events-dead --max-delivery-attempts=5
Updated subscription [projects/planner-dev/subscriptions/billing].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create billing-dead --topic=app-events-dead
Created subscription [projects/planner-dev/subscriptions/billing-dead].
```

**The number of attempts is between 5 and 100**, `gcloud`'s help says, and the refusal of 3 came from
`gcloud` itself, before any request was sent. `billing-dead` is the subscription somebody reads the
dead letters from; a dead-letter topic is an ordinary topic, and a message published to it with no
subscription would be kept by nobody, as the first section showed.

**On Google there is one more step, and the emulator does not ask for it.** Pub/Sub moves dead
letters with a service account of its own, the Pub/Sub service agent of the project, and Google
documents that it needs permission to publish to the dead-letter topic and to subscribe to the
source subscription. Without the two grants the policy is accepted and dead letters are not
forwarded. The emulator checks no permission at all, so this lab cannot show that failure.

The billing worker, saved as `~/gcp/billing_worker.py`:

```schooling-example
{"language": "python", "file": "billing_worker.py", "parts": [{"code": "import json\nfrom concurrent.futures import TimeoutError\n\nfrom google.cloud import pubsub_v1\n\nsubscriber = pubsub_v1.SubscriberClient()\npath = subscriber.subscription_path('planner-dev', 'billing')\n\n\n", "note": "The billing service, reduced to the part that can fail: reading a payment."}, {"code": "def callback(message):\n    try:\n        payment = json.loads(message.data)\n        cents = int(payment['cents'])\n    except (ValueError, KeyError) as e:\n        print(f'id {message.message_id:>3}  attempt {message.delivery_attempt}  nack: {e}', flush=True)\n        message.nack()\n        return\n", "note": "**A payment it cannot read is nacked, not acked and not dropped.** Acking it would lose a payment in silence; nacking it asks for it again. `delivery_attempt` counts the deliveries, and it is filled in only on a subscription with a dead-letter topic."}, {"code": "    print(f\"id {message.message_id:>3}  attempt {message.delivery_attempt}  billed {payment['order_id']} {cents}\", flush=True)\n    message.ack()\n\n\n", "note": "A payment it can read is billed and acked."}, {"code": "future = subscriber.subscribe(path, callback=callback)\nwith subscriber:\n    try:\n        future.result(timeout=8)\n    except TimeoutError:\n        future.cancel()\n        future.result()\n", "note": "The same streaming pull as `subscriber.py`, stopped after eight seconds."}]}
```

```
ana@laptop:~/gcp$ gcloud pubsub topics publish app-events --message='{"order_id": "o-304", "cents": "23,50"}' --attribute=type=payment,customer_id=c-05
messageIds:
- '26'
ana@laptop:~/gcp$ python3 billing_worker.py
id  12  attempt 1  billed o-301 4590
id  15  attempt 1  billed o-302 12800
id  17  attempt 1  billed o-303 990
id  26  attempt 1  nack: invalid literal for int() with base 10: '23,50'
id  26  attempt 2  nack: invalid literal for int() with base 10: '23,50'
id  26  attempt 3  nack: invalid literal for int() with base 10: '23,50'
id  26  attempt 4  nack: invalid literal for int() with base 10: '23,50'
id  26  attempt 5  nack: invalid literal for int() with base 10: '23,50'
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull billing-dead --auto-ack --format='yaml(message.data.decode(base64).decode(utf-8),message.attributes)'
---
message:
  attributes:
    CloudPubSubDeadLetterSourceDeliveryCount: '5'
    CloudPubSubDeadLetterSourceSubscription: billing
    CloudPubSubDeadLetterSourceSubscriptionProject: planner-dev
    CloudPubSubDeadLetterSourceTopicPublishTime: '2026-10-30T19:00:51.837Z'
    customer_id: c-05
    type: payment
  data: '{"order_id": "o-304", "cents": "23,50"}'
```

**The worker billed the three payments waiting in `billing` and tried the fourth five times.** The
payments with ids 12 and 15 came from the second run of `events.py`, and 17 from the push test.
After the fifth nack the emulator stopped delivering message 26 and published it to `app-events-dead`,
with its data and attributes as they were and four attributes added that say where it came from and
how often it was tried. This is one of the places the emulator does what the service does: it
forwards, with the service's own attribute names. `delivery_attempt` counted 1 to 5 because the
subscription has a dead-letter policy; without one the field is empty, and the library's own
documentation calls the count best effort and approximate.

**A dead letter is a question for a person, not a message to retry.** The worker's bug is fixed by
reading amounts with a comma, and the dead letter is then published again to `app-events`, by hand or
by a small program that reads `billing-dead`. Republishing it without the fix sends it round the same
five attempts. And on an ordered subscription a dead letter leaves its key's sequence for good: the
messages after it are delivered as if it had never been there.

## How long a message is kept

Three settings decide how long a message can still be read, and each lives in a different place:

| setting | where | default and range, from `gcloud`'s help | keeps |
|---|---|---|---|
| `--message-retention-duration` | subscription | 7 days, from 10 minutes to 31 days | unacknowledged messages |
| `--retain-acked-messages` | subscription | off | acknowledged messages too, for the same duration |
| `--message-retention-duration` | topic | off, from 10 minutes to 31 days | every message published, for every subscription |

**Retention is the size of the second chance.** A consumer deployed on Friday with a bug, found on
Monday, can reprocess the weekend only if the weekend's messages still exist after they were
acknowledged. By default they do not: an acked message is gone from its subscription.

## Seek: reading again

`seek` moves a subscription's position. To a **time**, it marks every retained message published
before that time as acknowledged and every one after it as not, so they are delivered again. To a
**snapshot**, it returns to the state captured when the snapshot was made. Analytics turns on the
retention of acknowledged messages, reads, and then rewinds ten minutes:

```
ana@laptop:~/gcp$ gcloud pubsub subscriptions update analytics --retain-acked-messages
Updated subscription [projects/planner-dev/subscriptions/analytics].
ana@laptop:~/gcp$ python3 events.py > /dev/null && python3 subscriber.py analytics
id  10  view         {"product": "tomate"}
id  17  payment      {"order_id": "o-303", "cents": 990}
id  26  payment      {"order_id": "o-304", "cents": "23,50"}
id  28  view         {"product": "banana-prata"}
id  29  view         {"product": "tomate"}
id  30  add_to_cart  {"product": "banana-prata", "qty": 6}
id  31  payment      {"order_id": "o-301", "cents": 4590}
id  32  search       {"text": "manga"}
id  33  add_to_cart  {"product": "tomate", "qty": 2}
id  34  payment      {"order_id": "o-302", "cents": 12800}
id  35  view         {"product": "manga-palmer"}
ana@laptop:~/gcp$ python3 subscriber.py analytics
ana@laptop:~/gcp$ gcloud pubsub subscriptions seek analytics --time=$(date -d '10 minutes ago' -Iseconds)
subscriptionId: projects/planner-dev/subscriptions/analytics
time: '2026-10-30T18:51:13.000000Z'
ana@laptop:~/gcp$ python3 subscriber.py analytics | wc -l
11
```

**Eleven messages read, nothing left, and after the seek the same eleven again.** The first read also
cleared what `analytics` had been holding: message 10, lent to `gcloud` and never acked in the second
section, and the two payments published since. The eleven are the messages acknowledged after the
retention was switched on. The ones acknowledged before it, ids 1 to 9 and 11 to 16, were not kept,
and no seek brings them back.

A **snapshot** is the safer tool before a change, because it does not depend on guessing a time.
Before deploying a new version of the analytics job, the old position is saved:

```
ana@laptop:~/gcp$ gcloud pubsub snapshots create analytics-before-deploy --subscription=analytics
Created snapshot [projects/planner-dev/snapshots/analytics-before-deploy].
ana@laptop:~/gcp$ python3 events.py > /dev/null && python3 subscriber.py analytics | wc -l
8
ana@laptop:~/gcp$ gcloud pubsub subscriptions seek analytics --snapshot=analytics-before-deploy
snapshotId: projects/planner-dev/snapshots/analytics-before-deploy
subscriptionId: projects/planner-dev/subscriptions/analytics
ana@laptop:~/gcp$ python3 subscriber.py analytics | wc -l
8
```

The new version read eight events; seeking to the snapshot gave the same eight back to be read again.
**A snapshot keeps what was unacknowledged when it was taken and everything published after it.**
Google documents that it lasts at most seven days, less the age of the oldest message it holds, and
the pricing page charges its storage like retention. Lesson 20 uses a snapshot to replay a payments
stream through a consumer that has to come out with the same totals.

**Topic retention is the setting that does not depend on any one subscription:**

```
ana@laptop:~/gcp$ gcloud pubsub topics update app-events --message-retention-duration=7d
Updated topic [projects/planner-dev/topics/app-events].
ana@laptop:~/gcp$ gcloud pubsub topics describe app-events
messageRetentionDuration: 604800s
name: projects/planner-dev/topics/app-events
```

With it, every message published to `app-events` is kept for seven days whoever has acknowledged it,
and `gcloud`'s help says it lets any attached subscription seek up to that far back. That includes a
subscription created later, like the fraud check of the first section, which can be seeked to a
week ago and read the week. **It is also the cheapest way to keep history for several subscriptions**,
because the topic stores one copy where retaining acknowledged messages stores one per subscription.
The last section prices it.
