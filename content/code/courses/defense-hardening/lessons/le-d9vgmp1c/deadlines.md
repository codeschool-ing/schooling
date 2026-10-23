---
title: Deadlines, and the exceptions to them
version: 1
---

**Each level of the policy has a number of days, and the due date is counted from the day the
finding was made.** The days in `prioritise.py` are Jatobá's choice: seven for a flaw being exploited
now, thirty for one likely to be or reachable from the network, sixty for a severe one that is not,
ninety for the rest. They are in the same range as published ones. CISA's directive for US federal
agencies gives two weeks for most entries on its KEV list, and PCI DSS, the card-payment standard,
asks for critical patches within a month. A deadline nobody can meet is worse than a longer one,
because it teaches people that deadlines are decoration.

The arithmetic is the kind that goes wrong on paper, across month ends, so let a command do it:

```
ana@admin:~$ for d in 7 30 60 90; do date -d "2026-10-23 + $d days" +"%F  $d days"; done
2026-10-30  7 days
2026-11-22  30 days
2026-12-22  60 days
2027-01-21  90 days
```

## Why from the day it was found

A due date counted from the day somebody reads the report moves every time the report is printed
again. Counted from the day of the finding, it stays where it was, and a report run in November says
plainly that something found in October is late. **The date of the finding is part of the finding**,
recorded when the scanner or the script first reports it, and kept.

## What happens on the date

Three things can be true when a due date arrives, and each needs a different response:

| state | what happens |
|---|---|
| fixed, and verified by the same check that found it | closed, with the date it closed |
| not fixed, and nobody decided anything | it is overdue: it goes to whoever owns the machine's risk, by name, and stays on the report until it closes |
| not fixable yet: no patch, or the patch breaks the portal | an **exception**, written down before the date, not after |

## An exception is a decision with an expiry

Sometimes the fix cannot happen by the date. The vendor has not shipped one, or lesson 17's testing
finds that it breaks something. What makes that acceptable is that somebody decides it, on purpose,
with a record a stranger could read:

| field | for the nginx finding, say |
|---|---|
| finding | JTB-2026-02, nginx on `web` |
| reason | the fixed package breaks the portal's proxy settings; vendor ticket open |
| compensating control | rate limit on port 80 at the edge, alert on nginx restarts |
| approved by | the person who owns the portal's risk, by name |
| expires | a date, after which the exception is void and the finding is overdue again |

**An exception without an expiry is how a finding becomes permanent.** The compensating control
matters as much as the date: an exception says "we cannot fix this yet, so here is what we do
instead", and one that says only "we cannot fix this" is a risk accepted by default. Lesson 17 shows
the same idea in its own terms, as a package held back on purpose.

## What to measure

A vulnerability programme is judged by numbers that are easy to collect once the steps above exist:
how many findings are open past their due date, how long findings take to close at each level, and
how many exceptions are open and how many have expired. **Watch the overdue count, not the total.**
The total rises every time a new advisory is published, which says nothing about the team; the
overdue count is the one the team controls.
