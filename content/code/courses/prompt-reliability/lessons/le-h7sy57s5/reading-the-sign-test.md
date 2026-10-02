---
title: Reading the sign test
version: 1
---

`pl compare` ends every comparison with a line like `sign test on the 2 that changed: p = 0.500`.
**The number answers one narrow question**: if the change made no difference at all, and each
changed message was as likely to go one way as the other, how often would chance alone produce a
split at least this uneven, in either direction?

Only the messages whose result changed enter the test. The 46 that passed under both prompts and the
22 that failed under both say nothing about the difference between them, which is why a test set of
seventy can hold very little evidence about a particular change.

## How many changed messages you need

When every changed message moves the same way, the arithmetic is short. Each message is a coin
toss, and the chance that all *n* land on the same side is a half multiplied by itself *n* times.
Either side counts, so p is twice that. The lab's own function, the one `pl compare` calls, gives
the same numbers:

```
ana@lab:~/triage$ python3 -c 'from promptlab.cli import sign_test; [print(n, sign_test(n, 0)) for n in range(1, 9)]'
1 1.0
2 0.5
3 0.25
4 0.125
5 0.0625
6 0.03125
7 0.015625
8 0.0078125
```

Read it as *changed messages, then p*. Two changed messages, both in the same direction, give 0.5.
Five give 0.0625. **Six is the smallest number that can fall below 0.05**, and only when all six
moved the same way. One message going the other way raises the bar:

```
ana@lab:~/triage$ python3 -c 'from promptlab.cli import sign_test; [print(n, 1, round(sign_test(n, 1), 3)) for n in range(5, 10)]'
5 1 0.219
6 1 0.125
7 1 0.07
8 1 0.039
9 1 0.021
```

With one broken, it takes eight fixed before p drops under 0.05. The prose experiment had two
changed messages, so **no result it could have produced would have counted as evidence**. That is
worth knowing before you run an experiment, not after.

## What p is not

- It is not the probability that the change helped. It says how surprising the split would be
  if the change did nothing.
- It says nothing about why. The run with the temperature left in gave p = 0.001: the two runs
  really were different, and the test cannot tell you that wording had no part in it.
- 0.05 is a convention. It is a line people agree to draw, and a p of 0.06 is not proof of no
  effect. It means this test set did not show one.

When a change moves too few messages to measure, there are two honest moves: a bigger test set, or a
change with a bigger effect. Writing *slightly better* in the commit message is not one of them.
