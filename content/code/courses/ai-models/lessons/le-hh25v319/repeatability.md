---
title: The same question, twice
version: 1
---

A program run twice on the same input gives the same output. A model may not, and an evaluation
that ran each case once has measured one draw from something that varies.

Where the variation comes from is the **temperature** setting that `prompt-engineering` covers:
above zero, the model samples among likely next tokens instead of always taking the likeliest, so the same
prompt can produce different replies. At zero most providers come close to repeatable, though not
all of them guarantee it.

## At temperature 0

`evalkit` sends temperature 0 unless told otherwise. Ana runs standin-small again on the same cases
and compares the answers with the first run's:

```
ana@desk:~/desk$ python lab/evalkit.py run triage runs/again.jsonl 0 standin-small && diff <(cut -d, -f4,5 runs/again.jsonl) <(grep standin-small runs/triage.jsonl | cut -d, -f4,5) && echo same answers
same answers
```

Identical, case for case.

## At temperature 1

Then twice at temperature 1, the setting some applications leave on for drafting:

```
ana@desk:~/desk$ python lab/evalkit.py run triage runs/hot-a.jsonl 1 standin-small; python lab/evalkit.py run triage runs/hot-b.jsonl 1 standin-small
```

```
ana@desk:~/desk$ python lab/evalkit.py report runs/hot-a.jsonl; python lab/evalkit.py report runs/hot-b.jsonl | tail -1
model           strict   loose     loose, 95%  p50 s  $ per 1k
standin-small    32/40   34/40     71% to  93%   0.21    0.0167
standin-small    30/40   32/40     65% to  90%   0.21    0.0167
```

Same model, same cases, same prompt: **34 one time and 32 the next**. The difference between the
two runs is two cases:

```
ana@desk:~/desk$ diff <(cut -d, -f3,4 runs/hot-a.jsonl) <(cut -d, -f3,4 runs/hot-b.jsonl)
10c10
<  "case": "c10", "answer": "other"
---
>  "case": "c10", "answer": "refund"
17c17
<  "case": "c17", "answer": "refund"
---
>  "case": "c17", "answer": "order-status"
```

c10, an invoice request, was `other` in one run and `refund` in the other. c17, a refund not yet
received, was `refund` and then `order-status`. These are the stand-in's two unstable cases, written
by the course to behave this way; a real model at temperature 1 varies on whichever cases sit close
to its own boundaries, and you find out which by running more than once.

## What follows

- **Classify and extract at temperature 0.** There is one right answer; variety is only noise.
- **Where temperature has to stay up**, as it may for drafting, run each case several times and
  report the spread, not one score. "32 to 34 in two runs" is a true statement; "34" alone is not.
- **A difference between two models smaller than one model's own run-to-run spread is not a
  difference.** Two cases separated these runs of one model. That is half the four cases that
  separated standin-large from standin-small in section 06, which is one more reason that comparison
  was called suggestive.
