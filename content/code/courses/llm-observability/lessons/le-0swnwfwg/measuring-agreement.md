---
title: Agreement, and agreement by chance
version: 1
---

The obvious measure of two raters is how often they agree. It is misleading on its own, and the reason
is arithmetic. If both raters passed nine replies in ten without reading them, they would still agree
on most replies, because most of the time both would have written pass. **Some agreement is free**,
and how much depends only on how often each rater says each verdict.

**Cohen's kappa** takes the free part away. It compares the agreement observed with the agreement
two raters would reach by chance, writing their verdicts at their own rates with no connection
between them:

```
kappa = (observed − by chance) / (1 − by chance)
```

Kappa is 1 when they agree on everything, 0 when they agree exactly as often as chance would make them,
and below 0 when they agree less than that, which means they are systematically reading the rubric
in opposite ways. `agree.py` computes it for any two sets of labels, and lists the replies the two
sets disagree on, split by whether the reply is the agreed refusal:

```python
"""agree.py: how far two sets of relevance labels agree, beyond what chance alone would give.

    python agree.py relevance-v1/ana relevance-v1/bruno
    python agree.py relevance-v2/agreed judge

A set is RUBRIC/RATER from data/labels.jsonl, or `judge`, the verdicts
judge_runs.py wrote. A reply is named by its question's id and the release
that wrote it, never by its position in a file.
"""
import json
import sys
from collections import Counter

import checks


def kappa(a, b):
    """Cohen's kappa: the agreement observed, the agreement chance would give, and how far beyond it."""
    n = len(a)
    observed = sum(x == y for x, y in zip(a, b)) / n
    ca, cb = Counter(a), Counter(b)
    expected = sum(ca[k] * cb[k] for k in ca) / n / n
    return observed, expected, (observed - expected) / (1 - expected)


def load(name):
    if name == "judge":
        return {(r["case"], r["release"]): r["label"] for r in map(json.loads, open("runs/judged.jsonl"))}
    rubric, rater = name.split("/")
    return {(r["case"], r["release"]): r[rubric][rater] for r in map(json.loads, open("data/labels.jsonl"))}


replies = {(r["id"], r["release"]): r["reply"] for run in ("old", "new") for r in map(json.loads, open(f"runs/{run}.jsonl"))}
left, right = load(sys.argv[1]), load(sys.argv[2])
keys = sorted(left)
assert keys == sorted(right) == sorted(replies), "the two sets do not label the same replies"
a, b = [left[k] for k in keys], [right[k] for k in keys]
observed, expected, k = kappa(a, b)
cells = Counter(zip(a, b))
print(f"{len(keys)} replies; rows {sys.argv[1]}, columns {sys.argv[2]}")
print("          pass  fail")
for x in ("pass", "fail"):
    print(f"  {x}  {cells[x, 'pass']:6}{cells[x, 'fail']:6}")
print(f"agreement {observed:.1%}   by chance {expected:.1%}   kappa {k:.2f}")
apart = [key for key in keys if left[key] != right[key]]
refusals = [key for key in apart if checks.is_refusal(replies[key])]
print(f"apart on {len(apart)}: {len(refusals)} refusals, {len(apart) - len(refusals)} other replies")
for key in apart:
    print(f"  {key[0]} {key[1]}  {left[key]} / {right[key]}  {replies[key][:58]}")
```

## Version 1

CAPTURE:v1

**They agree on 31 of the 60 replies, 51.7%, and chance alone would give 45.7%.** Kappa is 0.11: two
people reading the same replies against the same sentence agreed barely more than if one of them had
written verdicts without looking. Neither of them was careless. The table says where it went wrong:
Ana passed almost everything, 56 of 60, and Bruno passed fewer than half.

**Twenty-four of the twenty-nine disagreements are the refusal.** Ana read "does the reply address the
question" as "is it about the question", and a reply saying the documents have no answer is about the
question. Bruno read it as "does it answer", and a refusal answers nothing. Both readings are
reasonable, and version 1 does not choose between them.

The other five are two kinds of reply that sit on the boundary of the same sentence:

- **e02 under the old release**: asked who pays for return postage, the reply talks about keeping the
  post office receipt. It is about returns postage, and it does not say who pays.
- **e06 under both releases**: asked how much express delivery costs, the reply says it is not free at
  any order value. On the subject; not the price.
- **e05 under both releases**: asked whether an e-book downloaded yesterday can be refunded, the reply
  says an e-book can be refunded if it has not been downloaded. The answer is in it, but the customer
  has to work it out.

## What the number is for

A kappa this low says nothing about the replies and everything about the rubric: **the labels cannot be
used as a reference**, because a third person would agree with Ana or with Bruno depending on how they
happened to read one sentence. Measuring the judge against either set would measure the judge against
a coin.

There are tables that name ranges of kappa, "slight", "moderate", "substantial", and they are
conventions rather than results. What matters in practice is the comparison: kappa between people is
the practical ceiling for kappa between the judge and people. When two people only half agree, a judge
that matches one of them is matching a reading of the rubric, not the rubric.
