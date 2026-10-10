---
title: Telling the ANPD, the people affected, and yourselves
version: 1
---

Lesson 12 named the rule: art. 48 of the LGPD requires the controller to tell the ANPD and the data
subjects about a security incident that may cause them relevant risk or damage, and Resolution
CD/ANPD nº 15 of 2024 sets the deadline at three working days. This section applies it to INC-7.

## Is it reportable?

Resolution 15 calls an incident relevant when two things hold. It may significantly affect the
subjects' interests and rights, **and** it involves at least one of a short list: sensitive data,
data of children, adolescents or older people, financial data, authentication data, data under legal
secrecy, or data at large scale. Two payment records, with a name, a CPF and an amount, read by an
unknown address, are financial data in the hands of somebody who took them on purpose. The course
reads INC-7 as reportable. **The decision is the encarregado's**, made on the day and written into
the timeline with its reasons, whichever way it goes: an incident judged not reportable still needs
the argument on record.

## The deadline, counted

Three working days is easy to miscount on a Friday. The holidays the count needs, written by the
course; paste them:

```sh
cat > ~/guard/data/holidays.txt <<'EOF'
# National holidays in Brazil for the rest of 2026, from federal law.
# State and city holidays are added by whoever runs this where they apply.
2026-10-12 Our Lady of Aparecida
2026-11-02 All Souls' Day
2026-11-15 Proclamation of the Republic
2026-11-20 Black Consciousness Day
2026-12-25 Christmas Day
EOF
```

Save the counter as `~/guard/tools/anpd.py`:

```python
# anpd.py: the deadline for telling the ANPD and the people affected.
#
#   guard anpd --known DATE [--days N]
#
# Resolution CD/ANPD nº 15 of 2024 gives three working days, counted from
# the day the controller learns that the incident affected personal data.
# The course counts that day as day zero and the next working day as day
# one. A working day here is Monday to Friday and not a national holiday in
# data/holidays.txt; a real deployment adds its state's and its city's.
import argparse
import datetime as dt
import os

p = argparse.ArgumentParser(prog="guard anpd")
p.add_argument("--known", required=True)
p.add_argument("--days", type=int, default=3)
a = p.parse_args()

holidays = {}
with open(os.path.expanduser("~/guard/data/holidays.txt"), encoding="utf-8") as f:
    for line in f:
        if line.strip() and not line.startswith("#"):
            day, name = line.rstrip("\n").split(" ", 1)
            holidays[dt.date.fromisoformat(day)] = name

day = dt.date.fromisoformat(a.known)
print("%s  %-9s day 0, the incident is known" % (day, day.strftime("%A")))
count = 0
while count < a.days:
    day += dt.timedelta(days=1)
    if day.weekday() >= 5:
        print("%s  %-9s not a working day" % (day, day.strftime("%A")))
    elif day in holidays:
        print("%s  %-9s not a working day: %s" % (day, day.strftime("%A"), holidays[day]))
    else:
        count += 1
        print("%s  %-9s working day %d" % (day, day.strftime("%A"), count))
print("deadline: the end of %s" % day)
```

```
ana@lab:~/guard$ guard anpd --known 2026-10-09
2026-10-09  Friday    day 0, the incident is known
2026-10-10  Saturday  not a working day
2026-10-11  Sunday    not a working day
2026-10-12  Monday    not a working day: Our Lady of Aparecida
2026-10-13  Tuesday   working day 1
2026-10-14  Wednesday working day 2
2026-10-15  Thursday  working day 3
deadline: the end of 2026-10-15
```

**Thursday 15 October, not Monday 12.** "Three days" counted on a calendar lands on a holiday; three
working days skip the weekend and Our Lady of Aparecida. The other mistake goes the opposite way:
the clock starts on the day Tarefa learned that personal data was affected, the Friday the blast
showed the two reads, not when the report is finished. Three days spent investigating before
deciding to notify is the whole deadline gone. When something is still unknown on day three, the
communication says so and is completed later; lateness is not the way to wait for certainty.

## What the communication says

Art. 48 §1 lists what goes in, and every item can be written from INC-7's file:

| art. 48 §1 asks for | for INC-7 |
|---|---|
| the nature of the personal data affected | name, CPF and amount of two payments |
| information on the subjects involved | two clients of Tarefa |
| the technical and security measures used to protect the data | a key with access to payment records; a canary in the system prompt; an alert on it |
| the risks related to the incident | fraud using the CPF, and messages to the clients that cite a real payment to look genuine |
| the reasons for any delay | none, if it goes by 15 October |
| the measures taken or to be taken to reverse or mitigate the effects | key revoked in 28 minutes; new key limited to refunds; prompt fixed; the clients told |

The clients are told within the same three working days, in plain words: what happened, which of
their data, what Tarefa did, and **what they can do**, which here is to distrust any message that
quotes their payment and asks for money or a code. A message that only apologises leaves them with
nothing to act on.

## The record, and the review

Resolution 15 also requires a record of every security incident, reported or not, kept for at least
five years. INC-7's file is the core of it: what happened, when, what was decided and by whom.

The last step is the review, a few days later, with everybody involved. It asks how the incident
became possible and how it could have been caught sooner, **never who is to blame**: a review that
looks for a culprit teaches people to write vaguer timelines. Its output is a short list of actions,
each with an owner and a date:

| action | owner | due |
|---|---|---|
| no file under review may hold a credential: `keyscan` over `data/prompts/` in lesson 23's suite | ana.lima | 2026-10-16 |
| every key narrowed to what its users need, the rest of SEC-42 | bruno.alves | 2026-10-23 |
| the sweep gets an incident hold, so pausing it is not a manual step | ana.lima | 2026-10-30 |

Each action that can be checked becomes a check in lesson 23's suite, as a known failure with the
action's date. **A review whose actions live only in a document is forgotten by the next incident.**
One whose actions are in the build goes red on the day a promise is missed.
