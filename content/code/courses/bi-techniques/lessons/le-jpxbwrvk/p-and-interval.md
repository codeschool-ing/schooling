---
title: What the p-value and the interval say
version: 1
---

## The p-value

`statistics` lesson 14 defines it, and the definition is worth repeating because nearly everybody
gets it backwards. **The p-value is the probability of seeing a difference at least this large if
the two pages really converted at the same rate.** For Panela's test, 0.032: if the new checkout
made no difference at all, a gap of 0.40 points or more would turn up in about three tests in a
hundred.

What it is not:

- **not the probability that the new page is no better.** That would need a prior belief about how
  often new checkouts work, which the test does not have;
- **not the size of the effect.** A tiny effect in a huge test has a tiny p-value; a large effect in
  a small test can have a large one;
- **not a measure of importance.** Lesson 22 of `statistics` is about exactly this gap.

Below 0.05, the plan of lesson 7 calls the result significant. That is a decision rule, useful
because it was fixed in advance. It is not a description of how sure anybody should be.

## The interval

**The 95% confidence interval for the difference is the range of true effects the data is
compatible with.** Panela's runs from +0.03 to +0.76 points. It says three things the p-value
cannot:

- **zero is outside it**, which is the same finding as p below 0.05, seen from the other side;
- **the effect could be very small**: 0.03 points is a lift nobody would pay to build;
- **the effect could be larger than the plan's minimum**: 0.6 points is inside the range.

So the honest summary of the three weeks is not "the new checkout wins" but **"the new checkout is
probably better, by somewhere between almost nothing and three quarters of a point"**. The interval
carries the uncertainty that the word "significant" throws away, and it is what should be on the
slide.
