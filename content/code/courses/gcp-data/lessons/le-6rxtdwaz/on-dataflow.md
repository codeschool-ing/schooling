---
title: Event time from Pub/Sub, here and on Dataflow
version: 1
---

**A TestStream is where you learn windows; Pub/Sub is where they have to work.** Two things change
when the source is real. The event time has to travel with each message, because Pub/Sub only
knows when it received one. And the watermark is no longer yours to set: the source estimates it,
and how well it does decides which data counts as late. This section runs the first on the
emulator, shows that the DirectRunner's estimate is not Dataflow's, and teaches Dataflow's from
Google's documentation, without running it.

## Sending the event time

**`ReadFromPubSub(timestamp_attribute='placed')` takes each element's timestamp from a message
attribute instead of from the publish time.** The attribute holds either milliseconds since the
epoch or an RFC 3339 time, and the publisher has to set it, because only the publisher knows when
the order was placed. This program publishes half of the evening at a time, with the time each
order was placed in an attribute called `placed`. Save it as `~/gcp/publish_evening.py`:

`publish_evening.py`:

```python
"""publish_evening.py: half of the evening's orders, with the time each was placed.

    python3 publish_evening.py first        the first five orders
    python3 publish_evening.py second       the other five
"""
import json
import sys
from datetime import datetime, timezone

from google.cloud import pubsub_v1

from evening import ORDERS, at

half = ORDERS[:5] if sys.argv[1] == 'first' else ORDERS[5:]
publisher = pubsub_v1.PublisherClient()
topic = publisher.topic_path('planner-dev', 'evening')
for order, customer, neighbourhood, cents, placed, arrived in half:
    when = datetime.fromtimestamp(at(placed), timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    data = json.dumps({'order_id': order, 'neighbourhood': neighbourhood, 'cents': cents})
    publisher.publish(topic, data.encode(), placed=when).result()
    print(f'{order} placed {placed}, published with placed={when}')
```

And a pipeline that reads them, in five-minute windows of that attribute. Save it as
`~/gcp/from_pubsub.py`:

`from_pubsub.py`:

```python
"""from_pubsub.py: orders from Pub/Sub, in five-minute windows of the time each was placed."""
import json

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.transforms.window import FixedWindows

from evening import clock


class Show(beam.DoFn):
    def process(self, total, window=beam.DoFn.WindowParam):
        neighbourhood, cents = total
        print(f'{clock(window.start)}-{clock(window.end)}  {neighbourhood:<10} {cents / 100:>7.2f}',
              flush=True)


options = PipelineOptions(['--streaming'], runner='BundleBasedDirectRunner')
with beam.Pipeline(options=options) as p:
    (p
     | beam.io.ReadFromPubSub(subscription='projects/planner-dev/subscriptions/evening-beam',
                              timestamp_attribute='placed')
     | beam.Map(json.loads)
     | beam.Map(lambda o: (o['neighbourhood'], o['cents']))
     | beam.WindowInto(FixedWindows(5 * 60))
     | beam.CombinePerKey(sum)
     | beam.ParDo(Show()))
```

With the Pub/Sub emulator running in its own terminal, as in lesson 21, a topic and the pipeline's
subscription:

```
ana@laptop:~/gcp$ gcloud pubsub topics create evening
Created topic [projects/planner-dev/topics/evening].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create evening-beam --topic=evening
Created subscription [projects/planner-dev/subscriptions/evening-beam].
```

In a third terminal, the pipeline, for ninety seconds:

```sh
timeout 90 python3 from_pubsub.py
```

Back in the terminal you type into, the first five orders, then, after about twenty seconds, the
other five:

```
ana@laptop:~/gcp$ python3 publish_evening.py first
o-501 placed 19:01:10, published with placed=2026-10-15T22:01:10Z
o-502 placed 19:02:05, published with placed=2026-10-15T22:02:05Z
o-503 placed 19:03:30, published with placed=2026-10-15T22:03:30Z
o-504 placed 19:04:20, published with placed=2026-10-15T22:04:20Z
o-505 placed 19:06:00, published with placed=2026-10-15T22:06:00Z
ana@laptop:~/gcp$ python3 publish_evening.py second
o-506 placed 19:07:45, published with placed=2026-10-15T22:07:45Z
o-507 placed 19:04:50, published with placed=2026-10-15T22:04:50Z
o-508 placed 19:11:15, published with placed=2026-10-15T22:11:15Z
o-509 placed 19:13:40, published with placed=2026-10-15T22:13:40Z
o-510 placed 19:09:10, published with placed=2026-10-15T22:09:10Z
```

**The attribute is in UTC**, `22:01:10Z` for 19:01:10 in São Paulo, and the pipeline turns it back
into local time when it prints. The pipeline's terminal, after its ninety seconds:

```
ana@laptop:~/gcp$ timeout 90 python3 from_pubsub.py
19:00:00-19:05:00  Moema        55.80
19:00:00-19:05:00  Pinheiros   128.00
```

**Three orders of ten made it into a window**: `o-501`, `o-502` and `o-503`, the first three
published, 55.80 for Moema and 128.00 for Pinheiros. The other seven were dropped, without a
message, the same silence as the previous sections. The reason is in the DirectRunner's own source:
after each pull from Pub/Sub, its Pub/Sub reader sets the watermark to `time.time()`, the clock on the wall,
with a comment in the code saying the right value is still to be done. The first pull, which in this
run brought three messages, was read before the watermark had moved at all, so what it brought
counted as on time. From then on the watermark was the afternoon of the day this was recorded, and every order of 15 October was two
weeks behind it. **With old data, the DirectRunner reading Pub/Sub calls almost everything late**,
and how much survives depends on how many messages the first pull happened to return. That is the
limit of this lab for watermarks, and the reason the earlier sections used a TestStream.

## What Dataflow does instead

From here on, nothing was run. Google's Dataflow documentation describes how its Pub/Sub source
estimates a watermark, and three points of it matter for this lesson:

- **The estimate comes from the backlog, not from the wall clock.** Dataflow looks at the event
  times of the messages still unacknowledged in the subscription, and holds the watermark at about
  the oldest of them. When `timestamp_attribute` is set, Dataflow creates a second, tracking
  subscription on the same topic to inspect those timestamps without delivering them. A
  subscription with a day of old orders waiting in it therefore starts with a watermark a day in the
  past, and nothing in it is late merely for being old.
- **A message published late is still late.** If a phone publishes an order placed ten minutes ago,
  after the backlog has been drained past that time, the watermark has moved on and the order is
  behind it. The estimate cannot see a message that has not been published yet, which is the lift
  of the opening video, and no runner can.
- **Two numbers on the job's page measure the gap.** Data freshness is how far the watermark is
  behind the present, and system latency is how long an element waits in the pipeline. A data
  freshness that keeps growing means the job is falling behind its input, and windows are closing
  later and later.

**Dropped late data is as quiet on Dataflow as it was here.** No step fails and no error is logged
for an element behind the watermark and past its allowed lateness. The dependable check is the one lesson 21 made
possible: the same transforms, run in batch over the night's export, compute the same windows from
complete data. A stream whose totals keep disagreeing with the night's has a watermark that is too
eager or an allowed lateness that is too short.

## What lateness and early panes cost

**Every window is state until the watermark passes its end plus the allowed lateness.** For this
pipeline, a window of five minutes with five minutes of lateness is kept for about ten, one entry
per neighbourhood. With Streaming Engine that state lives in the service, and both kinds of
Streaming Engine billing in lesson 21 grow with it: the legacy one counts the bytes kept for
windows, and the resource-based one counts the work of keeping them. An allowed lateness of a day
on a sliding window of an hour every minute is sixty copies of every element, each kept for a day.

Early panes cost in the other direction: every pane is an output, written to a sink and, on
Pub/Sub or BigQuery, paid for as writes. A trigger every minute on a window of an hour is up to
sixty writes per key where one would do.

**Draining a job is the watermark's last move.** `gcloud dataflow jobs drain`, from lesson 21,
stops reading, and the help of the lab's own `gcloud` says the input watermark is then advanced to
infinity: every open window passes its end at once and fires what it holds. Data still on its way
when the drain starts is not waited for.
