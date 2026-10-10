---
title: Cost per feature
version: 2
---

A bill with one number on it says how much and never why. The first cut that explains anything is by
**feature**, because a feature is something somebody decided to build and can decide to change.
`bill.py` groups the week's requests by any field of the root span:

```python
"""bill.py: the week's cost, grouped by one field of the request."""
import argparse
from collections import defaultdict
from decimal import Decimal

import costs

p = argparse.ArgumentParser()
p.add_argument("--by", default="feature", choices=["feature", "user", "day", "release", "outcome"])
p.add_argument("--top", type=int)
a = p.parse_args()

rows = costs.requests()
key = (lambda r: r["at"].strftime("%a %d")) if a.by == "day" else (lambda r: r[a.by])
groups = defaultdict(list)
for r in rows:
    groups[key(r)].append(r)
total = sum((r["cost"] for r in rows), Decimal(0))
spend = {g: sum((r["cost"] for r in rs), Decimal(0)) for g, rs in groups.items()}
order = list(groups) if a.by == "day" else sorted(groups, key=lambda g: -spend[g])
print(f"{a.by:18} {'requests':>8} {'input':>8} {'output':>7} {'cost US$':>9} {'per 1k':>7} {'share':>6}  features")
for g in order[:a.top]:
    rs = groups[g]
    features = "/".join(sorted({r["feature"] for r in rs}))
    print(f"{str(g):18} {len(rs):8} {sum(r['input'] for r in rs):8} {sum(r['output'] for r in rs):7} "
          f"{spend[g]:9.4f} {spend[g] / len(rs) * 1000:7.2f} {spend[g] / total:6.1%}  {features}")
print(f"{'total':18} {len(rows):8} {sum(r['input'] for r in rows):8} {sum(r['output'] for r in rows):7} "
      f"{total:9.4f} {total / len(rows) * 1000:7.2f}")
```

```
ana@dev:~/obs$ python bill.py --by feature
feature            requests    input  output  cost US$  per 1k  share  features
help                    207    36359    4192    0.0896    0.43  62.5%  help
order                    68    13491    2262    0.0378    0.56  26.4%  order
summary                  36     3390    1551    0.0160    0.44  11.1%  summary
total                   311    53240    8005    0.1434    0.46
```

The `help` feature is 62% of the cost and 67% of the requests: no surprise. Per request, `order` is
the dearest, 0.56 dollars per thousand against 0.43 and 0.44, because a customer writing about their
own order writes more, and every word of it goes into the prompt. The support team's summaries were
expected to be the expensive ones, because they send a whole conversation, and they cost about what a
help question does: the conversations in this week are three or four lines long and the summaries are
at most forty words. The guess was about conversations in general, the measurement about these
ones.

**A cost per feature is the number a product decision is made with.** "The assistant costs 0.14 a
week" invites nothing. "Order questions cost a third more each than help questions" invites a
conversation about whether the order feature should exist in this form, which the next lessons will
have.

## An average hides a spread

`spread.py` looks inside each feature at the cost of a single request:

```python
"""spread.py: how the cost of one request is distributed, per feature."""
from collections import defaultdict

import costs

by = defaultdict(list)
for r in costs.requests():
    by[r["feature"]].append(r["cost"] * 1_000_000)
print(f"{'feature':8} {'requests':>8} {'no model call':>13}   cost of one request in millionths of a dollar")
print(f"{'':8} {'':>8} {'':>13}   {'min':>6} {'median':>6} {'p95':>6} {'max':>6}")
for feature, c in by.items():
    c.sort()
    pick = lambda q: c[min(len(c) - 1, int(q * len(c)))]
    free = sum(1 for x in c if x < 100)
    print(f"{feature:8} {len(c):8} {free:13}   {c[0]:6.0f} {pick(0.5):6.0f} {pick(0.95):6.0f} {c[-1]:6.0f}")
```

```
ana@dev:~/obs$ python spread.py
feature  requests no model call   cost of one request in millionths of a dollar
                                     min median    p95    max
summary        36             0      374    436    582    582
order          68             8        1    563    940   1172
help          207            38        0    428    939   1268
```

**The minimum is zero, or one,** in two features because of the refusals lesson 1 found. When
nothing clears the floor, the assistant answers without calling the model, and the request costs
only its embedding, a fraction of a millionth. 38 of the 207 help requests and 8 of the 68 order
requests cost nothing in model tokens. A summary always calls the model, so its minimum is 374.

**The 95th percentile is twice the median** in `help`, and well above it in `order`, and it is not the
answer that makes it so. A request with three sources in its prompt pays for three chunks of text; a
request with one pays for one. The cost of a request is set mostly by **how much was retrieved**, which
is `k` and the floor, settings in `releases.json` that nobody would think of as a cost decision.
