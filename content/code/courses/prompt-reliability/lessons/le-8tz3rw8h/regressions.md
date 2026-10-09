---
title: Catching a regression the same day
version: 2
---

The table in the last section was printed after the fact, for a lesson. In August, nothing printed
it. `85dfa4e` was committed on the 17th, and if anybody ran the test set against it the history does
not say so. **A regression is found when somebody looks, and the only dependable somebody is a check
that runs by itself.**

## A check on every change

The check is the same comparison lesson 1 used to decide whether examples helped, pointed the other
way. Before a change to the prompt is merged, run the new file over the test sets, run the file that
is live now, and compare them message by message. On 17 August the live file was `86913c0`'s and
the new one was the revert:

```
ana@lab:~/triage$ pl compare runs/86913c0.jsonl runs/now.jsonl
runs/86913c0.jsonl       passes 27/40
runs/now.jsonl           passes 24/40
fixed 1, broken 4
broken: t12 t23 t28 t38
sign test on the 5 that changed: p = 0.375
```

That output would have stopped the merge, or at least made somebody explain it. Four messages broken
and one fixed, **and it names every one of them**, so the person who made the change starts from
`t12` rather than from a count. The sign test says 0.375: five changed messages splitting four to
one is not good evidence that the revert was worse. It is no evidence at all that it was better, and
it cost 1855 tokens a run. A gate is not there to decide that question alone; it is there so that
the question gets asked on the day, by somebody who still remembers why they made the change.

A gate built on that has three parts, and none of them is clever:

1. **It runs on every change to a prompt file**, before the change is merged, on whatever runs
   your other tests. A check somebody has to remember is a check that runs on the days they
   remember.
2. **It runs every test set the prompt has**, not only dev. `a0f1d2a` cost two messages on dev and
   gained one on the attacks, and a gate on dev alone would have seen only the loss.
3. **It fails on any broken message** and prints their ids, and a person who wants to merge anyway
   says why in the commit. Sometimes breaking one message to fix five is right; it should never
   happen without anybody noticing.

The total is the least useful line in the output. A change can fix one message and break another
and leave the total exactly where it was, and the line that matters for a gate is `broken`.

## A regression with no diff

The gate compares runs, and a run is more than the file. Here is the run at temperature 0.8 from
earlier, against the run of the same file at its default:

```
ana@lab:~/triage$ pl compare runs/now.jsonl runs/hot.jsonl
runs/now.jsonl           passes 24/40
runs/hot.jsonl           passes 24/40
fixed 1, broken 1
broken: t31
sign test on the 2 that changed: p = 1.000
```

The same 24 of 40, one message fixed and one broken. **The prompt id is the same in both runs, and
`git diff` would show nothing**, because the change was never in the file. A gate that only runs
when the prompt file changes would never see it, and a gate that compared totals would see nothing
even if it ran. That is the practical argument for the rule in *What a version is*: when every
parameter lives in the file, every change to what production runs is a change to the file, and the
gate sees all of them.

Lesson 15 writes down what the revert should have said, so that the next person to make the
examples easier to read, or to put them back, knows what was measured when it was last tried.
