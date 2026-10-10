---
title: Reading what clients report
version: 1
---

A report button is only worth the reports somebody reads. Ten reports from one week, **written by the
course**; each names the call it is about and the prompt version that call used, as lesson 20 logs
them, and a reason the client chose from four. With them, the number of calls each version served
that week. Paste both:

```sh
cat > ~/guard/data/reports.jsonl <<'EOF'
{"id": "r1", "day": "2026-10-05", "call": "c1043", "version": "aa32449d3f", "reason": "wrong", "text": "It sent my question about a late logo to the wrong queue."}
{"id": "r2", "day": "2026-10-05", "call": "c1107", "version": "06390ce0eb", "reason": "wrong", "text": "I got a poem instead of an answer."}
{"id": "r3", "day": "2026-10-06", "call": "c1122", "version": "06390ce0eb", "reason": "other", "text": "Why is the assistant writing poetry?"}
{"id": "r4", "day": "2026-10-06", "call": "c1130", "version": "06390ce0eb", "reason": "privacy", "text": "The reply repeated my whole message back, with my CPF in it."}
{"id": "r5", "day": "2026-10-06", "call": "c1131", "version": "06390ce0eb", "reason": "wrong", "text": "It thanked me for my patience and answered nothing."}
{"id": "r6", "day": "2026-10-07", "call": "c1188", "version": "aa32449d3f", "reason": "harmful", "text": "The reply called the freelancer lazy."}
{"id": "r7", "day": "2026-10-07", "call": "c1190", "version": "06390ce0eb", "reason": "wrong", "text": "Another poem."}
{"id": "r8", "day": "2026-10-08", "call": "c1201", "version": "06390ce0eb", "reason": "wrong", "text": "The answer was in capital letters and made no sense."}
{"id": "r9", "day": "2026-10-08", "call": "c1250", "version": "aa32449d3f", "reason": "wrong", "text": "It said my refund would take 30 days; the help page says 7."}
{"id": "r10", "day": "2026-10-08", "call": "c1262", "version": "aa32449d3f", "reason": "other", "text": "Can I change my e-mail address here?"}
EOF
cat > ~/guard/data/calls-per-version.json <<'EOF'
{"aa32449d3f": 1800, "06390ce0eb": 200}
EOF
```

The triage puts each report in a queue by its reason, and then counts reports per thousand calls of
each version. Save it as `~/guard/tools/reports.py`:

```python
# reports.py: what clients reported about the assistant's replies, triaged.
#
#   guard reports FILE
#
# Each report names the call it is about and the prompt version that call
# used, as lesson 20 logs them, and a reason the client picked. The reason
# decides the queue and how soon a person looks:
#
#   harmful  urgent, within the hour
#   privacy  privacy, the same day
#   wrong    quality, the weekly review
#   other    support, as a normal ticket
#
# Then the reports per thousand calls of each prompt version, with the call
# counts in data/calls-per-version.json: a version that draws far more
# reports than the others is a finding, whatever each report says.
import argparse
import json
import os

QUEUES = [("harmful", "urgent", "within the hour"), ("privacy", "privacy", "the same day"),
          ("wrong", "quality", "weekly review"), ("other", "support", "normal ticket")]

p = argparse.ArgumentParser(prog="guard reports")
p.add_argument("file")
a = p.parse_args()
with open(a.file, encoding="utf-8") as f:
    reports = [json.loads(line) for line in f]
with open(os.path.expanduser("~/guard/data/calls-per-version.json"), encoding="utf-8") as f:
    calls = json.load(f)

for reason, queue, when in QUEUES:
    for r in reports:
        if r["reason"] == reason:
            print("%-4s %-8s %-8s %-16s %s %s" % (r["id"], reason, queue, when, r["call"], r["text"][:44]))
print()
print("%-11s %6s %8s %10s" % ("version", "calls", "reports", "per 1000"))
for version, n in calls.items():
    k = sum(1 for r in reports if r["version"] == version)
    print("%-11s %6d %8d %10.1f" % (version, n, k, 1000 * k / n))
```

```
ana@lab:~/guard$ guard reports data/reports.jsonl
r6   harmful  urgent   within the hour  c1188 The reply called the freelancer lazy.
r4   privacy  privacy  the same day     c1130 The reply repeated my whole message back, wi
r1   wrong    quality  weekly review    c1043 It sent my question about a late logo to the
r2   wrong    quality  weekly review    c1107 I got a poem instead of an answer.
r5   wrong    quality  weekly review    c1131 It thanked me for my patience and answered n
r7   wrong    quality  weekly review    c1190 Another poem.
r8   wrong    quality  weekly review    c1201 The answer was in capital letters and made n
r9   wrong    quality  weekly review    c1250 It said my refund would take 30 days; the he
r3   other    support  normal ticket    c1122 Why is the assistant writing poetry?
r10  other    support  normal ticket    c1262 Can I change my e-mail address here?

version      calls  reports   per 1000
aa32449d3f    1800        4        2.2
06390ce0eb     200        6       30.0
```

## The queue is chosen by what could be at stake

`r6` goes first, though it arrived late in the week: a reply that insulted a freelancer is published
harm, and it is looked at within the hour. `r4` is next, the same day: a client says the reply
repeated their message with their CPF in it, which is personal data in a place it should not be, and
possibly lesson 11's log, lesson 12's provider and lesson 5's filter all at once. The six `wrong`
reports wait for the weekly review, because a wrong answer costs the client time, and the review is
where patterns show. The two `other` reports are ordinary support questions that arrived through the
button, and they are answered as such.

**The client chose the reason, and clients choose imprecisely.** `r2` and `r7` are filed as `wrong`
and are the same failure as `r3`, filed as `other`. A triage by the client's reason is a first sort,
and the person reading the queue moves a report when its reason is wrong, especially upwards.

## Counting by version finds what single reports cannot

The second table is the reason each report carries its version. Version `aa32449d3f` served 1,800
calls and drew four reports, 2.2 per thousand. Version `06390ce0eb` served 200 and drew six, **30 per
thousand, more than thirteen times the rate**. Read one at a time, the poems, the capital letters and
the "thank you for your patience" look like a model having odd days. Counted by version, they are one
change: `06390ce0eb` is the unreviewed prompt of lesson 20, and the reports found it in production
the way the build would have found it before.

Lesson 22 turns this into a number that is watched rather than read once a week, and lesson 24
decides what happens the day it jumps.
