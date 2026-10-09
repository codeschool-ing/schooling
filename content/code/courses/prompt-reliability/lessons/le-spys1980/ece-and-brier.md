---
title: ECE and the Brier score
version: 2
---

A diagram is for looking at. To compare two prompts, or to watch calibration from one release to
the next, you want one number. `calibrate.py` prints two at the bottom of its table, and they
measure different things.

## Expected calibration error

**ECE is the average gap between what was said and what happened**, weighted by how many replies
each bin holds. For each bin, take the gap between mean stated confidence and accuracy, ignore its
sign, and multiply by the bin's share of all replies. Add the bins.

From the last section's table:

- 0.8 to 0.9: 46 ÷ 70 × (0.80 − 0.72) = 0.657 × 0.08 = 0.053
- 0.9 to 1.0: 23 ÷ 70 × (0.90 − 0.78) = 0.329 × 0.12 = 0.039
- below 0.5: 1 ÷ 70 × (1.00 − 0.00) = 0.014

The sum from the rounded numbers is 0.106; `calibrate.py` adds them before rounding and prints
0.108. The one reply stated at 0.0 supplies an eighth of it on its own, because its gap is the
largest a gap can be.

ECE says how far off the stated numbers are on average. It does not say in which direction, and a
model that is underconfident in one bin and overconfident in another adds both gaps.

The measure was used before, and the paper that made it the usual one is *On Calibration of Modern
Neural Networks* (Guo and others, 2017). It found that the deep classifiers of the time were
markedly more overconfident than older, smaller networks, and measured them with ECE and
reliability diagrams. It also showed that a single rescaling of their outputs, temperature scaling,
fixed much of it. That paper was about the probabilities a classifier computes; the confidence in
this lesson is a number a model writes. **The measurement is the same either way**: what was
claimed, against what happened.

## The Brier score

The Brier score skips the bins. For every reply, take the stated confidence, subtract 1 if the
answer was right or 0 if it was wrong, square it, and average over all replies.

`h03` stated 0.9 and was wrong: (0.9 − 0)² = 0.81. Divided among 70 replies, that one answer adds
0.012 to the score. A right answer stated at 0.9 adds (0.9 − 1)² = 0.01, divided by 70: almost
nothing. `t35`, right and stated at 0.0, adds (0.0 − 1)² = 1, divided by 70: 0.014.

The whole score is 0.212. Lower is better, and 0 needs every right answer stated at 1 and every
wrong one at 0. Because the gap is squared, **the Brier score punishes a confident mistake far more
than a timid one**, and it rewards a model that both separates its right answers from its wrong
ones and says so.

ECE only asks whether the numbers match the rate. A model that stated 0.74 on every reply here
would have an ECE of zero, since 0.74 is its accuracy, and would tell you nothing about which reply
to trust. The Brier score charges it for that: (18 × 0.74² + 52 × 0.26²) ÷ 70 = (9.86 + 3.52) ÷ 70 =
0.19. **That is better than the 0.212 the model earned with its own numbers.** Saying the overall
accuracy every time, the least informative confidence there is, would have scored better than what
`llama3.2:3b` wrote.

Report both. ECE answers *can I read the number as a rate?* and Brier answers *does the number help
me tell good answers from bad ones?* Here the first answer is roughly, and the second is no.
