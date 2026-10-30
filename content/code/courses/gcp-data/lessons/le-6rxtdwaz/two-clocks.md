---
title: Event time and processing time
version: 1
---

**Every event in a stream has two times, and a window has to choose one.** The **event time** is
when the thing happened: the moment the customer pressed the button. The **processing time** is
when the pipeline saw it, which is later, by a few milliseconds when the network behaves and by
minutes when a phone is in a lift. Lesson 21's streaming run windowed by processing time, the
publish time Pub/Sub stamps on a message, and said so. This lesson windows by event time, which is
what a question such as "how much did Moema order between 19:00 and 19:05" means.

The wrong picture is that the two differ by a small, steady delay, so that windowing by arrival is
off by a second or two and nothing worse. **The delay is not steady.** Most events arrive at once and
a few arrive minutes late, and the late ones are not a random sample: they come from phones on bad
networks, which is to say from particular places and particular moments.

## One evening, ten orders

To see the difference, the data has to be small enough to check by hand, and the arrival order
has to be under your control rather than the network's. This module holds ten orders from 15
October with both times written down, and the programs of this lesson import it. Seven arrived
within two seconds; three did not. Save it as `~/gcp/evening.py`:

`evening.py`:

```python
"""evening.py: ten orders of one evening at Quitanda, as the riders' phones sent them.

Imported by the other programs of this lesson. Each order carries the time it
was placed, which is its event time, and the time it reached Pub/Sub, which is
when a pipeline could first see it.
"""
from datetime import datetime, timedelta, timezone

from apache_beam.testing.test_stream import TestStream
from apache_beam.transforms.window import TimestampedValue

SP = timezone(timedelta(hours=-3))

ORDERS = [
    # order    customer  neighbourhood  cents   placed      arrived
    ('o-501', 'c-17', 'Moema',      4590, '19:01:10', '19:01:12'),
    ('o-502', 'c-02', 'Pinheiros', 12800, '19:02:05', '19:02:06'),
    ('o-503', 'c-17', 'Moema',       990, '19:03:30', '19:03:31'),
    ('o-504', 'c-05', 'Pinheiros',  2350, '19:04:20', '19:08:40'),
    ('o-505', 'c-31', 'Moema',      1500, '19:06:00', '19:06:02'),
    ('o-506', 'c-02', 'Pinheiros',  7200, '19:07:45', '19:07:46'),
    ('o-507', 'c-44', 'Moema',      3100, '19:04:50', '19:12:30'),
    ('o-508', 'c-05', 'Pinheiros',  5600, '19:11:15', '19:11:16'),
    ('o-509', 'c-17', 'Moema',      2200, '19:13:40', '19:13:41'),
    ('o-510', 'c-31', 'Pinheiros',   800, '19:09:10', '19:14:00'),
]


def at(hhmmss):
    """Seconds since the epoch for a time on 15 October 2026, São Paulo."""
    h, m, s = map(int, hhmmss.split(':'))
    return datetime(2026, 10, 15, h, m, s, tzinfo=SP).timestamp()


def clock(timestamp):
    return datetime.fromtimestamp(float(timestamp), SP).strftime('%H:%M:%S')


def stamped(order, key, time):
    """One order as (key, cents), stamped with its 'placed' or 'arrived' time."""
    column = {'placed': 4, 'arrived': 5}[time]
    index = {'neighbourhood': 2, 'customer': 1}[key]
    return TimestampedValue((order[index], order[3]), at(order[column]))


def arrivals(lag=60):
    """The orders as a TestStream, replayed in the order they arrived.

    Before each order the processing-time clock moves to its arrival, and after
    it the watermark moves to `lag` seconds behind that arrival: the source's
    claim that nothing placed earlier is still on its way.
    """
    stream = TestStream().advance_watermark_to(at('19:00:00'))
    now = at('19:00:00')
    for o in sorted(ORDERS, key=lambda o: o[5]):
        stream = stream.advance_processing_time(at(o[5]) - now)
        now = at(o[5])
        stream = stream.add_elements([TimestampedValue((o[2], o[3]), at(o[4]))])
        stream = stream.advance_watermark_to(now - lag)
    return stream.advance_processing_time(60).advance_watermark_to_infinity()
```

**`stamped` and `arrivals` are the two ways the lesson feeds these orders to Beam.** `stamped`
turns one order into an element whose timestamp is one of its two times, for a batch pipeline that
reads them all at once. `arrivals` builds a **TestStream**, Beam's tool for testing streaming
pipelines: a source that emits the elements in the order you give, moves the processing-time clock
when you say, and moves the watermark when you say. The fourth section explains the watermark; for
now it is the line `advance_watermark_to(now - lag)`. Nothing in a TestStream depends on how fast
the laptop is, so every run gives the same output, which a stream from Pub/Sub never promises.

## The same orders, windowed by each clock

A batch pipeline that stamps each order with one of its two times, cuts the evening into windows
of five minutes and sums each neighbourhood's orders in each. Save it as `~/gcp/by_time.py`:

`by_time.py`:

```python
"""by_time.py: the evening's orders in five-minute windows, by one of two clocks.

    python3 by_time.py placed       windows of event time
    python3 by_time.py arrived      windows of processing time
"""
import sys

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.transforms.window import FixedWindows

from evening import ORDERS, clock, stamped


class Show(beam.DoFn):
    def process(self, total, window=beam.DoFn.WindowParam):
        neighbourhood, cents = total
        print(f'{clock(window.start)}-{clock(window.end)}  {neighbourhood:<10} {cents / 100:>7.2f}')


options = PipelineOptions([], runner='BundleBasedDirectRunner')
with beam.Pipeline(options=options) as p:
    (p
     | beam.Create(ORDERS)
     | beam.Map(stamped, 'neighbourhood', sys.argv[1])
     | beam.WindowInto(FixedWindows(5 * 60))
     | beam.CombinePerKey(sum)
     | beam.ParDo(Show()))
```

`beam.Map(stamped, 'neighbourhood', sys.argv[1])` passes the two extra arguments to `stamped` for
every order. The window is chosen by the element's timestamp, so the only difference between the
two runs is which time that is:

```
ana@laptop:~/gcp$ python3 by_time.py placed | sort
19:00:00-19:05:00  Moema        86.80
19:00:00-19:05:00  Pinheiros   151.50
19:05:00-19:10:00  Moema        15.00
19:05:00-19:10:00  Pinheiros    80.00
19:10:00-19:15:00  Moema        22.00
19:10:00-19:15:00  Pinheiros    56.00
ana@laptop:~/gcp$ python3 by_time.py arrived | sort
19:00:00-19:05:00  Moema        55.80
19:00:00-19:05:00  Pinheiros   128.00
19:05:00-19:10:00  Moema        15.00
19:05:00-19:10:00  Pinheiros    95.50
19:10:00-19:15:00  Moema        53.00
19:10:00-19:15:00  Pinheiros    64.00
```

**The totals of the evening are the same; the windows they fall in are not.** By the time each
order was placed, Pinheiros ordered 151.50 reais between 19:00 and 19:05; by the time each arrived,
128.00. The 23.50 of `o-504`, placed at 19:04:20 and arrived at 19:08:40, moved into the next
window, where Pinheiros shows 95.50 instead of 80.00. `o-507` and `o-510` moved the same way, and
Moema's last window holds 53.00 by arrival against 22.00 by placing. **Both runs added every
order once**; what changed is the question each answered. The first answers "how much was ordered
in these five minutes", which is the question. The second answers "how much reached us in these
five minutes", which is a fact about the network.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"A chart of the ten orders of the evening, the time each was placed across and the time it arrived upwards, from 19:00 to 19:15 on both axes. Seven orders sit on the diagonal: they arrived within two seconds of being placed. Three sit well above it: o-504, placed 19:04:20 and arrived 19:08:40; o-507, placed 19:04:50 and arrived 19:12:30; o-510, placed 19:09:10 and arrived 19:14:00. A dashed line one minute above the diagonal is the watermark; the three late orders are above it, which means the watermark had already passed the time they were placed when they arrived. Vertical lines mark the five-minute windows at 19:05 and 19:10.\" data-fig=\"gcp22-clocks\"><line x1=\"90.0\" y1=\"40\" x2=\"90.0\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line><text x=\"90.0\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:00</text><text x=\"82\" y=\"300.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:00</text><line x1=\"270.0\" y1=\"40\" x2=\"270.0\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line><text x=\"270.0\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:05</text><text x=\"82\" y=\"213.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:05</text><line x1=\"450.0\" y1=\"40\" x2=\"450.0\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line><text x=\"450.0\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:10</text><text x=\"82\" y=\"126.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:10</text><line x1=\"630.0\" y1=\"40\" x2=\"630.0\" y2=\"300\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line><text x=\"630.0\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:15</text><text x=\"82\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19:15</text><line x1=\"90\" y1=\"300\" x2=\"630\" y2=\"300\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"90\" y1=\"300\" x2=\"90\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"360\" y=\"330\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">placed: event time</text><text x=\"30\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">arrived: processing time</text><line x1=\"90.0\" y1=\"282.7\" x2=\"594.0\" y2=\"40.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" stroke-dasharray=\"5 3\"></line><text x=\"625\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">watermark, one minute behind the latest arrival</text><circle cx=\"132.0\" cy=\"279.2\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"165.0\" cy=\"263.6\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"216.0\" cy=\"239.0\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"246.0\" cy=\"149.8\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"254.0\" y=\"149.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">o-504</text><circle cx=\"306.0\" cy=\"195.4\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"369.0\" cy=\"165.4\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"264.0\" cy=\"83.3\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"272.0\" y=\"83.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">o-507</text><circle cx=\"495.0\" cy=\"104.7\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"582.0\" cy=\"62.8\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"none\"></circle><circle cx=\"420.0\" cy=\"57.3\" r=\"4\" fill=\"var(--amber)\" stroke=\"none\"></circle><text x=\"428.0\" y=\"57.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">o-510</text><text x=\"102\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">late: placed before the watermark had already passed</text></svg>", "caption": "The same ten orders on two clocks. A window is a strip between two vertical lines; a point above the dashed watermark reached the pipeline after the pipeline had stopped expecting it."}
```

**A batch over a file has no difficulty here**, because it has every order before it starts: it can
wait for `o-507` because `o-507` is already in the file. A stream does not know whether an order
placed at 19:04 is still on its way, and at some point it has to publish the 19:00 window anyway.
The point at which it decides is the watermark, two sections on.
