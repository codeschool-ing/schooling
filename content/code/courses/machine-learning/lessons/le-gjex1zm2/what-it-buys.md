---
title: What rebalancing buys, and when
version: 1
---

Put the lesson's numbers in one place:

| remedy | AUC | average precision | at its own best cut |
|---|---|---|---|
| none | 0.804 | 0.322 | R$ 23,832 |
| class weights | 0.797 | 0.321 | R$ 21,304 |
| oversampling | 0.788 | 0.315 | R$ 21,616 |
| undersampling | 0.788 | 0.285 | R$ 18,440 |

On this problem **none of the remedies made the model know more**, and each made it worse, undersampling most.
What each did was move the chances, and with them the place where a cut is useful. A model that
produces chances, read with a cut computed from the costs, has already dealt with the imbalance:
the cut is where it is dealt with.

That is not true of every problem, and the cases where rebalancing earns its place are worth
knowing by name:

- **A model that gives labels, not chances.** Some algorithms, or some deployed systems, only say
  yes or no. Without a chance there is no cut to move, and the weight is the only dial left to turn.
- **An algorithm whose loss ignores the rare class.** A support vector machine or a shallow tree on
  a one-in-a-thousand class can settle on predicting the majority everywhere. Weights force it to
  look. Check that it did, with the curves from lesson 10, rather than assume.
- **Data too large to fit.** Undersample the majority, then correct the chances.
- **A rare class with very few examples.** Here nothing in this lesson helps much, and the section on
  counts said why. Collect more of them.

And three habits, whichever remedy is used:

- **Compare with doing nothing**, at each model's own best cut, on the same honest test.
- **Resample inside the fold**, never before the split.
- **Put the chances back** before a cut computed from the costs reads them: the formula after
  undersampling, calibration after anything else.
