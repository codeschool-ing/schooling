---
title: The two releases, measured
version: 1
---

The same five numbers for the evaluation set answered by each release, from the runs of lesson 10:

```
ana@lab:~/obs$ python metrics.py old new
run  release     ctx precision      ctx recall    faithfulness       relevance     correctness
old  2026.09.4     0.91 (n=20)     0.73 (n=26)     1.00 (n=30)     1.00 (n=30)     0.63 (n=30)
new  2026.10.1     0.94 (n=16)     0.56 (n=26)     1.00 (n=30)     1.00 (n=30)     0.53 (n=30)
```

**Two of the five do not move, and both are 1.00.** That is not two perfect releases. Faithfulness is
1.00 because extract-1 copies sentences out of its sources, so every sentence is supported by
construction; `rag` lesson 8 found the same with a rule. Relevance is 1.00 because judge-1 at its
threshold of 0.40 passes every reply it reads, which lesson 10 measured and the previous section
explained. **A metric that cannot fall tells you nothing when it does not fall.** Before a number is
put beside a release, somebody has to have seen it fail on a reply that deserved it.

**The three with a reference all move, and they move together.** Correctness falls from 0.63 to 0.53,
the same 19 and 16 right out of 30 that lesson 8 counted. Context recall falls further, from 0.73 to
0.56: the floor of 0.62 drops chunks that held the answer, and for four questions it drops every chunk,
so the model never sees them and refuses. And context precision **rises**, from 0.91 to 0.94, because
the chunks that survive the higher floor are more often the right ones.

That last pair is the trade of the previous section, in the search rather than in a judge. **The
floor is a threshold**: raising it bought precision with recall, and recall was the one that mattered,
because a model cannot use a chunk it was never given. A team watching only context precision would
have reported the release as an improvement.

## Reading a metric's n

Every number carries its count, and the counts differ on purpose:

- **Context recall is over 26 questions** in both runs: the four with no gold section have nothing to
  recall, and are excluded rather than scored as zero or one.
- **Context precision is over 20 and 16**: only the questions where the model was given anything. The
  new release refused four more questions with no chunks, so its precision is computed over fewer, and
  better, retrievals.

A mean without its n hides exactly that. Two precisions computed over different sets of questions are
not the same measurement, and a dashboard that shows them side by side without their counts invites the
wrong conclusion.
