---
title: Agreement, and agreement by chance
version: 2
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

```
ana@dev:~/obs$ python agree.py relevance-v1/ana relevance-v1/bruno
48 replies; rows relevance-v1/ana, columns relevance-v1/bruno
          pass  fail
  pass      31    17
  fail       0     0
agreement 64.6%   by chance 64.6%   kappa 0.00
apart on 17: 17 refusals, 0 other replies
  e04 2026.10.1  pass / fail  I could not find that in our documents.
  e05 2026.09.4  pass / fail  I could not find that in our documents.
  e05 2026.10.1  pass / fail  I could not find that in our documents.
  e12 2026.09.4  pass / fail  I could not find that in our documents.
  e12 2026.10.1  pass / fail  I could not find that in our documents.
  e14 2026.10.1  pass / fail  I could not find that in our documents.
  e19 2026.10.1  pass / fail  I could not find that in our documents.
  e20 2026.09.4  pass / fail  I could not find that in our documents.
  e20 2026.10.1  pass / fail  I could not find that in our documents.
  e21 2026.09.4  pass / fail  I could not find that in our documents.
  e21 2026.10.1  pass / fail  I could not find that in our documents.
  e22 2026.09.4  pass / fail  I could not find that in our documents.
  e22 2026.10.1  pass / fail  I could not find that in our documents.
  e23 2026.09.4  pass / fail  I could not find that in our documents.
  e23 2026.10.1  pass / fail  I could not find that in our documents.
  e24 2026.09.4  pass / fail  I could not find that in our documents.
  e24 2026.10.1  pass / fail  I could not find that in our documents.
```

**They agree on 31 of the 48 replies, 64.6%, and chance alone would give exactly that.** Kappa is
0.00: two people reading the same replies against the same sentence agreed on two thirds of them, and
not one agreement more than if one of them had written verdicts without looking. Neither was careless.
The table says why: Ana passed every reply, and when one rater never says fail, every agreement is the
free kind.

**All seventeen disagreements are the refusal.** Ana read "does the reply address the question" as "is
it about the question", and a reply saying the documents have no answer is about the question. Bruno
read it as "does it answer", and a refusal answers nothing. Both readings are reasonable, and version 1
does not choose between them. Notice that both of them passed every reply that did answer, including
e02 under the new release, which tells the customer they pay the return postage when they do not.
Neither reading of version 1 asks whether a reply is true, and neither should: that is faithfulness.

## What the number is for

A kappa of zero says nothing about the replies and everything about the rubric: **the labels cannot be
used as a reference**, because a third person would agree with Ana or with Bruno depending on how they
happened to read one sentence. Measuring the judge against either set would measure the judge against
a coin.

There are tables that name ranges of kappa, "slight", "moderate", "substantial", and they are
conventions rather than results. What matters in practice is the comparison: kappa between people is
the practical ceiling for kappa between the judge and people. When two people only half agree, a judge
that matches one of them is matching a reading of the rubric, not the rubric.
