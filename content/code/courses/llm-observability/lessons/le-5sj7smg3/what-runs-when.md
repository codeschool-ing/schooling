---
title: What runs, and when
version: 1
---

Lessons 13 and 14 built two kinds of check: the set's own integrity, and the comparison of a candidate
with production. Run by hand, each depends on somebody remembering to run it, on the day it matters,
which is the day somebody is in a hurry. Wiring them into **continuous integration** makes them run on
every change that could need them, and makes a failure stop the merge rather than appear in a message
nobody reads.

Not everything should run on every commit, because the checks cost very different amounts:

| Tier | What runs | Calls a model? | When |
| --- | --- | --- | --- |
| the set | ids, manifest hash, facts in gold sections, documents at their pinned versions, personal data | no | every change to the set, the documents or the tests |
| the regression | production and candidate answer the set; broken cases, new check failures, budgets | yes, twice per case | every change that can alter a reply |
| the slow ones | held-out split, judge-graded metrics, a look at the changed replies | yes, more | before a release, or nightly |

**The first tier costs nothing and should never be skipped.** It is lesson 13's `check_set.py` as tests. It fails in seconds when somebody commits a set that does not match its manifest, or a case that
holds a customer's name.

**The second tier costs money on every run.** In lesson 14 the whole set cost under five cents to
answer, at the lab's prices, for the most expensive candidate. Twice that per pull request is cheap
next to a release that breaks five questions, and it is still a bill: the trigger has to be the changes
that can alter a reply, not every edit to a README.

**The third tier is where people come in**: the held-out split is run once a candidate is final, and the
replies that changed are read, as lesson 14 asked. A pipeline can schedule these; it cannot do the
reading.

The rest of this lesson builds the first two tiers as pytest tests, runs them on lesson 14's candidates,
and shows the workflow that runs them on a pull request.
