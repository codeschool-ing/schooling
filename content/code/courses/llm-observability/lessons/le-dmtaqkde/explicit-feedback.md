---
title: Thumbs up and thumbs down
version: 2
---

The most direct quality signal there is: ask the customer. A thumb under every reply, up or down,
costs nothing to show and one click to give. In this week, **the customers are simulated**, and what
each one does after a reply is decided by rules `replay.py` states at its top:

```
  - A reply is RIGHT if it contains one of its topic's facts, or, for a topic
    the documents do not answer, if it contains the refusal.
  - 25% of customers rate a reply. A wrong reply gets a thumbs down 85% of the
    time; a right one gets a thumbs up 92% of the time.
  - After a wrong reply, 45% ask again in other words, 40 to 120 seconds
    later, in the same session. If that is wrong too, 60% ask for a person.
  - Summaries are for the support team, who do not rate them.
```

The numbers are the course's, chosen to look like what support teams report and not measured from
anybody. What the lesson measures is what the assistant answered and how those rules then add up.

## Joining a thumb to its reply

Each click is one line in `feedback.jsonl`, and it carries **the trace id of the reply it is about**,
which the screen received with the reply:

```
ana@dev:~/obs$ head -3 feedback.jsonl
{"trace": "a97ca428c676540ebab912432abec13c", "request": "r009", "at": "2026-09-28T09:29:35", "kind": "thumbs", "value": "up"}
{"trace": "9d3fe5c38cadad8bdb8f799e9374929c", "request": "r010", "at": "2026-09-28T09:40:12", "kind": "thumbs", "value": "up"}
{"trace": "2f467df1fd3622649fbdc311f53d6ddf", "request": "r011", "at": "2026-09-28T10:10:13", "kind": "thumbs", "value": "down"}
```

The join is exact, by id, as lesson 1 said it had to be: a customer who asked twice in a minute
gives two traces and a thumb on one of them. `signals.py` joins each line to its trace's release and
counts:

```python
"""signals.py: feedback joined to its trace by id, and counted per release."""
import json
from collections import Counter, defaultdict

import costs

release = {r["trace"]: r["release"] for r in costs.requests()}
asked = Counter(r["release"] for r in costs.requests() if r["feature"] != "summary")
seen = defaultdict(Counter)
for f in map(json.loads, open("feedback.jsonl")):
    seen[release[f["trace"]]][f["kind"] if f["kind"] != "thumbs" else "thumbs " + f["value"]] += 1
print(f"{'release':10} {'requests':>8} {'rated':>6} {'down':>5} {'down %':>7} {'rephrased':>9} {'person':>7}  per 100 requests")
for rel, c in sorted(seen.items()):
    rated = c["thumbs up"] + c["thumbs down"]
    print(f"{rel:10} {asked[rel]:8} {rated:6} {c['thumbs down']:5} {c['thumbs down'] / rated:7.0%} "
          f"{c['rephrase'] / asked[rel] * 100:9.1f} {c['escalate'] / asked[rel] * 100:7.1f}")
```

```
ana@dev:~/obs$ python signals.py
release    requests  rated  down  down % rephrased  person  per 100 requests
2026.09.4       134     32     5     16%       6.7     0.0
2026.10.1       141     26     4     15%      12.8     2.8
```

Under the old release, **16% of the thumbs were down**; under the new one, **15%**. On the thumbs
alone, the release that refused nearly twice as many help questions changed nothing, and that is
worth being careful with.

## What a thumb measures, and what it does not

**Few people rate.** 32 ratings under one release and 26 under the other, out of 134 and 141
requests: nine thumbs down in the whole week. At these sizes a difference of two or three thumbs is
noise, in either direction, and a dashboard showing a day's thumbs-down rate over five ratings will
jump about on noise alone. Lesson 9 puts a margin of error on a rate like this.

**The people who rate are not the people who ask.** Here they are a random quarter, because the rule
says so. In real products, people rate more when they are annoyed, or more when they are delighted,
and the mix moves with the screen: a thumb that is always visible gets a different crowd from one
that appears after a pause. A thumbs-down rate is a measure of the raters' experience, and it is
safe to compare between two releases of the same screen, not between two products.

**A thumb says something was wrong, not what.** A thumbs down on a refusal, on a wrong fact and on a
slow answer look the same. Its value is that it points at traces worth reading, and that it is
independent of anything the system thinks of itself.
