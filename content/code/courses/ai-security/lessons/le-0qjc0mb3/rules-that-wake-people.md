---
title: Rules that wake somebody only when they should
version: 1
---

A count nobody watches finds nothing. An alert is a rule that turns a count into a message to a
person, and it has two ways to fail: **staying quiet during an incident, and shouting when nothing is
wrong**. The second is as dangerous as the first, because a team paged every night for nothing learns
to sleep through pages.

Two sets of rules for the same two days, written by the course. Paste them:

```sh
cat > ~/guard/data/alerts.json <<'EOF'
{
 "naive": [
  {"metric": "rejects", "rate_above": 0.02, "severity": "page"}
 ],
 "tuned": [
  {"metric": "canary", "count_at_least": 1, "severity": "page"},
  {"metric": "rejects", "times_baseline": 3, "min_events": 5, "severity": "ticket"},
  {"metric": "denies", "times_baseline": 5, "min_events": 10, "severity": "page"}
 ]
}
EOF
```

The program replays every hour against a set and prints what would have fired. Save it as
`~/guard/tools/monitor.py`:

```python
# monitor.py: alert rules replayed over the assistant's hourly counts.
#
#   guard monitor FILE --rules naive|tuned
#
# The rules are in data/alerts.json. Three shapes of rule:
#
#   count_at_least  fires whenever the metric reaches the count; for events
#                   that should never happen, such as a canary in a reply
#   rate_above      fires when the metric divided by the hour's calls passes
#                   a fixed rate
#   times_baseline  fires when the metric passes N times its median over the
#                   previous 24 hours, and only when at least min_events
#                   happened, so that one event in a quiet hour is not news
#
# Each alert is a page (somebody is woken) or a ticket (somebody looks in
# working hours). The last line counts both.
import argparse
import json
import os
import statistics

p = argparse.ArgumentParser(prog="guard monitor")
p.add_argument("file")
p.add_argument("--rules", choices=["naive", "tuned"], required=True)
a = p.parse_args()

with open(os.path.expanduser("~/guard/data/alerts.json"), encoding="utf-8") as f:
    rules = json.load(f)[a.rules]
with open(a.file, encoding="utf-8") as f:
    hours = [json.loads(line) for line in f]

fired = {"page": 0, "ticket": 0}
for i, h in enumerate(hours):
    for r in rules:
        value = h[r["metric"]]
        why = None
        if "count_at_least" in r and value >= r["count_at_least"]:
            why = "%s = %d" % (r["metric"], value)
        if "rate_above" in r and h["calls"] and value / h["calls"] > r["rate_above"]:
            why = "%s %d of %d calls, %.1f%%" % (r["metric"], value, h["calls"], 100 * value / h["calls"])
        if "times_baseline" in r and i >= 24:
            base = statistics.median(x[r["metric"]] for x in hours[i - 24:i])
            if value >= r["min_events"] and value > r["times_baseline"] * max(base, 1):
                why = "%s = %d, baseline %g" % (r["metric"], value, base)
        if why:
            fired[r["severity"]] += 1
            print("%s  %-6s %s" % (h["hour"], r["severity"].upper(), why))
print("rules %s: %d pages, %d tickets in %d hours" % (a.rules, fired["page"], fired["ticket"], len(hours)))
```

## The obvious rule

`naive` has one rule, the one most teams write first: page when more than 2% of replies are refused.

```
ana@lab:~/guard$ guard monitor data/hourly.jsonl --rules naive
2026-10-07 03:00  PAGE   rejects 1 of 1 calls, 100.0%
2026-10-07 04:00  PAGE   rejects 1 of 1 calls, 100.0%
2026-10-08 03:00  PAGE   rejects 1 of 1 calls, 100.0%
2026-10-08 04:00  PAGE   rejects 1 of 1 calls, 100.0%
2026-10-08 10:00  PAGE   rejects 10 of 130 calls, 7.7%
2026-10-08 11:00  PAGE   rejects 11 of 140 calls, 7.9%
2026-10-08 12:00  PAGE   rejects 10 of 120 calls, 8.3%
rules naive: 7 pages, 0 tickets in 48 hours
```

**Seven pages, and four of them woke somebody at three and four in the morning** for one refused reply
out of one call. The rule saw 100% and fired, which was arithmetic, not an incident. And of the three
real incidents, it caught one: the refused replies from 10:00. The canary at 14:00 and the denied
calls at 16:00 were never measured at all, because nobody wrote a rule for them.

## Three rules, each shaped for its signal

`tuned` has a rule per signal, each a different shape:

```
ana@lab:~/guard$ guard monitor data/hourly.jsonl --rules tuned
2026-10-08 10:00  TICKET rejects = 10, baseline 1
2026-10-08 11:00  TICKET rejects = 11, baseline 1
2026-10-08 12:00  TICKET rejects = 10, baseline 1
2026-10-08 14:00  PAGE   canary = 1
2026-10-08 16:00  PAGE   denies = 30, baseline 0.5
2026-10-08 17:00  PAGE   denies = 30, baseline 0.5
rules tuned: 3 pages, 3 tickets in 48 hours
```

**All three incidents, and nothing else.** Each rule's shape fits what it watches:

- **the canary pages on the first one.** It is an event that should never happen, so a baseline is
  meaningless and one is enough;
- **refused replies open a ticket at three times their usual level**, the median of the previous 24
  hours, and only from five events up. That one condition removed the night-time pages: one refusal
  in a quiet hour is under five, whatever the rate;
- **denied tool calls page at five times their level, from ten events.** An agent pushed against the
  gate thirty times an hour is worth waking somebody for, because the gate is the last thing between
  the proposals and the tools.

The severities are decisions too. The format breaking is a ticket: clients see a person instead of an
answer, which costs time, not harm. A canary or a gate under pressure is a page, because the next step
of either is something lesson 24 has to clean up.
