---
title: A paired comparison
version: 1
---

The two releases answered the same 42 questions. Comparing their pass rates as two separate numbers, as
lesson 9 compared samples, throws that away: 23 right against 18 right, two intervals of about ±15
points each, overlapping almost entirely, and the honest report would be "cannot tell".

**A paired comparison uses the fact that the questions are the same.** The 37 cases both releases got
right, or both got wrong, say nothing about the difference between them. All the information is in the
cases that changed verdict, and the question is whether they changed in one direction more than chance
would explain.

**McNemar's test** answers that. If the change made no difference, each changed case would be equally
likely to have gone either way, like a coin; the exact test asks how often a fair coin, tossed once per
changed case, would come out at least as lopsided. `regress.py` computes it in five lines.

For the floor release: five changed cases, all five broken. A fair coin gives five heads in a row one
time in 32, and the test counts the other direction too: **p = 0.0625**. Not below the 0.05 that
textbooks use, and the floor release is still not fit to ship.

That is not a contradiction, because the two answer different questions:

- **The p-value is about the average**: whether the candidate is worse on questions like these in
  general. With five changed cases out of 42, the set is too small to say so with confidence, as lesson
  13's arithmetic predicted.
- **The broken cases are facts**: these five questions, which the assistant used to answer, it no
  longer does. They need no statistics. Each one is a question a customer asks, and the regression
  report names it.

So a team uses both, for different decisions. **A broken case blocks a release until somebody has read
it** and decided it is acceptable, whatever the p-value. **The p-value decides claims about the average**,
such as "the new model is better", where the honest answer from a small set is often that it cannot be
told.
