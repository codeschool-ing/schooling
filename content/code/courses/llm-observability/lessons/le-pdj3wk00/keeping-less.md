---
title: Keeping the text for less time than the numbers
version: 2
---

The table at the start of this lesson gave the text and the numbers different lives: days for the
words people typed, months for the tokens, the times and the outcomes. Holding to that takes a job
that runs on a schedule and takes the text out of spans that have passed their date, leaving
everything else in place.

`expire.py` does it to the span file:

```python
"""expire.py: take what people typed out of spans older than --days, and keep everything else."""
import argparse
import json
import os
from datetime import datetime, timedelta

TEXT = ("app.question", "app.reply")
p = argparse.ArgumentParser()
p.add_argument("--now", required=True)
p.add_argument("--days", type=int, required=True)
p.add_argument("--spans", default="spans.jsonl")
a = p.parse_args()

since = datetime.fromisoformat(a.now) - timedelta(days=a.days)
cutoff = since.timestamp() * 1e9
spans, expired = [json.loads(line) for line in open(a.spans)], 0
for s in spans:
    if s["start"] < cutoff and any(k in s["attributes"] for k in TEXT):
        for k in TEXT:
            s["attributes"].pop(k, None)
        expired += 1
with open(a.spans + ".new", "w") as f:
    f.writelines(json.dumps(s, ensure_ascii=False) + "\n" for s in spans)
os.replace(a.spans + ".new", a.spans)
print(f"{len(spans)} spans; text removed from {expired}, every one that started before {since:%Y-%m-%d %H:%M}")
```

There is nothing old to expire yet. `replay.py` makes some: it plays the traffic file through the
assistant, with each request stamped at the moment the file gives it, and plays the simulated
customers' reactions by rules written at its top. Lesson 3 takes it apart and plays the whole week;
save it in `~/obs` now:

```python
"""replay.py: a week of data/traffic.jsonl through the assistant, in under an hour.

    python replay.py [--from 2026-09-28] [--to 2026-10-05] [--workers 1] [--processor MODULE:CLASS]

Each request runs for real: the embedding, the search, the streamed reply, all
measured. What is simulated is the calendar and the people. The calendar:
every span is stamped with the moment the traffic file gives its request, and
the durations inside it are the measured ones. The people: what a customer
does after reading a reply is decided by the rules below, which the course
wrote, with a generator seeded by the request's id so that a rerun decides
the same way. They are written down so that nobody mistakes them for a
measurement of how people behave.

  - A reply is RIGHT if it contains one of its topic's facts, or, for a topic
    the documents do not answer, if it contains the refusal.
  - 25% of customers rate a reply. A wrong reply gets a thumbs down 85% of the
    time; a right one gets a thumbs up 92% of the time.
  - After a wrong reply, 45% ask again in other words, 40 to 120 seconds
    later, in the same session. If that is wrong too, 60% ask for a person.
  - Summaries are for the support team, who do not rate them.

Feedback is appended to feedback.jsonl, keyed by the trace id of the reply it
is about.
"""
import argparse
import importlib
import json
import random
import threading
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta

import assistant
import telemetry

p = argparse.ArgumentParser()
p.add_argument("--traffic", default="data/traffic.jsonl")
p.add_argument("--from", dest="since", default="0000")
p.add_argument("--to", dest="until", default="9999")
p.add_argument("--workers", type=int, default=1)
p.add_argument("--spans", default="spans.jsonl")
p.add_argument("--processor", action="append", default=[], help="MODULE:CLASS, a span processor to add")
a = p.parse_args()

TOPICS = json.load(open("data/topics.json"))
LOCK = threading.Lock()
counts = {"requests": 0, "errors": 0, "feedback": 0}


def right(reply, topic):
    facts = TOPICS[topic - 1]["facts"]
    if not facts:
        return assistant.REFUSAL in reply
    return any(f.lower() in reply.lower() for f in facts)


def record(**row):
    with LOCK, open("feedback.jsonl", "a") as f:
        f.write(json.dumps(row) + "\n")
        counts["feedback"] += 1


def one(row, at, text):
    """Ask, as if at AT; (reply, trace id), or (None, None) if the assistant failed."""
    t = datetime.fromisoformat(at)
    token = telemetry.OFFSET_NS.set(int(t.timestamp() * 1e9) - telemetry.time.time_ns())
    try:
        reply, _, trace_id = assistant.ask(text, user=row["user"], session=row["session"],
                                           feature=row["feature"], at=at)
        return reply, trace_id
    except Exception:
        with LOCK:
            counts["errors"] += 1
        return None, None
    finally:
        telemetry.OFFSET_NS.reset(token)
        with LOCK:
            counts["requests"] += 1


def person(row):
    rng = random.Random(row["id"])
    reply, trace_id = one(row, row["at"], row["text"])
    if row["feature"] == "summary" or reply is None:
        return
    ok = right(reply, row["topic"])
    t = datetime.fromisoformat(row["at"])
    if rng.random() < 0.25:
        up = rng.random() < 0.92 if ok else rng.random() >= 0.85
        record(trace=trace_id, request=row["id"], at=(t + timedelta(seconds=rng.randrange(5, 30))).isoformat(),
               kind="thumbs", value="up" if up else "down")
    if ok or rng.random() >= 0.45:
        return
    t += timedelta(seconds=rng.randrange(40, 121))
    others = [x for x in TOPICS[row["topic"] - 1]["phrasings"] if x != row["text"]] or [row["text"]]
    again = rng.choice(others)
    record(trace=trace_id, request=row["id"], at=t.isoformat(), kind="rephrase", value=again)
    reply2, trace2 = one(row, t.isoformat(timespec="seconds"), again)
    if reply2 is not None and not right(reply2, row["topic"]) and rng.random() < 0.6:
        record(trace=trace2, request=row["id"], at=(t + timedelta(seconds=20)).isoformat(),
               kind="escalate", value="asked for a person")


telemetry.setup(a.spans, processors=[getattr(importlib.import_module(m), c)() for m, c in
                                     (x.split(":") for x in a.processor)])
rows = [r for r in map(json.loads, open(a.traffic)) if a.since <= r["at"] < a.until]
with ThreadPoolExecutor(a.workers) as pool:
    list(pool.map(person, rows))
print(f"replayed {len(rows)} requests from {a.traffic}: {counts['requests']} asked, "
      f"{counts['errors']} failed, {counts['feedback']} feedback events")
```

Here it plays the weekend, so there is something to expire:

```
ana@dev:~/obs$ rm -f spans.jsonl feedback.jsonl; python replay.py --from 2026-10-03 --to 2026-10-05
replayed 63 requests from data/traffic.jsonl: 70 asked, 0 failed, 18 feedback events
ana@dev:~/obs$ grep -c "app.question" spans.jsonl
70
ana@dev:~/obs$ python expire.py --now 2026-10-05T00:00 --days 1
366 spans; text removed from 36, every one that started before 2026-10-04 00:00
ana@dev:~/obs$ grep -c "app.question" spans.jsonl
34
```

Two days, 70 questions on root spans. With a day's life for the text, run at midnight on the Sunday
night, the 36 questions from Saturday lose their words and keep their place in every count. The span
is still there, with its feature, its release, its tokens, its duration and its outcome. Sunday's 34
keep their text until the next run.

## What a retention policy for traces looks like

| what | kept | why that long |
|---|---|---|
| spans without text: names, times, tokens, outcomes, scores | 13 months | a year of trend plus the month to compare it with |
| the question and the reply on a span | 7 days | long enough to debug a complaint and to sample for evaluation |
| a sample chosen for evaluation (lessons 9 and 13) | until the evaluation set is replaced | it becomes test data, with its own owner and its own review |
| the full prompt, sources included | not kept | the sources are in the database and the chunk ids on the span find them |

The numbers in that table are a starting point, not a rule anybody published. What makes it a policy
is that each line has a purpose and an end, and that the job enforcing it runs whether or not anybody
remembers it.

Two details decide whether it works. **Expiry rewrites, and some stores make that hard**: a tracing
backend built for appending may only be able to delete whole traces by age. Then the text belongs in
a separate store with its own, shorter retention, joined to the trace by its id. And **erasure has
to reach the text before expiry does**. A customer who asks the shop to delete what it holds about
them is owed that today, not in seven days. The pseudonym makes the request findable: hash their
user id with the key, delete the text on every span carrying that value, and the numbers stay in the
counts with nothing left to identify. `observability` lesson 10 has the same problem for logs and
reaches the same answer.