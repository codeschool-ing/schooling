---
title: A checklist before you forecast
version: 1
---

The first six lessons, folded into the questions to ask of a new series before any model is fitted.
Each one is cheap, and each one has been the cause of a forecast that looked right and was not.

**About the decision**

- What will be decided with the forecast, at what horizon and at what grain? (lesson 4)
- What does a miss cost, and is a big miss worse than several small ones? That chooses between MAE
  and RMSE. (lesson 5)

**About the data**

- Are the last periods complete? Compare a snapshot with the final numbers, and cut or mark what is
  still arriving.
- Are there partial periods at either end: a week of three days, a month started on the 20th?
- Has the definition changed? A new way of counting is a regime change in the data rather than in the
  business, and it looks the same.

**About the series**

- What are its seasons, and are they added or multiplied? (lessons 1 and 2)
- Which holidays move, and are they visible in the residuals of a decomposition? (lesson 2 and this
  one)
- Has anything happened that the history does not contain: a price change, a launch, a closure?
  Mark it before a smoother absorbs it.

**About the forecast**

- Does it beat the naive and seasonal naive baselines on weeks it did not see? (lessons 3 and 5)
- Was it measured from several origins, at the horizon the decision needs? (lesson 5)
- Do its intervals cover what they claim in a back-test? (lesson 4)
- Is every vintage stored with its date? (lesson 4)

A forecast that passes all of this can still be wrong; the future owes nobody anything. But it will be
wrong for reasons nobody could have known, which is the only kind of wrong a forecaster can defend.
