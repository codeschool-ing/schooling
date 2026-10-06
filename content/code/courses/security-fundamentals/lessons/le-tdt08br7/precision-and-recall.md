---
title: Precision and recall
version: 1
---

A threshold of five failures in ten minutes is a common default. Here is what it does to the shop's
week:

```
ana@laptop:~$ python3 detect.py 5
threshold 5: 10 alerts
  TP   3   FP   7
  FN   8   TN  80
precision 30%   recall 27%
```

Ten alerts in a week, and the matrix says what they were worth. **Three true positives**: the fast
guesser's three windows of eight failures each. **Seven false positives**: the backup job, every
night, failing six times with its expired password. **Eight false negatives**: every window of the
slow guesser, who never failed more than three times in ten minutes, sailed under the rule. **Eighty
true negatives**: staff mistyping, correctly left alone.

Two numbers summarise the matrix, and they answer different questions.

**Precision** answers *"when it alerts, how often is it right?"*

> precision = TP ÷ (TP + FP) = 3 ÷ 10 = **30%**

Seven alerts in ten were the backup job. Whoever reads them learns, within a week, that this alert
usually means "the backup job again".

**Recall** answers *"of the real attacks, how many did it catch?"*

> recall = TP ÷ (TP + FN) = 3 ÷ 11 = **27%**

The exercise produced eleven cases and the rule caught three. The slow guesser was invisible, and a
real attacker who knows the common defaults guesses slowly on purpose.

So this rule is bad on both counts at once, and the two numbers say why in different words: it
alerts on the wrong thing (precision) and misses most of the right thing (recall). Neither number
alone would have shown both problems. A detector with 100% recall that alerts on every failed login
is useless, and so is one with 100% precision that fires once a year and misses everything else.

### The two numbers have other names

Different fields use different words for the same ideas, and you will meet them all:

| here | also called | the question |
|---|---|---|
| recall | sensitivity, true positive rate, detection rate | of the bad things, how many did we catch? |
| precision | positive predictive value | of the alerts, how many were real? |
| the false positive rate | fall-out | of the harmless cases, how many did we alert on? |

The last row is FP ÷ (FP + TN), which here is 7 ÷ 87, about 8%. It looks small, and the last section
of this lesson shows why a small false positive rate can still bury a team.
