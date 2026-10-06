---
title: A week of latency, in percentiles
version: 1
---

`latency.py` takes every successful model call of the replayed week, and every request, and prints
the three clocks as percentiles:

```python
"""latency.py: the week's successful model calls and requests, as percentiles."""
import json

spans = [json.loads(line) for line in open("spans.jsonl")]
chats = [s for s in spans if s["name"].startswith("chat ") and s["status"] != "ERROR"]
asks = [s for s in spans if s["name"] == "ask"]
ms = lambda s: (s["end"] - s["start"]) / 1e6
ttft = lambda s: s["attributes"]["app.time_to_first_token_ms"]
per_token = lambda s: (ms(s) - ttft(s)) / max(s["attributes"]["gen_ai.usage.output_tokens"] - 1, 1)
rows = {"whole request": [ms(s) for s in asks], "model call": [ms(s) for s in chats],
        "first token": [ttft(s) for s in chats], "each token after": [per_token(s) for s in chats]}
print(f"{'':17} {'n':>5} {'mean':>6} {'p50':>6} {'p90':>6} {'p95':>6} {'p99':>6} {'max':>6}   ms")
for name, xs in rows.items():
    xs.sort()
    q = lambda p: xs[min(len(xs) - 1, int(p * len(xs)))]
    print(f"{name:17} {len(xs):5} {sum(xs) / len(xs):6.0f} {q(.5):6.0f} {q(.9):6.0f} {q(.95):6.0f} {q(.99):6.0f} {xs[-1]:6.0f}")
```

```
ana@lab:~/obs$ python replay.py
replayed 1127 requests from data/traffic.jsonl: 1345 asked, 0 failed, 483 feedback events
ana@lab:~/obs$ python latency.py
                      n   mean    p50    p90    p95    p99    max   ms
whole request      1345   1253   1056   2541   2962   4846   6343
model call         1108   1438   1324   2591   3045   4862   6282
first token        1108    353    290    399    444   4257   4460
each token after   1108     26     26     35     38     48     54
```

## Why not the mean

Read the `first token` row. The median is 290 ms and the 95th percentile 444: nineteen calls in
twenty saw the first token in under half a second. Then **the 99th percentile is 4,257 ms** and the
maximum 4,460. One call in a hundred waited almost ten times as long as a typical one. The mean, 353,
sits between the two and describes nobody: it is too high for the typical call and absurdly low for
the slow one.

That shape, a tight body and a long thin tail, is what latency looks like nearly everywhere, and it is
why latency is reported in percentiles. `observability` lesson 6 builds the histograms that make
percentiles cheap to compute at scale; here a sorted list of a thousand numbers is enough.

The tail is labobs' **cold start**: with a probability of one in a hundred, a request waits four extra
seconds before its first token. A real provider's tail has other causes, a request routed to a busy
machine, a model being loaded, a long queue at the hour everybody's batch jobs start, and the same
look in a percentile table.

## Which percentile to watch

**p50** says what most people see, and moves when something changes for everybody, a new model, a
longer prompt. **p95 and p99** say what the unlucky see, and they are where a provider's bad afternoon
shows first. A customer who asks ten questions in a session has a one-in-ten chance of meeting a p99
call at least once, so the 99th percentile is not a rare customer, it is a rare *call* in a common
session.

The `whole request` row is the model call plus everything around it, and its tail is the same tail,
from the same cause, because the model is nearly all of it. The `each token after` row is the second
clock: 26 ms at the median, 48 at p99. It varies far less than the first token, and that is
characteristic: what is slow and unpredictable is getting started.
