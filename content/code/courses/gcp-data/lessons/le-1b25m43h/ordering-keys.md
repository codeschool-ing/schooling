---
title: Ordering keys, and the order the emulator does not keep
version: 1
---

**Without an ordering key, Pub/Sub promises no order at all**, not even between two messages from the
same publisher a second apart. A reader that pictures the topic as one line of events, read back in
the order they happened, will one day mark an order delivered before it was placed. The service is
built from many machines that store and deliver in parallel, and order costs something it does not
spend unless asked. What it offers instead is an **ordering key**: a string on each message, and the
promise that messages with the same key, published in the same region, are delivered to a
subscription with ordering enabled in the order Pub/Sub received them.

**Choose the key as the smallest thing whose events must stay in order.** For order status that is the
customer or the order, never the store and never a constant: one key carries one stream of ordered
messages at a time, and Google documents a limit of 1 MB a second per ordering key. A topic keyed by
a constant is a topic with a single lane.

## Ordering on both ends

A topic for order status, and two subscriptions on it, one with ordering and one without:

```
ana@laptop:~/gcp$ gcloud pubsub topics create order-status
Created topic [projects/planner-dev/topics/order-status].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create status-ordered --topic=order-status --enable-message-ordering
Created subscription [projects/planner-dev/subscriptions/status-ordered].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create status-any --topic=order-status
Created subscription [projects/planner-dev/subscriptions/status-any].
```

Save the publisher as `~/gcp/ordered.py`:

```schooling-example
{"language": "python", "file": "ordered.py", "parts": [{"code": "from google.cloud import pubsub_v1\n\noptions = pubsub_v1.types.PublisherOptions(enable_message_ordering=True)\npublisher = pubsub_v1.PublisherClient(publisher_options=options)\ntopic = publisher.topic_path('planner-dev', 'order-status')\n\n", "note": "**Ordering is switched on in the publisher as well as on the subscription.** With the option, the client sends one key's messages one batch at a time, in order, and never two batches of the same key at once."}, {"code": "EVENTS = [\n    ('o-101', 'c-17', 'placed'), ('o-102', 'c-02', 'placed'),\n    ('o-101', 'c-17', 'packed'), ('o-103', 'c-05', 'placed'),\n    ('o-102', 'c-02', 'packed'), ('o-101', 'c-17', 'delivered'),\n    ('o-103', 'c-05', 'cancelled'), ('o-102', 'c-02', 'delivered'),\n]\n\n", "note": "Eight status changes of three orders, interleaved as they would be on a busy evening. An order is placed, packed and delivered, or cancelled."}, {"code": "futures = [publisher.publish(topic, f'{order} {status}'.encode(), ordering_key=customer)\n           for order, customer, status in EVENTS]\nfor (order, customer, status), future in zip(EVENTS, futures):\n    print(f'id {future.result():>3}  key {customer}  {order} {status}')\n", "note": "**The ordering key is the customer**, so each customer's events keep their order and different customers' events are free of each other."}]}
```

```
ana@laptop:~/gcp$ python3 ordered.py
id  21  key c-17  o-101 placed
id  18  key c-02  o-102 placed
id  22  key c-17  o-101 packed
id  23  key c-05  o-103 placed
id  19  key c-02  o-102 packed
id  24  key c-17  o-101 delivered
id  25  key c-05  o-103 cancelled
id  20  key c-02  o-102 delivered
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull status-any --auto-ack --limit=20 --format='table(message.messageId:label=ID,message.orderingKey:label=KEY,message.data.decode(base64).decode(utf-8):label=DATA)'
ID  KEY   DATA
18  c-02  o-102 placed
19  c-02  o-102 packed
20  c-02  o-102 delivered
23  c-05  o-103 placed
25  c-05  o-103 cancelled
21  c-17  o-101 placed
22  c-17  o-101 packed
24  c-17  o-101 delivered
```

**The ids show the publisher at work.** The program published in the interleaved order of `EVENTS`,
and the library sent one batch per key, so the ids were handed out as the batches arrived: 18 to 20
for `c-02`, 21, 22 and 24 for `c-17`, 23 and 25 for `c-05`. Across keys they mean nothing, and within
each key they rise in the order written. The pull from
`status-any`, the subscription without ordering, happened to come back in key order too. That is
this emulator's habit and not a promise: the subscription asked for no order, and the real service
interleaves such a pull however its machines finish.

**Ordering needs the option in the publisher as well as the subscription.** Without it the library
refuses an ordering key before sending anything:

```
ana@laptop:~/gcp$ python3 -c "from google.cloud import pubsub_v1; p = pubsub_v1.PublisherClient(); p.publish(p.topic_path('planner-dev', 'order-status'), b'x', ordering_key='c-17')" 2>&1 | tail -1
ValueError: Cannot publish a message with an ordering key when message ordering is not enabled.
```

## When a message is nacked

**Order matters most when something fails**, and that is where the emulator parts from the service.
Save this as `~/gcp/redeliver.py`. It reads the subscription with ordering, takes one message, hands
it back with a nack, and then reads everything that is left:

```schooling-example
{"language": "python", "file": "redeliver.py", "parts": [{"code": "import sys\n\nfrom google.cloud import pubsub_v1\n\nsubscriber = pubsub_v1.SubscriberClient()\npath = subscriber.subscription_path('planner-dev', sys.argv[1])\n\n\ndef pull(n):\n    return subscriber.pull(subscription=path, max_messages=n, timeout=5).received_messages\n\n\n", "note": "`pull` is the unary form, one request and one answer, which is what `gcloud` uses. It makes the order of delivery easy to print."}, {"code": "first = pull(1)[0]\nprint(f'pulled {first.message.ordering_key}  {first.message.data.decode()}, nacked it')\nsubscriber.modify_ack_deadline(subscription=path, ack_ids=[first.ack_id], ack_deadline_seconds=0)\n\n", "note": "**A nack is an ack deadline of zero**: it hands the message back at once instead of waiting for the deadline to run out. This is what a consumer does when it fails on a message."}, {"code": "for r in pull(20):\n    print(f'then   {r.message.ordering_key}  {r.message.data.decode()}')\n", "note": "Then it pulls everything that is left, the nacked message included, and prints the order it came in."}]}
```

`status-ordered` still holds all eight messages, since only `status-any` was read:

```
ana@laptop:~/gcp$ python3 redeliver.py status-ordered
pulled c-02  o-102 placed, nacked it
then   c-02  o-102 packed
then   c-05  o-103 placed
then   c-17  o-101 placed
then   c-17  o-101 packed
then   c-02  o-102 delivered
then   c-02  o-102 placed
then   c-05  o-103 cancelled
then   c-17  o-101 delivered
```

**The emulator delivered `o-102 packed` and `o-102 delivered` before `o-102 placed`**, on the
subscription that asked for order. It took the nack, put `placed` back behind the rest, and went on
handing out the key's later messages as though the earlier one were done. A consumer tested against it would never
see what the real service does here. Google documents it, and it was not run: when a message
with an ordering key is nacked or its deadline runs out, Pub/Sub delivers it again **together with
every later message of that key**, including ones already acknowledged, so that the reader meets
them again in order. The cost of order is therefore duplicates, and a consumer of an ordered
subscription has to be idempotent, which is lesson 20.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"One ordering key, c-02, whose first message o-102 placed is nacked. Top row, what Google documents and was not run here: o-102 placed is delivered again, then o-102 packed and o-102 delivered, so the order holds. Bottom row, what the emulator did in redeliver.py: o-102 packed and o-102 delivered came next, before the order was placed, and o-102 placed came last.\" data-fig=\"l19-order\"><text x=\"20.0\" y=\"54.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Google documents</text><text x=\"20.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">not run here</text><rect x=\"175.0\" y=\"40.0\" width=\"118.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"234.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-102 placed</text><text x=\"234.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">nacked</text><rect x=\"311.0\" y=\"40.0\" width=\"118.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-102 placed</text><text x=\"370.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">delivered again</text><line x1=\"294.0\" y1=\"62.0\" x2=\"303.0\" y2=\"62.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"309.0,62.0 303.0,65.0 303.0,59.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"447.0\" y=\"40.0\" width=\"118.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"506.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-102 packed</text><line x1=\"430.0\" y1=\"62.0\" x2=\"439.0\" y2=\"62.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"445.0,62.0 439.0,65.0 439.0,59.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"583.0\" y=\"40.0\" width=\"118.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"642.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-102 delivered</text><line x1=\"566.0\" y1=\"62.0\" x2=\"575.0\" y2=\"62.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"581.0,62.0 575.0,65.0 575.0,59.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><text x=\"20.0\" y=\"154.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the emulator</text><text x=\"20.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">as run, redeliver.py</text><rect x=\"175.0\" y=\"140.0\" width=\"118.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"234.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-102 placed</text><text x=\"234.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">nacked</text><rect x=\"311.0\" y=\"140.0\" width=\"118.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-102 packed</text><text x=\"370.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">before it was placed</text><line x1=\"294.0\" y1=\"162.0\" x2=\"303.0\" y2=\"162.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"309.0,162.0 303.0,165.0 303.0,159.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"447.0\" y=\"140.0\" width=\"118.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"506.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-102 delivered</text><text x=\"506.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">before it was placed</text><line x1=\"430.0\" y1=\"162.0\" x2=\"439.0\" y2=\"162.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"445.0,162.0 439.0,165.0 439.0,159.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon><rect x=\"583.0\" y=\"140.0\" width=\"118.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"642.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">o-102 placed</text><text x=\"642.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">last</text><line x1=\"566.0\" y1=\"162.0\" x2=\"575.0\" y2=\"162.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"581.0,162.0 575.0,165.0 575.0,159.0\" fill=\"var(--wire)\" stroke=\"none\"></polygon></svg>", "caption": "One key's three messages after the first is nacked: the order the service documents, and the order the emulator delivered."}
```

## What ordering does not survive

**A publisher's failure stops the key, by design.** If publishing a message with an ordering key
fails after the library's retries, the Python client pauses that key: every later publish with it
fails at once, so that nothing overtakes the message that did not go. The program has to decide what
to do with the failure and then call `publisher.resume_publish(topic, key)`. The other keys go on.
None of this was run, because the emulator never fails a publish.

**Ordering is per region and per subscription.** Two publishers in two regions writing the same key
are not ordered against each other; a dead-letter topic, in the next section, takes a message out of
its key's sequence for good. And an ordered subscription delivers a key's messages one batch at a
time, so a key with a slow consumer holds back only its own messages, while a key with a single slow
message holds back everything after it. If a question needs the order of events across keys, the
subscription cannot answer it; the events have to carry a timestamp of their own, and lesson 22 is
about sorting by it when some arrive late.
