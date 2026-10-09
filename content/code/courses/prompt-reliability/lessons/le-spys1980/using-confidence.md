---
title: Using a stated confidence
version: 2
---

A confidence is worth collecting if it helps you decide what to do with an answer. The common use
is a threshold: **answer automatically above it, and send the rest to a person**. Raising the
threshold answers fewer messages and, if the confidence means anything, gets more of them right.
The trade is called coverage against accuracy.

`calibrate.py --thresholds` prints that trade for a few thresholds. The way to use it is to choose
on one set and check on another that played no part in the choice. Here, choose on the dev set:

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/dev.jsonl --out runs/v9-dev.jsonl
40 calls, prompt c31bed19, llama3.2:3b, written to runs/v9-dev.jsonl
ana@lab:~/triage$ python3 calibrate.py runs/v9-dev.jsonl --thresholds
stated         n  mean said  accuracy
0.00-0.50     1       0.00      1.00
0.50-0.60     0          -         -
0.60-0.70     0          -         -
0.70-0.80     0          -         -
0.80-0.90    27       0.80      0.81
0.90-1.00    12       0.90      1.00

replies 40, 0 with no usable confidence; right 35 of 40, mean stated 0.81
ECE 0.064   Brier 0.130

answer if      answered  accuracy
conf >= 0.00       40      0.88
conf >= 0.80       39      0.87
conf >= 0.85       12      1.00
conf >= 0.90       12      1.00
conf >= 0.95        1      1.00
```

On dev, the stated number looks useful. Replies stated at 0.9 or above were right every time, 12 of
12, and the ones stated at 0.8 were right 0.81 of the time. Answer when the confidence is at least
0.85, and you answer 12 messages of 40 **with an accuracy of 1.00**, and send 28 to a person.

Now hold that threshold against the harder set it never saw:

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/holdout.jsonl --out runs/v9-holdout.jsonl
30 calls, prompt c31bed19, llama3.2:3b, written to runs/v9-holdout.jsonl
ana@lab:~/triage$ python3 calibrate.py runs/v9-holdout.jsonl --thresholds
stated         n  mean said  accuracy
0.00-0.50     0          -         -
0.50-0.60     0          -         -
0.60-0.70     0          -         -
0.70-0.80     0          -         -
0.80-0.90    19       0.80      0.58
0.90-1.00    11       0.90      0.55

replies 30, 0 with no usable confidence; right 17 of 30, mean stated 0.84
ECE 0.270   Brier 0.322

answer if      answered  accuracy
conf >= 0.00       30      0.57
conf >= 0.80       30      0.57
conf >= 0.85       11      0.55
conf >= 0.90       11      0.55
conf >= 0.95        0         -
```

The same rule answers 11 messages of 30 and gets **0.55** of them right. Answering everything gets
0.57. On this set the replies stated at 0.9 were right less often than the ones stated at 0.8, and a
threshold that was perfect on dev is worse than no threshold at all. Nothing about the model or the
threshold changed. The messages did: the holdout holds the harder messages, and on them the model
wrote 0.9 for reasons that had nothing to do with being right.

## What the threshold did

On dev, a confidence that barely separated right from wrong over seventy messages looked like a
perfect filter over forty, because twelve replies happened to be right. On the holdout the same
filter did nothing useful. That is the lesson 11 gap again, dev against holdout, in a different
number: **a threshold chosen on one set is a best case for that set**, and the number that means
anything is the one from a set it was not chosen on.

So the rules for a stated confidence are the rules for any other output:

- **Measure it against labels a person gave**, with a reliability table, ECE and Brier, on the
  messages you will actually see.
- **Compare it with saying the base rate every time.** If a constant beats it on Brier, as one did
  here, the number carries no information you can route on.
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
