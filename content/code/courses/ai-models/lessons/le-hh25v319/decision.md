---
title: Deciding, and deciding again
version: 1
---

Everything is now on the table: lesson 4's thresholds and costs, and this lesson's scores. Ana's
floor for sorting was 35 of 40, and for extraction she sets it where a wrong order number is rare
enough to catch by hand: **no content errors at all**, and format errors only if a structured-output
feature removes them.

| task | standin-large | standin-small | standin-local |
|---|---|---|---|
| sorting floor, 35 of 40 | **passes, 38** | fails, 34 | fails, 32 |
| extraction, no content errors | **passes** | passes once the format is fixed | fails: a transposed number |
| price per 1,000 requests | $0.2001 | $0.0167 | a machine |

On these numbers the choice for both tasks is standin-large, and at 400 e-mails a day its price is
a rounding error. With real candidates the table would have more rows and closer scores, and
the rule that decides stays the same: **the cheapest candidate that passes every floor, per task**.

## The run is a baseline

The run that decided is kept, with the date, the exact model identifiers, the prompt and the
version of the cases. It becomes the **baseline** the next run is compared with, and there will be
a next run. Lesson 2 section 06 listed what triggers one: a model retired on the provider's date,
an alias that starts answering with a different model, a new candidate worth trying, a prompt
edited to fix the borderline cases. Each of those is a change to one input of the evaluation, and
the cases answer whether it made things worse.

`evalkit gate` makes that check something a program can refuse. It compares a model's loose score
in a new run with the baseline and fails, with exit status 1, if the new one is worse by more than
the cases allowed:

```
ana@desk:~/desk$ cp runs/triage.jsonl runs/baseline.jsonl
ana@desk:~/desk$ python lab/evalkit.py gate runs/baseline.jsonl runs/hot-a.jsonl standin-small; echo "exit $?"
standin-small: 34 before, 34 now, 1 allowed: pass
exit 0
ana@desk:~/desk$ python lab/evalkit.py gate runs/baseline.jsonl runs/hot-b.jsonl standin-small; echo "exit $?"
standin-small: 34 before, 32 now, 1 allowed: FAIL
exit 1
```

The first run at temperature 1 matched the baseline, 34 and 34, and passed. The second dropped two
cases, past the one allowed, and **failed with exit status 1**, which is what lets a script, a
scheduled job or a CI pipeline stop a change from going out. Section 08's two runs, gated: the same
model, the same cases, and one of the two would have been refused.

## What makes this the lesson that lasts

Every model this course names in lessons 6 to 20 will be replaced. The forty cases, the decision
about what counts as right, the harness, the intervals and the gate will not need to be. When the
next model arrives, the work of choosing it is to add a row and run the file: **an afternoon,
because the evaluation was already written**.
