---
title: The two releases, measured
version: 2
---

The same five numbers for the evaluation set answered by each release, from the runs of lesson 10:

```
ana@dev:~/obs$ python metrics.py old new
run  release     ctx precision      ctx recall    faithfulness       relevance     correctness
old  2026.09.4     1.00 (n=19)     1.00 (n=19)     0.46 (n=24)     0.67 (n=24)     0.92 (n=24)
new  2026.10.1     1.00 (n=17)     0.89 (n=19)     0.45 (n=24)     0.58 (n=24)     0.67 (n=24)
```

**Correctness falls from 0.92 to 0.67**, 22 and 16 right out of 24, and that is the release lesson 5
traced to its floor. The four numbers beside it say where the six lost answers went, and each needs
reading with care.

**Context precision is 1.00 in both.** Whenever the model was given anything, the gold chunk was
among it and on top. The search is not where the replies went wrong.

**Context recall falls from 1.00 to 0.89**: under the new release, two answerable questions, the
instalments and the right of withdrawal, got no chunk at all, because none cleared the higher floor.
That is two of the six. The other four are not retrieval: under both releases the model was handed the
right chunk for the downloaded e-book and the Kindle and refused anyway, and under the new one it did
the same for the signed copy. **Context recall of 1.00 does not mean the answer reached the customer**;
it means it reached the model.

**Faithfulness is 0.46 and 0.45**, the judge's own score, and it barely moves. It is low because this
judge scores low; lesson 10 measured how far it can be trusted, and its faithfulness score was never
measured at all. **A metric nobody has checked against people is a number with a name.**

**Relevance falls from 0.67 to 0.58**: the refusals decided by the answer key, and the judge's
verdicts on everything else. It moves for the right reason, the extra refusals, and it is still made of
a judge that failed eleven good answers in lesson 10.

So two of the five numbers explain the release, correctness and context recall, and they are the two
with a reference behind them. The two that need none, the ones a team can run on production, are the
ones this judge is worst at.

## Reading a metric's n

Every number carries its count, and the counts differ on purpose:

- **Context recall is over 19 questions** in both runs: the five with no gold chunk have nothing to
  recall, and are excluded rather than scored as zero or one.
- **Context precision is over 19 and 17**: only the questions where the model was given anything. The
  new release gave nothing for two more questions, so its precision is computed over fewer
  retrievals.

A mean without its n hides exactly that. Two precisions computed over different sets of questions are
not the same measurement, and a dashboard that shows them side by side without their counts invites the
wrong conclusion.
