---
title: Keeping the text for less time than the numbers
version: 1
---

The table at the start of this lesson gave the text and the numbers different lives: days for the
words people typed, months for the tokens, the times and the outcomes. Holding to that takes a job
that runs on a schedule and takes the text out of spans that have passed their date, leaving
everything else in place.

`expire.py` does it to the lab's span file:

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

Lesson 3 explains `replay.py`, which plays the traffic file through the assistant with each request
stamped at the moment the file gives it. Here it plays the weekend, so there is something to expire:

```
ana@lab:~/obs$ rm -f spans.jsonl feedback.jsonl; python replay.py --from 2026-10-03 --to 2026-10-05
replayed 238 requests from data/traffic.jsonl: 296 asked, 0 failed, 124 feedback events
ana@lab:~/obs$ grep -c "app.question" spans.jsonl
296
ana@lab:~/obs$ python expire.py --now 2026-10-05T00:00 --days 1
1533 spans; text removed from 153, every one that started before 2026-10-04 00:00
ana@lab:~/obs$ grep -c "app.question" spans.jsonl
143
```

Two days, 296 questions on root spans. With a day's life for the text, run at midnight on the Sunday
night, the 153 questions from Saturday lose their words and keep their place in every count: the
span is still there, with its feature, its release, its tokens, its duration and its outcome. Sunday's
143 keep their text until the next run.

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
backend built for appending may only be able to delete whole traces by age, in which case the text
belongs in a separate store with its own, shorter retention, joined to the trace by its id. And
**erasure has to reach the text before expiry does**. A customer who asks the shop to delete what it
holds about them is owed that today, not in seven days. The pseudonym makes the request findable:
hash their user id with the key, delete the text on every span carrying that value, and the numbers
stay in the counts with nothing left to identify. `observability` lesson 10 has the same problem for
logs and reaches the same answer.
