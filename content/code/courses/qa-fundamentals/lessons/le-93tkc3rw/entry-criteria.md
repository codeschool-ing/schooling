---
title: Entry criteria, or when testing can start
version: 1
---

**A test cycle is a stretch of testing with a start and an end: Lia's two days before Friday's release are one.**
Entry criteria say what must be true before it starts; exit criteria, the next section, say what must be true before
it can end. Both are written down in advance, so that neither moment is decided by whoever is most impatient.

Lesson 13 met the same idea on a Kanban board, as a policy for leaving a column. Here it is applied to a whole cycle.

## Why testing should not start too early

Starting a cycle before the thing to be tested is ready sounds like getting a head start. It is usually the opposite.
Testing a build that half the changes have not reached yet means testing it twice. Testing on a machine that is not
set up like the box office produces defects that are really configuration, and wastes a day on each. Testing without
the acceptance criteria means testing against guesses.

## Cine Aurora's entry criteria

Lia's cycle starts on Wednesday morning, and only when all five are true:

| criterion | why |
|---|---|
| all six changes are in one build | testing half a release is testing it twice |
| the automated checks pass on that build | a build that fails its own checks is not worth a person's time yet |
| the build is installed on the test machine set up like the box office terminal | defects should be the program's, not the machine's |
| every story has its acceptance criteria written | otherwise there is nothing to test against |
| the test data includes a real week's schedule, the Sunday 9:30 session among it | yesterday's defects live in yesterday's data |

None of these is exotic. Each one exists because a cycle somewhere, often at Cine Aurora, started without it and lost a
day.

## A smoke test

The second criterion is checked with a **smoke test**: a short, fast run of the most basic checks, to see whether the
build is worth testing at all. The name comes from hardware, where the first test of a new board was to switch it on
and see whether smoke came out. A smoke test does not look for subtle defects. It looks for a build that is so broken
that any further testing would be wasted.

In the lab, Cine Aurora's smoke test is three commands: the unit tests from lesson 15, the scenarios from lessons 16 and
17, and one ordinary ticket from the command line:

```
lia@lab:~/aurora$ python -m unittest
....
----------------------------------------------------------------------
Ran 4 tests in 0.000s

OK
lia@lab:~/aurora$ behave --format progress
USING RUNNER: behave.runner:Runner
features/coupons.feature  ....
features/prices.feature  ......

2 features passed, 0 failed, 0 skipped
10 scenarios passed, 0 failed, 0 skipped
36 steps passed, 0 failed, 0 skipped
Took 0min 0.003s
lia@lab:~/aurora$ python tickets.py 35 no thu 20:00
R$ 36,00
```

Every check passes and one evening ticket costs R$ 36,00, so the build meets its entry criterion and the cycle can
start. If any of the three had failed, Lia would not start. She would send the build back with the failure attached,
and the cycle would start when a build passed.

## Who checks the entry criteria

Lia checks them, but she does not decide them alone, and she does not decide alone to skip one. Had Rafael asked on
Wednesday morning whether testing could start without the refund button, because it was not finished, the answer would
not have been Lia's to give quietly. Either the refund button leaves this release, which is Joana's decision, or the
cycle waits. A cycle that starts anyway, with a note to "test refunds when they arrive", has an exit date that is
already wrong.
