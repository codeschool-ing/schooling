---
title: Measuring the judge
version: 1
---

A judge is a classifier. It reads two replies and outputs a label, `a` or `b`, so **it is measured
the way the triage prompt was: against labels a person wrote down first.**

```
ana@lab:~/triage$ pl judge cases/pairs.jsonl
j01  human b  judge a
j02  human b  judge b
j03  human a  judge a
j04  human a  judge a
j05  human b  judge b
j06  human a  judge a
j07  human b  judge a
j08  human a  judge a
j09  human b  judge b
j10  human a  judge a
j11  human b  judge a
j12  human a  judge a
j13  human b  judge a
j14  human b  judge b
j15  human a  judge b
j16  human a  judge b

agrees with the human on 10 of 16
Cohen's kappa 0.25
```

Ten of sixteen agree with the person, 62.5%. That reads like most of them, and it is less than it
looks.

## Agreement beyond chance

With two possible answers, a judge that tossed a coin would agree with the person about half the
time. Raw agreement does not say how much of the 62.5% is that half. **Cohen's kappa measures
agreement beyond chance**, a statistic Jacob Cohen published in 1960 for exactly this: two raters
sorting the same items into categories.

It needs two numbers. The observed agreement is 10 of 16, 0.625. The agreement expected by chance
comes from how often each rater uses each answer:

```
ana@lab:~/triage$ grep -c '"human": "a"' cases/pairs.jsonl
8
```

The person chose `a` in 8 pairs of 16, and the judge chose `a` in 10. If the two answered
independently at those rates, they would both say `a` with probability 8/16 × 10/16 = 0.3125, and
both say `b` with probability 8/16 × 6/16 = 0.1875, so they would agree 0.5 of the time by chance.

Kappa is how far the observed agreement got from chance, as a share of how far it could have got:
(0.625 − 0.5) / (1 − 0.5) = 0.25. **A kappa of 0 is a judge that agrees with people exactly as often
as chance would, and 1 is perfect agreement.** The scale most often quoted, from Landis and Koch in
1977, calls 0.21 to 0.40 fair. This judge sorts pairs a little better than a coin.

## Calibrate before you trust

That number is what a judge has to show before anybody relies on it: a sample of the real task,
labelled by people who did not see the judge's answer, and the judge's agreement with them corrected
for chance. Sixteen pairs is the smallest set that makes the arithmetic visible, and lesson 11's
warning applies in full: one pair moves the agreement by six points. A judge you plan to use on
thousands of replies deserves a few hundred labelled pairs first.
