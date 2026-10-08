---
title: On every reply, in production
version: 2
---

A rule costs microseconds and no tokens, so it can run on **every** reply, not on a sample. Two places
to run it: on the evaluation run, before a change ships, and on the traffic, after.

`check_run.py` counts each check's passes over a run:

```python
"""check_run.py: every check in checks.py on every reply of a run, counted, and the failures listed."""
import json
import sys
from collections import Counter

import checks

run = [json.loads(line) for line in open(f"runs/{sys.argv[1]}.jsonl")]
failed, examples = Counter(), {}
for r in run:
    for name, ok, why in checks.run(r["reply"], r["sources"]):
        if not ok:
            failed[name] += 1
            examples.setdefault(name, f"{r['id']}: {why}")
for c in checks.CHECKS:
    print(f"{c.__name__:22} {len(run) - failed[c.__name__]:3}/{len(run)} pass   {examples.get(c.__name__, '')}")
```

```
ana@dev:~/obs$ python check_run.py current
cites_every_sentence    24/24 pass   
citations_exist         24/24 pass   
numbers_in_sources      24/24 pass   
no_personal_data        24/24 pass   
refusal_is_exact        24/24 pass   
short_enough            24/24 pass   
```

And `check_week.py` does the same over the replayed week, reading each reply from its root span and its
sources from the chunk ids on its search span, which find their text in
`data/index.json`. It prints one example of each kind of failure:

```python
"""check_week.py: the checks on every reply of the replayed week, from the spans, per release."""
import json
from collections import Counter, defaultdict

import checks

text = {c["id"]: c["text"] for c in json.load(open("data/index.json"))["chunks"]}
by_trace = defaultdict(dict)
for s in map(json.loads, open("spans.jsonl")):
    by_trace[s["trace"]][s["name"]] = s["attributes"]
seen, failed, example = Counter(), defaultdict(Counter), {}
for spans in by_trace.values():
    root = spans["ask"]
    if root["app.feature"] == "summary":
        continue
    sources = [{"id": c, "text": text[c]} for c in spans["search"].get("app.search.chunks", [])]
    release = root["app.release"]
    seen[release] += 1
    for name, ok, why in checks.run(root["app.reply"], sources):
        failed[release][name] += not ok
        if not ok:
            example.setdefault(name, f"{why}: {root['app.reply'][:70]}")
print(f"{'check':22}" + "".join(f"{r:>12}" for r in sorted(seen)))
for c in checks.CHECKS:
    print(f"{c.__name__:22}" + "".join(f"{failed[r][c.__name__]:6} fail" for r in sorted(seen)))
print(f"{'replies':22}" + "".join(f"{seen[r]:12}" for r in sorted(seen)))
for name, e in example.items():
    print(f"  {name}: {e}")
```

```
ana@dev:~/obs$ python check_week.py
check                    2026.09.4   2026.10.1
cites_every_sentence      21 fail    18 fail
citations_exist            0 fail     0 fail
numbers_in_sources        16 fail    14 fail
no_personal_data           0 fail     0 fail
refusal_is_exact           2 fail     0 fail
short_enough               0 fail     0 fail
replies                        134         141
  cites_every_sentence: 1 sentence(s) with no citation: According to [1], a standard parcel is considered lost when its tracki
  numbers_in_sources: not in any source: ['3']: According to [1], you can return a printed book within 30 days from de
  refusal_is_exact: not the agreed refusal: According to [1], "Returns are free: we e-mail you a prepaid label, an
```

**The twenty-four replies of the run pass everything. The week does not.** Of 275 replies to
customers, 39 have a sentence with no citation, 30 a number that is in no source, and two a refusal in
words of their own. The run and the week are the same assistant under the same rules; what differs is
what people typed. The evaluation set asks clean questions, and the week's customers wrote about their
own parcels and their own dates.

Read the examples, because each kind is a different finding:

- **The uncited sentences are the model reasoning about the customer.** "Since you received the book
  3 weeks ago, which is less than 30 days, you should be able to return it." Nothing in the documents
  says that, so there is nothing to cite, and 27 of the 39 are in `order` requests, the ones about a
  particular parcel. Whether Marginalia wants that sentence is a decision about the product, not a fact
  the rule can settle; the rule's job is to make the decision visible.
- **Most of the stray numbers are the customer's own.** Of the 30, 24 are a `3` or a `12` that the
  customer typed: "a book I got 3 weeks ago", "after 12 working days". They are false alarms, and the
  fix belongs in the rule: allow a number that appears in the question as well as in the sources.
- **The other six are the model's arithmetic, and it is wrong.** "It's been two weeks, which is
  equivalent to 14 working days." Two weeks are ten working days. The number came from nowhere, the
  rule caught it, and no customer reading the reply would have.
- **The two refusals in other words are one reply twice**, to the return-postage question: it says the
  customer pays, then "I could not find any information in [2] that contradicts this". The rule fired
  on the words, and the reply under them is the contradiction lesson 1 found.

That is what running a rule on every reply buys: not a score, a **list of places to look**, sorted by
kind. A rule with false alarms is fixed like any program, and a rule that is quiet on a clean set and
loud on real traffic is telling you where the set is too clean.

## Making a rule worth running

Two things make the list useful rather than ignored:

- **It is recorded where the trace is.** The result of each check goes on the trace as a score, as the
  thumbs did in lessons 6 and 7, with an annotator kind of `CODE`. A reply that fails a check is then
  one click from its prompt and sources.
- **Its rate is watched, not its single failures.** A steady few uncited sentences a day is the
  assistant's habit. A jump, starting on the day of a release, is lesson 16's alert: a new model
  version, a new prompt or a library upgrade can start breaking a rule overnight, and the rule is the
  alarm.

## What runs where

| | where | how often | what it costs |
|---|---|---|---|
| rules on the form | in the application, after each reply, or in a job over the traces | every reply | nothing measurable |
| comparison with an expected answer | on the evaluation set, before shipping | every change | the run itself |
| a model as judge (lesson 9) | on a sample of traffic, and on the evaluation set | a share of replies | a model call per reply judged |
| people (lesson 10) | on a smaller sample | weekly | hours |

The order of that table is the order of cost, and it is also the order of trust: the cheaper a check,
the less it can see, and the more of the traffic it can afford to look at.
