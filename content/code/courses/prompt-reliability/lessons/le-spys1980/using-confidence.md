---
title: Using a stated confidence
version: 1
---

A confidence is worth collecting if it helps you decide what to do with an answer. The common use
is a threshold: **answer automatically above it, and send the rest to a person**. Raising the
threshold answers fewer messages and, if the confidence means anything, gets more of them right.
The trade is called coverage against accuracy.

`pl calibrate --thresholds` prints that trade for a few thresholds. The way to use it is to choose
on one set and check on another that played no part in the choice. Here, choose on the dev set:

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/dev.jsonl --out runs/v9-dev.jsonl
40 calls, prompt c31bed19, written to runs/v9-dev.jsonl
ana@lab:~/triage$ pl calibrate runs/v9-dev.jsonl --thresholds
stated         n  mean said  accuracy
0.50-0.60    0          -         -
0.60-0.70    0          -         -
0.70-0.80    1       0.70      0.00
0.80-0.90   14       0.85      1.00
0.90-1.00   25       0.97      1.00

replies 40, right 39, mean stated confidence 0.92
ECE 0.092   Brier 0.022

answer if  answered  accuracy
conf >= 0.00     40      0.97
conf >= 0.80     39      1.00
conf >= 0.85     34      1.00
conf >= 0.90     25      1.00
conf >= 0.95     21      1.00
```

On dev, the stand-in looks **underconfident**: replies stated around 0.85 were right every time.
The only wrong answer was stated at 0.70, and a threshold of 0.80 removes it. Answer when the
confidence is at least 0.80, and you answer 39 messages of 40 with an accuracy of 1.00.

Now hold that threshold against the harder set it never saw:

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/holdout.jsonl --out runs/v9-holdout.jsonl
30 calls, prompt c31bed19, written to runs/v9-holdout.jsonl
ana@lab:~/triage$ pl calibrate runs/v9-holdout.jsonl --thresholds
stated         n  mean said  accuracy
0.50-0.60    0          -         -
0.60-0.70    2       0.69      0.00
0.70-0.80    6       0.74      0.33
0.80-0.90   13       0.85      0.62
0.90-1.00    9       0.96      0.78

replies 30, right 17, mean stated confidence 0.85
ECE 0.282   Brier 0.295

answer if  answered  accuracy
conf >= 0.00     30      0.57
conf >= 0.80     22      0.68
conf >= 0.85     16      0.75
conf >= 0.90      9      0.78
conf >= 0.95      7      0.86
```

The same rule answers 22 messages of 30 and gets **0.68** of them right. On this set the stand-in is
overconfident in every bin, and its ECE is 0.282 against 0.092 on dev. Nothing about the model or
the threshold changed. The messages did: the holdout holds the harder messages, many of them with
evidence for two labels like `h04`, and that is exactly where the stand-in's rule states a
confidence its answer has not earned.

## What the threshold still did

It did help. On the holdout, answering everything gives 0.57; answering at 0.80 or above gives
0.68, and the eight messages it held back went to a person. A confidence that is miscalibrated can
still rank answers usefully, and that ranking is what a threshold uses. What it cannot do is
deliver the accuracy it promised on the set it was chosen on.

So the rules for a stated confidence are the rules for any other output:

- **Measure it against labels a person gave**, with a reliability table, ECE and Brier, on the
  messages you will actually see.
- **Choose a threshold on one set and report it on another.** The number from the set you chose on
  is a best case.
- **Re-measure when anything changes**: the prompt, the model, the kind of messages arriving. A
  calibration is a property of all three together.

**A stated confidence is a feature to be measured, never a probability to be trusted.**

## The course

This was the last lesson. Every one of them ran the same prompt over the same messages and asked
whether a change held up, in a count that could have come out the other way. A confidence is one
more claim a model makes about its own answer, and it gets what every claim in this course got: a
test set, a person's labels, and a number you computed rather than one you were told.
