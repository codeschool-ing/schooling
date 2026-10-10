---
title: Counters and labels
version: 2
---

A metrics system such as Prometheus does not read spans. It scrapes **counters**: numbers that only go
up, each with a set of **labels**, and computes rates from how fast they rise. `exposition.py` counts
the same week's replies into one counter and prints it in Prometheus's text format, which is what a
scrape would receive. Its library, `prometheus-client`, came into the environment with Phoenix in
lesson 7; if you skipped that lesson, install it:

```sh
pip install prometheus-client==0.26.0
```

```python
"""exposition.py: the same replies as the counters a metrics system scrapes, in Prometheus's text format."""
from prometheus_client import CollectorRegistry, Counter, disable_created_metrics, generate_latest

import replies

disable_created_metrics()   # a counter's creation time is now, not the week's: leave it out
registry = CollectorRegistry()
answers = Counter("assistant_replies", "Customer replies, by what kind of reply they were.",
                  ["feature", "release", "outcome"], registry=registry)
for r in replies.week():
    answers.labels(r["feature"], r["release"], "refused" if r["refused"] else "answered").inc()
print(generate_latest(registry).decode(), end="")
```

```
ana@dev:~/obs$ python exposition.py
# HELP assistant_replies_total Customer replies, by what kind of reply they were.
# TYPE assistant_replies_total counter
assistant_replies_total{feature="order",outcome="answered",release="2026.09.4"} 23.0
assistant_replies_total{feature="help",outcome="answered",release="2026.09.4"} 80.0
assistant_replies_total{feature="help",outcome="refused",release="2026.09.4"} 22.0
assistant_replies_total{feature="order",outcome="refused",release="2026.09.4"} 9.0
assistant_replies_total{feature="help",outcome="answered",release="2026.10.1"} 63.0
assistant_replies_total{feature="help",outcome="refused",release="2026.10.1"} 43.0
assistant_replies_total{feature="order",outcome="refused",release="2026.10.1"} 14.0
assistant_replies_total{feature="order",outcome="answered",release="2026.10.1"} 22.0
```

The labels are the dimensions lessons 3 and 5 broke everything down by: feature, release, outcome. A
dashboard divides one series by another to draw the refusal share per feature and per release, and
the order questions under 2026.10.1 come out at 14 refused of 36, the 39% lesson 5 found.

**What is never a label** matters as much. Each distinct combination of labels is a separate series
the metrics system stores for as long as it keeps anything, so a label with many values multiplies the
cost of everything:

- **Never the user or the session.** Thousands of values, and personal data in a system that lesson 2's
  rules never reached.
- **Never the question or the reply.** Unbounded values, and customers' words.
- **Never a trace id.** One series per request is a trace store built badly.

Those belong in the traces, where lesson 1 put them. The counter says how many, the label says of
which kind, and the trace says which one, with a link from the panel to the traces behind a point on it.

The `_created` series that this version of the client adds by default are switched off in the script:
they hold the time each counter was created, which here is the moment the script ran, not anything about
the week.
