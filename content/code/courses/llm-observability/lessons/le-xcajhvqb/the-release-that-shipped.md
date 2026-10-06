---
title: The release that shipped
version: 1
---

`regress.py` compares two runs of the same set. It refuses runs that did not ask exactly the set's questions and grades every reply by lesson 8's facts and checks. Then it reports the cases that moved, the
checks that newly fail, and what the change did to tokens, money and time:

```python
"""regress.py: a candidate release against the current one, case by case, on the same evaluation set.

    python regress.py BASE CANDIDATE        # runs/BASE.jsonl and runs/CANDIDATE.jsonl
"""
import hashlib
import json
import math
import statistics
import sys

import checks
import costs
from facts import normalised

SET = "data/eval-v2.jsonl"
body = open(SET, "rb").read()
cases = {c["id"]: c for c in map(json.loads, body.decode().splitlines())}
spent = {r["trace"]: r for r in costs.requests("eval-spans.jsonl")}


def load(name):
    run = {r["id"]: r for r in map(json.loads, open(f"runs/{name}.jsonl"))}
    if {i: r["question"] for i, r in run.items()} != {i: c["question"] for i, c in cases.items()}:
        sys.exit(f"runs/{name}.jsonl did not ask the questions of {SET}: refusing to compare")
    return run


def grade(r):
    """Right by lesson 8's facts, and the set of lesson 8's checks the reply fails."""
    return normalised(r["reply"], cases[r["id"]]["facts"]), {n for n, ok, _ in checks.run(r["reply"], r["sources"]) if not ok}


def mcnemar(broken, fixed):
    """Exact two-sided p: how often chance alone would split this many changed verdicts at least this unevenly."""
    n = broken + fixed
    tail = sum(math.comb(n, k) for k in range(min(broken, fixed) + 1)) / 2 ** n
    return min(1.0, 2 * tail)


base_name, cand_name = sys.argv[1:3]
base, cand = load(base_name), load(cand_name)
release = lambda run: next(iter(run.values()))["release"]
print(f"{SET} sha256 {hashlib.sha256(body).hexdigest()[:12]}: {release(base)} -> {release(cand)}")
print("               both right  both wrong  fixed  broken")
moved = {"fixed": [], "broken": []}
for split in ("dev", "held-out"):
    count = dict.fromkeys(("both right", "both wrong", "fixed", "broken"), 0)
    for i, c in cases.items():
        if c["split"] != split:
            continue
        was, now = grade(base[i])[0], grade(cand[i])[0]
        key = "both right" if was and now else "both wrong" if not (was or now) else "fixed" if now else "broken"
        count[key] += 1
        if key in moved:
            moved[key].append(i)
    print(f"  {split:9} {count['both right']:12}{count['both wrong']:12}{count['fixed']:7}{count['broken']:8}")
print(f"exact McNemar p = {mcnemar(len(moved['broken']), len(moved['fixed'])):.4f}"
      f" on {len(moved['broken']) + len(moved['fixed'])} changed verdicts")
for key in ("broken", "fixed"):
    for i in moved[key]:
        print(f"  {key:6} {i} {cases[i]['split']:8} {cases[i]['question'][:56]}")
new_fails = [(i, sorted(grade(cand[i])[1] - grade(base[i])[1])) for i in cases]
print("checks newly failing:", ", ".join(f"{i} {n}" for i, ns in new_fails for n in ns) or "none")
print(f"replies changed: {sum(base[i]['reply'] != cand[i]['reply'] for i in cases)} of {len(cases)}")
for label, f in (("output tokens", lambda r: spent[r["trace"]]["output"]), ("cost US$", lambda r: spent[r["trace"]]["cost"]),
                 ("median ms", None)):
    if f is None:
        b, n = (statistics.median(spent[r["trace"]]["ms"] for r in run.values()) for run in (base, cand))
        print(f"{label:14} {b:10.0f} -> {n:10.0f}   {(n - b) / b:+.0%}")
    else:
        b, n = (sum(f(r) for r in run.values()) for run in (base, cand))
        print(f"{label:14} {b:10} -> {n:10}   {(n - b) / b:+.0%}")
```

The first comparison is history: the release of 2 October against the one before it, which is the test
nobody ran that week.

```
ana@lab:~/obs$ python regress.py 2026.09.4 2026.10.1
data/eval-v2.jsonl sha256 0d464ef783cd: 2026.09.4 -> 2026.10.1
               both right  both wrong  fixed  broken
  dev                 10          15      0       3
  held-out             8           4      0       2
exact McNemar p = 0.0625 on 5 changed verdicts
  broken e07 dev      Above what order value is standard delivery free?
  broken e17 dev      When is the contract of sale formed?
  broken e38 dev      My parcel MG-00000001 still hasn't arrived, two weeks no
  broken e24 held-out Do you store my IP address?
  broken e42 held-out right of withdrawal days
checks newly failing: none
replies changed: 12 of 42
output tokens         956 ->        637   -33%
cost US$       0.01821592 -> 0.00944242   -48%
median ms             701 ->         92   -87%
```

**Five cases broke, and none were fixed.** Three in development, two held out. Lesson 8 saw three of them only
as a total falling from 19 to 16; here all five are by name, with their questions, before a customer has
met any of them: the free-delivery threshold, the contract of sale, a lost parcel asked
about with an order number, the IP address, and the right of withdrawal asked in keywords.

**And everything else on the report looks like an improvement.** 33% fewer output tokens, 48% cheaper,
a median reply more than seven times faster. That is why a release like this ships. The floor makes the assistant
refuse more, and a refusal is short, costs no model call, and returns at once; a dashboard of cost and
latency would have congratulated the team. Only the cases say what the savings were made of.

That is the first rule of reading a regression report: **cost and latency are read beside the broken
cases, never instead of them**. A candidate that is faster and cheaper because it answers less is
a worse assistant with a smaller bill.
