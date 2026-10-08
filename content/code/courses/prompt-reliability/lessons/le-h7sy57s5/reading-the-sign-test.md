---
title: Reading the sign test
version: 2
---

`pl compare` ends every comparison with a line like `sign test on the 13 that changed: p = 1.000`.
**The number answers one narrow question**: if the change made no difference at all, and each
changed message was as likely to go one way as the other, how often would chance alone produce a
split at least this uneven, in either direction?

Only the messages whose result changed enter the test. The twenty that passed under both prompts and
the thirty-seven that failed under both say nothing about the difference between them, which is why
a test set of seventy can hold very little evidence about a particular change.

## How many changed messages you need

When every changed message moves the same way, the arithmetic is short. Each message is a coin
toss, and the chance that all *n* land on the same side is a half multiplied by itself *n* times.
Either side counts, so p is twice that. `cmd_compare` in `pl.py` computes it with `math.comb`, and
so does this line:

```
ana@lab:~/triage$ python3 -c 'from math import comb; [print(n, 2 * comb(n, 0) / 2 ** n) for n in range(1, 9)]'
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
ana@lab:~/triage$ python3 -c 'from math import comb; [print(n, 1, round(2 * (comb(n, 0) + comb(n, 1)) / 2 ** n, 3)) for n in range(5, 10)]'
5 1 0.375
6 1 0.219
7 1 0.125
8 1 0.07
9 1 0.039
```

Read it as *changed messages, how many went the other way, then p*. With one of them against, it
takes nine changed messages before p drops under 0.05. The prose experiment had thirteen changed
messages split seven to six, and **no split that even can ever count as evidence**, however many
messages it covers. That is worth knowing before you run an experiment, not after.

## What p is not

- It is not the probability that the change helped. It says how surprising the split would be
  if the change did nothing.
- It says nothing about why. The run with the temperature left in gave p = 0.774: the test cannot
  tell you whether the wording or the temperature did anything, only that the total split looks
  like chance.
- It says nothing about what the totals hide. p = 1.000 sat on top of twelve changed categories and
  a reversed urgency bias.
- 0.05 is a convention. It is a line people agree to draw, and a p of 0.06 is not proof of no
  effect. It means this test set did not show one.

When a change moves too few messages to measure, there are two honest moves: a bigger test set, or a
change with a bigger effect. Writing *slightly better* in the commit message is not one of them.
