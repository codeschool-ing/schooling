---
title: The same pipeline, fed by Pub/Sub
version: 1
---

**The stream end changes two things and keeps everything between them.** It reads from a Pub/Sub
subscription instead of a file, and it cuts the messages into windows of one minute before the
middle adds them up. Run with `--streaming`, the program never finishes on its own: an unbounded
collection has no last element, so there is no moment at which the job is done, only moments at
which a window is.

## The emulator, and three topics

The Pub/Sub emulator runs in a terminal of its own, started with the same command as in lesson 19, after
`cd ~/gcp` and the second line of "Every time you open a terminal":

```sh
gcloud beta emulators pubsub start --project=planner-dev --host-port=localhost:8085
```

Then, in the terminal you type into, three topics: the one the shop publishes to, the one the
totals go to, and one for unreadable lines. The first gets the pipeline's own subscription, and the
other two get one each so that you can look at what arrives:

```
ana@laptop:~/gcp$ gcloud pubsub topics create order-events order-totals order-totals-unreadable
Created topic [projects/planner-dev/topics/order-events].
Created topic [projects/planner-dev/topics/order-totals].
Created topic [projects/planner-dev/topics/order-totals-unreadable].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create order-events-beam --topic=order-events
Created subscription [projects/planner-dev/subscriptions/order-events-beam].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create order-totals-check --topic=order-totals
Created subscription [projects/planner-dev/subscriptions/order-totals-check].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create order-totals-unreadable-check --topic=order-totals-unreadable
Created subscription [projects/planner-dev/subscriptions/order-totals-unreadable-check].
```

**`order-events-beam` is the pipeline's own subscription.** A subscription is a cursor that
belongs to one reader, lesson 19's point, and a pipeline that shared one with another program would
receive about half of each message stream. On Dataflow too, each pipeline gets a subscription of its
own.

## Without the window

First the one line that a stream cannot do without. `--window 0` leaves the `WindowInto` out:

```
ana@laptop:~/gcp$ timeout 60 python3 orders_beam.py --subscription order-events-beam --topic order-totals --streaming --window 0 2>&1 | tail -1
ValueError: GroupByKey cannot be applied to an unbounded PCollection with global windowing and a default trigger
```

**Beam refuses before reading a single message.** In the global window, with the default trigger, a
group is emitted when the window ends, and the global window of an unbounded collection never ends.
`CombinePerKey` would wait for ever and emit nothing, so Beam rejects the graph instead of running
it. The two ways out are the two halves of lesson 22: cut the stream into windows that do end, or
keep the global window and give it a trigger that fires before the end. This program takes the
first.

## With the window

In a third terminal, after the same two lines, start the pipeline:

```sh
timeout 120 python3 orders_beam.py --subscription order-events-beam --topic order-totals --streaming
```


```
ana@laptop:~/gcp$ timeout 120 python3 orders_beam.py --subscription order-events-beam --topic order-totals --streaming
```

**It prints nothing, from start to end, and that is correct.** Its output goes to a topic, and it is waiting for
messages. `timeout 120` ends it after two minutes, because nothing else would: a streaming pipeline
runs until somebody stops it, which on Dataflow is a drain or a cancel, two different
things the next section separates. `Ctrl+C` is not a dependable way out of the DirectRunner, whose
threads keep running after the main one is interrupted.

Back in the terminal you type into, the shop starts publishing. This program sends every line of
the same `events.jsonl` as one message each. Save it as `~/gcp/publish.py`:

`publish.py`:

```python
"""publish.py: every line of events.jsonl, published to the topic order-events."""
from google.cloud import pubsub_v1

publisher = pubsub_v1.PublisherClient()
topic = publisher.topic_path('planner-dev', 'order-events')
with open('events.jsonl', encoding='utf-8') as f:
    futures = [publisher.publish(topic, line.rstrip('\n').encode('utf-8')) for line in f]
for future in futures:
    future.result()
print(f'{len(futures):,} messages published to {topic}')
```

Wait for the end of the minute, then look at what the pipeline published:

```
ana@laptop:~/gcp$ python3 publish.py
2,001 messages published to projects/planner-dev/topics/order-events
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull order-totals-check --auto-ack --limit=20 --format='value(message.data)' | sort
{"window": "15:33:00", "neighbourhood": "Butantã", "orders": 150, "reais": "23835.54"}
{"window": "15:33:00", "neighbourhood": "Moema", "orders": 138, "reais": "22737.55"}
{"window": "15:33:00", "neighbourhood": "Pinheiros", "orders": 161, "reais": "24949.60"}
{"window": "15:33:00", "neighbourhood": "Santana", "orders": 140, "reais": "22367.32"}
{"window": "15:33:00", "neighbourhood": "Tatuapé", "orders": 152, "reais": "26061.58"}
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull order-totals-unreadable-check --auto-ack --limit=5 --format='value(message.data)'
{"order_id": "o-12000", "event": "placed", "total_cents": 
```

**The same five totals as the night run, to the cent, and the same bad line beside them.** The
middle of the program did not change, and neither did its answer. What changed is the window: the
totals now say which minute they are for, and the minute is the moment this run published the
events, in the afternoon of the day it was recorded, not the evening of 15 October that `at` says.
All 2,001 messages arrived within one minute, so one window holds them all. Published over an
hour, as the shop's app really publishes them, they would have come out as sixty sets of totals, one
for each minute.

**That minute is the time Pub/Sub received each message, not the time the order was placed.**
`ReadFromPubSub` gives every element the message's publish time unless it is told to read a
timestamp from an attribute, and a rider's phone that sends an event ten minutes late puts the
event in the wrong minute. That is the subject of lesson 22, and the reason it exists.

## What this run says, and what it does not

It says the program is correct in both modes: the same events give the same totals, a bad line
goes to its own sink in both, and the stream refuses a group it could never finish. **It says
nothing about Dataflow.** One process read the subscription; there were no workers to start, no
autoscaling, no shuffle between machines and no state kept outside the process. And delivery here is not
what lesson 20 would lead you to expect. **The DirectRunner acknowledges each message the moment it
pulls it**, before any step has seen it, which its source says in a comment: a run that died halfway
would lose the messages it had pulled, not count them twice. Dataflow does the opposite, as its
documentation describes: it acknowledges a message only once the work on it is kept durably, and it
removes duplicates that Pub/Sub delivers again by their message id. The next section is what
Dataflow adds, from Google's documentation, and none of it ran here.
