---
title: What each task asks of the platform
version: 1
---

The four programs in this lesson look alike: read the shop, build a table, fit, print. **Put into
production, they ask the platform for four different things**, and the differences are the ones a
data engineer has to plan for before anybody trains anything.

| | lapse (classification) | spend (regression) | kinds of reader (clustering) | next title (recommendation) |
| --- | --- | --- | --- | --- |
| **when the right answer is known** | 90 days after the prediction | 90 days after | never: there is no right answer | when the member next buys, if ever |
| **what a stored answer is keyed by** | member and cutoff | member and cutoff | member, cutoff and the run that made the groups | member, title and cutoff |
| **how many answers a night** | one per active member: 3,130 on 30 November | the same | one per member with five books | up to eighty per member |
| **how fresh the features must be** | a day old is fine | a day old is fine | a month old is fine | the last purchase matters, so minutes |

Each row is a decision later lessons make concrete.

**When the right answer is known** decides how a model can be tested before it ships (lesson 3)
and how its quality is watched once it has (lesson 9). For lapsing, nobody knows whether a
prediction made today was right until May.

**What a stored answer is keyed by** is the difference between a table you can join and one you
cannot. A score with no cutoff beside it cannot be compared with the outcome, and a cluster id with
no run beside it cannot be compared with anything (lessons 5 and 7).

**How many answers** decides whether they are computed overnight for everyone or on request for one
(lesson 8).

**How fresh the features must be** decides whether the platform needs a nightly table or a store
that answers in milliseconds, which is what lesson 6's feature store is for. The recommender is the
one where a purchase made at 10:02 should change what the website shows at 10:05.

None of these is in the algorithm. All of them are in the data.
