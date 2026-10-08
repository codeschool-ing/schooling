---
title: How sure a sample can be
version: 2
---

A pass rate from a sample is an estimate, and every estimate needs its error beside it. `grade_sample.py`
prints a **Wilson interval**: the range in which the true pass rate lies, at 95% confidence, given how
many replies passed out of how many were graded. It behaves better than the textbook `p ± 1.96 ×
√(p(1-p)/n)` at small samples and near 0% or 100%, which is where evaluation results often are; the
code is ten lines in `grade_sample.py`.

How wide the interval is depends on the number graded, and not on the size of the traffic. `sizes.py`
prints the half-width for a pass rate of 70% at five sample sizes:

```python
"""sizes.py: how close a sample of n replies gets to a true pass rate of 70%, at 95%."""
import math

for n in (50, 100, 400, 1000, 4000):
    print(f"n = {n:5}   a pass rate of 70% is known to within {1.96 * math.sqrt(0.7 * 0.3 / n):5.1%}")
```

```
ana@dev:~/obs$ python sizes.py
n =    50   a pass rate of 70% is known to within 12.7%
n =   100   a pass rate of 70% is known to within  9.0%
n =   400   a pass rate of 70% is known to within  4.5%
n =  1000   a pass rate of 70% is known to within  2.8%
n =  4000   a pass rate of 70% is known to within  1.4%
```

**Halving the error takes four times the sample.** A hundred replies give ±9 points; four hundred give
±4.5; a thousand, ±2.8. That arithmetic decides most practical questions:

- **To see a fall of 9 points**, as this week's release shows, several hundred replies per release
  are needed. The week had 134 and 141, which is why even grading all of it leaves the intervals
  overlapping, and the uniform tenth had 10 and 13, which says nothing at all.
- **To see a fall of 3 points**, a few thousand per period are needed, because both rates carry an
  error and the two add up. At this shop's volume that is months of traffic, and a team that needs to
  know sooner has to grade the evaluation set instead, where the questions are the same on both sides.
- **The size of the traffic does not matter**, as long as the sample is a small part of it. Four hundred
  replies say as much about a million as about ten thousand.

## Comparing two rates

"Did the release make it worse" is a question about two rates, and the honest answer comes from two
intervals: if they do not overlap, yes; if they overlap a lot, the sample cannot say. With the whole
week, 35.2% to 51.7% against 26.7% to 42.2%: they overlap, and the right report is "probably worse by
this judge's measure, not shown", even with every reply graded. **The week is the limit, not the
sample.** Lesson 14 answers the question properly for a change tested before release, on the
evaluation set, with a test made for two measurements of the same questions.
