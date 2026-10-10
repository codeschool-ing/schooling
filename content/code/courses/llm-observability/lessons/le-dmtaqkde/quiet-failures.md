---
title: The failures that are answers
version: 2
---

Lesson 4 counted errors: requests the provider refused and requests the customer saw fail. In this week
there were none, and that is the least informative number in the lesson. The assistant's failures are
mostly **answers**: a refusal to a question the documents answer, a reply that cites a source that
does not exist, a reply about the wrong thing. None of them raises an exception, so none of them is an
error to anything that counts errors. They have to be counted on purpose.

The assistant already records the outcome of every request (`app.outcome`) and how many of its
citations point at no source (`app.citations.dangling`). `outcomes.py` counts both per feature and
release:

```python
"""outcomes.py: what the requests ended as, per feature and release."""
import json
from collections import Counter, defaultdict

import costs

rows = costs.requests()
dangling = {s["trace"] for s in map(json.loads, open("spans.jsonl"))
            if s["name"] == "check_citations" and s["attributes"]["app.citations.dangling"]}
by = defaultdict(Counter)
for r in rows:
    by[r["feature"], r["release"]][r["outcome"] or "error"] += 1
    by[r["feature"], r["release"]]["dangling"] += r["trace"] in dangling
print(f"{'feature':8} {'release':10} {'requests':>8} {'answered':>9} {'refused':>8} {'refused %':>9} {'dangling':>8}")
for (feature, release), c in sorted(by.items()):
    n = sum(v for k, v in c.items() if k != "dangling")
    print(f"{feature:8} {release:10} {n:8} {c['answered'] + c['summarised']:9} {c['refused']:8} "
          f"{c['refused'] / n:9.0%} {c['dangling']:8}")
```

```
ana@dev:~/obs$ python outcomes.py
feature  release    requests  answered  refused refused % dangling
help     2026.09.4       102        80       22       22%        0
help     2026.10.1       105        62       43       41%        0
order    2026.09.4        32        23        9       28%        0
order    2026.10.1        36        22       14       39%        0
summary  2026.09.4        16        16        0        0%        0
summary  2026.10.1        20        20        0        0%        0
```

**No dangling citations all week.** `llama3.2:3b` cited only sources it was given, in every one of
its 265 answers. That is worth knowing and worth checking again after every change of model or
prompt: a model given three sources and inventing a `[4]` is a known failure, and this column is the
only place it would show.

**The refusal rate rose with the release, in both features.** Help went from 22% refused to **41%**:
under the new floor, two in five customers asking a question were told the documents had nothing for
them. Order went from 28% to 39%. A refusal is the right answer to a question the documents do not
answer, and four topics in this week's traffic are like that. It is the wrong answer to the rest. A
rate is not right or wrong by itself, but a rate that jumps on the day of a release is a release
that changed what customers get.

**And the order feature refused more than help even before.** 28% under the old floor, against 22%.
The next section finds out why, from two traces.