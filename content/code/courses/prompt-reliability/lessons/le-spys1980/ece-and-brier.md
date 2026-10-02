---
title: ECE and the Brier score
version: 1
---

A diagram is for looking at. To compare two prompts, or to watch calibration from one release to
the next, you want one number. `pl calibrate` prints two at the bottom of its table, and they
measure different things.

## Expected calibration error

**ECE is the average gap between what was said and what happened**, weighted by how many replies
each bin holds. For each bin, take the gap between mean stated confidence and accuracy, ignore its
sign, and multiply by the bin's share of all replies. Add the bins.

Work the 0.7 to 0.8 bin from the last section's table: 7 replies of 70, mean stated 0.73, accuracy
0.29.

7 ÷ 70 × (0.73 − 0.29) = 0.1 × 0.44 = **0.044**

The whole ECE is 0.088, so seven replies supply half of it. The 34 replies above 0.9 supply 34 ÷ 70
× (0.96 − 0.94), about 0.010, and the other two bins the rest. The sum of the four, from the rounded
numbers in the table, comes to about 0.089; `pl calibrate` adds them before rounding and prints
0.088.

ECE says how far off the stated numbers are on average. It does not say in which direction, and a
model that is underconfident in one bin and overconfident in another adds both gaps.

The measure was used before, and the paper that made it the usual one is *On Calibration of Modern
Neural Networks* (Guo and others, 2017). It found that the deep classifiers of the time were
markedly more overconfident than older, smaller networks, measured them with ECE and reliability
diagrams, and showed that a single rescaling of their outputs, temperature scaling, fixed much of
it. That paper was about the probabilities a classifier computes; the confidence in this lesson is
a number a model writes. **The measurement is the same either way**: what was claimed, against what
happened.

## The Brier score

The Brier score skips the bins. For every reply, take the stated confidence, subtract 1 if the
answer was right or 0 if it was wrong, square it, and average over all replies.

`h04` stated 0.97 and was wrong: (0.97 − 0)² = 0.9409. Divided among 70 replies, that one answer adds
0.013 to the score. A right answer stated at 0.97 adds (0.97 − 1)² = 0.0009, divided by 70: almost
nothing.

The whole score is 0.139. Lower is better, and 0 needs every right answer stated at 1 and every
wrong one at 0. Because the gap is squared, **the Brier score punishes a confident mistake far more
than a timid one**, and it rewards a model that both separates its right answers from its wrong
ones and says so. ECE only asks whether the numbers match the rate; a model that stated 0.80 on
every reply here would have an ECE of zero, since 0.80 is exactly its accuracy, and would tell you
nothing about which reply to trust. The Brier score charges it for that: (14 × 0.8² + 56 × 0.2²) ÷
70 = (8.96 + 2.24) ÷ 70 = 0.16, worse than the stand-in's 0.139.

Report both. ECE answers *can I read the number as a rate?* and Brier answers *does the number help
me tell good answers from bad ones?*
