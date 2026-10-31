---
title: A counter made of matching lines
version: 1
---

**A log-based metric turns entries that match a filter into a time series.** A counter metric adds one
for every matching entry in each minute; nothing else about the entry is kept, except the labels you ask
it to extract. It is how a line of text a program already writes becomes something a chart can draw and an
alert can compare with a threshold, without anybody changing the program. **Nothing in this lesson reaches
Cloud Logging or Cloud Monitoring.** The counting below is done on your computer with `jq`, on a log a
program generates, to show what the metric would record; the metrics and the alert are a Terraform plan.

The program writes thirty minutes of the shop's checkout log, forty orders a minute, with a bad patch at the
payment provider in the middle. Write it into `~/gcp/genlogs.py`:

```python
# genlogs.py
"""genlogs.py: thirty minutes of the shop's checkout log, as JSON lines.

Seeded, so every run writes the same file. The payment provider has a bad
patch between minutes 12 and 17, and checkout retries more often there.
"""
import json
import random
from datetime import datetime, timedelta, timezone

rng = random.Random(11)
start = datetime(2026, 10, 30, 14, 0, tzinfo=timezone.utc)
for minute in range(30):
    bad = 12 <= minute < 18
    for _ in range(40):
        t = start + timedelta(minutes=minute, seconds=rng.randint(0, 59))
        entry = {"timestamp": t.isoformat(), "severity": "INFO",
                 "message": "order placed", "total_cents": rng.choice([1890, 2490, 4380, 6870])}
        if rng.random() < (0.30 if bad else 0.02):
            entry.update(severity="WARNING", message="payment retried",
                         provider=rng.choice(["card", "pix"]))
        print(json.dumps(entry))
```

```
ana@laptop:~/gcp$ python3 genlogs.py > checkout.log
ana@laptop:~/gcp$ wc -l checkout.log
1200 checkout.log
```

## What a counter on "payment retried" would record

The metric's filter would be `jsonPayload.message="payment retried"`. Counted per minute, which is what a
counter metric does with the entries it matches:

```
ana@laptop:~/gcp$ jq -r 'select(.message == "payment retried") | .timestamp[11:16]' checkout.log | sort | uniq -c
      2 14:00
      1 14:03
      1 14:04
      2 14:05
      1 14:07
      1 14:08
      1 14:10
      3 14:11
     12 14:12
     15 14:13
     18 14:14
     13 14:15
     16 14:16
     11 14:17
      1 14:19
      1 14:20
      1 14:21
      1 14:22
      1 14:25
      2 14:26
      1 14:27
      1 14:29
```

Read the column on the left as the metric's points. One or two retries a minute is the normal background;
from 14:12 to 14:17 it jumps to between 11 and 18, which is the incident. **Look also at what is missing**:
there is no line for 14:01, 14:02 or 14:06. A minute with no matching entry produces **no point at all**, not
a point of zero, and that difference decides how an alert on this metric behaves when everything is fine
(lesson 14 returns to it).

## Labels: the same count, split

A counter can extract labels from each entry, and every distinct value becomes its own series, as lesson 8
described. Splitting the retries by the payment method says whether the problem was one provider or both:

```
ana@laptop:~/gcp$ jq -r 'select(.message == "payment retried") | .provider' checkout.log | sort | uniq -c
     50 card
     56 pix
```

Both methods retried, in similar numbers, so the cause is upstream of either: the checkout's own call to the
payment service, rather than one provider failing. A label is worth extracting when its values answer a
question like that. **A label whose values are unbounded** (an order id, a user id, a URL with an id in it)
turns one metric into thousands of series, each billed and each slow to query, and is the commonest mistake
with log-based metrics.
