---
title: Catching a regression the same day
version: 1
---

The table in the last section was printed after the fact, for a lesson. In August, nothing printed
it. `31a6a59` was committed on the afternoon of the 14th, and if anybody ran the test set against it
the history does not say so. For three days the live prompt answered every message in a format no
program could read.
**A regression is found when somebody looks, and the only dependable somebody is a check that runs
by itself.**

## A check on every change

The check is the same comparison lesson 1 used to decide whether examples helped, pointed the other
way. Before a change to the prompt is merged, run the new file over the test sets, run the file that
is live now, and compare them message by message:

```
ana@lab:~/triage$ pl compare runs/c8470c9.jsonl runs/31a6a59.jsonl
runs/c8470c9.jsonl       passes 36/40
runs/31a6a59.jsonl       passes 0/40
fixed 0, broken 36, still passing 0, still failing 4
broken: t01 t02 t03 t04 t05 t06 t07 t08 t09 t10 t11 t12 t13 t15 t16 t17 t18 t19 t20 t21 t22 t23 t25 t26 t27 t29 t30 t31 t32 t33 t34 t35 t36 t38 t39 t40
sign test on the 36 that changed: p = 0.000
```

That output, on 14 August, would have stopped the merge. Thirty-six messages broken and none fixed,
**and it names every one of them**, so the person who made the change starts from `t01` rather than
from a count. The total is the least useful line in it. A change can fix one message and break
another and leave the total exactly where it was, and the line that matters for a gate is
`broken`.

A gate built on that has three parts, and none of them is clever:

1. **It runs on every change to a prompt file**, before the change is merged, on whatever runs
   your other tests. A check somebody has to remember is a check that runs on the days they
   remember.
2. **It runs every test set the prompt has**, not only dev. `931c548` showed that dev is blind to
   what the attack set sees, and a gate on dev alone would pass a change that undid it.
3. **It fails on any broken message** and prints their ids, and a person who wants to merge anyway
   says why in the commit. Sometimes breaking one message to fix five is right; it should never
   happen without anybody noticing.

## A regression with no diff

The gate compares runs, and a run is more than the file. Here is the run at temperature 0.8 from
earlier, against the run of the same file at its default:

```
ana@lab:~/triage$ pl compare runs/now.jsonl runs/hot.jsonl
runs/now.jsonl           passes 36/40
runs/hot.jsonl           passes 28/40
fixed 0, broken 8, still passing 28, still failing 4
broken: t06 t08 t18 t20 t23 t25 t33 t38
sign test on the 8 that changed: p = 0.008
```

Eight messages broken, and a sign test of 0.008 says that is unlikely to be chance. **The prompt id is the
same in both runs, and `git diff` would show nothing**, because the change was never in the file. A
gate that only runs when the prompt file changes would never see it. That is the practical
argument for the last section's rule: when every parameter lives in the file, every change to what
production runs is a change to the file, and the gate sees all of them.

Lesson 15 writes down what a regression like `31a6a59` teaches, so that the next person to make the
examples easier to read knows why they look the way they do.
