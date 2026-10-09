---
title: A week of latency, in percentiles
version: 2
---

`latency.py` takes every successful model call of the week lesson 3 replayed, which is still in
`spans.jsonl`, and every request, and prints the three clocks as percentiles:

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
ana@dev:~/obs$ python latency.py
                      n   mean    p50    p90    p95    p99    max   ms
whole request       311   3317   2962   6078   8447   9838  11164
model call          265   3721   3099   6022   8996   9684  11003
first token         265    744    748   1346   1431   1954   2190
each token after    265    102    101    109    110    120    123
```

## Why not the mean

Read the `model call` row. The median is 3,099 ms and the 95th percentile 8,996: nineteen calls in
twenty finished in under nine seconds, and the slowest took eleven. The mean, 3,721, sits above the
median, pulled up by the slow few, and describes nobody: it is too high for the typical call and far
too low for the slow one.

That shape, a body and a long thin tail to one side, is what latency looks like nearly everywhere,
and it is why latency is reported in percentiles. `observability` lesson 6 builds the histograms
that make percentiles cheap to compute at scale; here a sorted list of a few hundred numbers is
enough.

The tail here has one cause, and the next section finds it: **the long answers**. What it does not
have is the cause a production tail usually has. A model that has to be loaded into memory first, a
request routed to a busy machine, a queue at the hour everybody's batch jobs start: none of those
happened. The model never left memory during a week replayed in seventeen minutes, and nothing else
was asking. The last section of this lesson makes the first of them happen on purpose.

## Which percentile to watch

**p50** says what most people see, and moves when something changes for everybody, a new model, a
longer prompt. **p95 and p99** say what the unlucky see, and they are where a provider's bad afternoon
shows first. A customer who asks ten questions in a session has a one-in-ten chance of meeting a p99
call at least once, so the 99th percentile is not a rare customer, it is a rare *call* in a common
session.

The `whole request` row is the model call plus everything around it, and its tail is the same tail,
from the same cause, because the model is nearly all of it. The `each token after` row is the second
clock: 101 ms at the median, 120 at p99. It hardly varies at all, and that is characteristic of a
model with a machine to itself: once it has started, it writes at its own pace.