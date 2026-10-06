---
title: What small studies get wrong
version: 1
---

An underpowered study is not just a study that often misses real effects. When it does find one, it tends to **exaggerate it**. This is called the **winner's curse**, and it is one of the reasons published effects so often shrink when somebody tries to repeat them.

## Watching it happen

Suppose the new routing system really saves **1 minute** per delivery. Run the 25-delivery trial 4,000 times, and keep only the trials that came out significant, as a journal or a manager might:

| true improvement | power | average improvement in the significant trials |
|---|---|---|
| 1 minute | 21% | 2.61 minutes |
| 2 minutes | 48% | 2.95 minutes |
| 3 minutes | 79% | 3.45 minutes |

When the true improvement is 1 minute, the trials that reach significance report, on average, **2.61 minutes**: more than two and a half times the truth.

## Why it happens

With 25 deliveries, the sample mean wobbles by about 1.2 minutes either way. For a one-minute improvement, only the trials that happened to wobble in the favourable direction — showing a large improvement by luck — clear the significance line. Selecting the significant ones selects the lucky ones. The lower the power, the more luck it takes to cross the line, and the larger the exaggeration.

With 79% power, most trials cross the line without needing luck, and the significant ones exaggerate much less.

## The consequences

**A significant result from a small study probably overstates the effect.** If Horta's 25-delivery trial had come out significant, its estimate of the improvement should have been treated as an upper-end guess, not as the expected saving.

**A non-significant result from a small study says little.** Lesson 13's trial did not find an improvement, and had only a coin-toss chance of finding a real two-minute one. "We tested it and it didn't work" is a strong claim that a 48%-power trial cannot support.

**The cure is the same as for every other problem in this lesson: plan the study for adequate power, before collecting the data.** A study sized for 80% power to detect the smallest effect that matters both finds real effects reliably and reports them without much exaggeration.
