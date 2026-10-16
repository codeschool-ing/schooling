---
title: The same answer by both roads
version: 1
---

There are now two ways to score a subscriber. The batch way of every earlier lesson is `predict_proba` on
a table read with `pd.read_csv`. The served way turns a row into JSON, sends it, checks it with
`Subscriber`, rebuilds a table of one line and only then gives it to the model. The served way is the
one the business uses, and the batch way is the one this course measured. **If they disagree, every
number in the course describes a model nobody is running.**

The name for that disagreement is **training–serving skew**, and it is one of the most common ways a
deployed model goes wrong without anybody seeing an error. It does not come from the model. It comes from
the road in: a type converted differently, a missing value spelt differently, a column computed by a
second piece of code that was meant to match the first. So the test is to send every subscriber of March
2026 down both roads and compare. With the server still running in the second terminal, save this as
`compare.py`:

```python
# compare.py
import json
import time
import urllib.request

import numpy as np

import stored
from feira import CREDIT, KEPT, SAVED, load_churn

model, card = stored.load("churn-2025-12")
new = load_churn("data/churn_2026.csv")
march = new[new["snapshot"] == "2026-03-01"]
start = time.perf_counter()
expected = model.predict_proba(march)[:, 1].round(4)
batch = time.perf_counter() - start


def ask(row):
    body = json.dumps(row).encode()
    request = urllib.request.Request("http://localhost:8000/score", body,
                                     {"content-type": "application/json"})
    with urllib.request.urlopen(request) as answer:
        return json.load(answer)["chance"]


rows = json.loads(march.drop(columns=["snapshot", "days_since_last_order"]).to_json(orient="records"))
start = time.perf_counter()
served = np.array([ask(row) for row in rows])
took = time.perf_counter() - start
print(f"one request per subscriber: {len(rows):,} requests, {1000 * took / len(rows):.1f} ms each")
print(f"the whole month in one call to the model: {1000 * batch:.0f} ms")
print(f"largest difference between the two: {np.abs(served - expected).max():.4f}")

cut = CREDIT / (SAVED * KEPT)
gaps = [i for i, row in enumerate(rows) if row["days_since_login"] is None]
zeros = np.array([ask({**rows[i], "days_since_login": 0}) for i in gaps])
print(f"{len(gaps):,} subscribers without the app, sent as 0 instead of null:")
print(f"  mean chance {served[gaps].mean():.3f} -> {zeros.mean():.3f}, "
      f"credits {(served[gaps] >= cut).sum()} -> {(zeros >= cut).sum()}")
```

`urllib.request` is the standard library's way of doing what `curl` did, so no new library is needed. It
takes about a minute, one request at a time.

```
ana@lab:~/ml$ python compare.py
one request per subscriber: 4,540 requests, 12.0 ms each
the whole month in one call to the model: 32 ms
largest difference between the two: 0.0000
1,133 subscribers without the app, sent as 0 instead of null:
  mean chance 0.071 -> 0.065, credits 52 -> 46
```

**The largest difference is zero**, to the four places the server rounds to. All 4,540 subscribers got
the same chance by both roads. That is not a formality: on the served road a `null` arrives as Python's
`None` rather than pandas's `NaN`, every number arrives through JSON, and each row is a table of its own.
This time, none of that changed an answer, and now that is known rather than assumed.

The last two lines are the skew this test exists to catch, made on purpose. **The 1,133 subscribers
without the app have no login, so `days_since_login` is `null`.** A client written by somebody who
thought a missing number should be 0, an assumption made in thousands of systems, sends 0 instead. To the
model, 0 means *logged in today*, the most engaged a subscriber can be. Their mean chance falls from 0.071
to 0.065 and six of them lose a credit. Nothing failed. Every request returned 200, every answer was a
plausible number, and the only place the change is visible is a comparison like this one.

Keep `compare.py`, or a test like it, and run it whenever the client, the server or the model changes.
**A deployed model is checked against the batch it was measured on, row by
row, not by looking at a few answers and finding them reasonable.**
