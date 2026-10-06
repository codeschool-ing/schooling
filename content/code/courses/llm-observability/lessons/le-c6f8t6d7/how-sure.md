---
title: How sure a sample can be
version: 1
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
ana@lab:~/obs$ python sizes.py
n =    50   a pass rate of 70% is known to within 12.7%
n =   100   a pass rate of 70% is known to within  9.0%
n =   400   a pass rate of 70% is known to within  4.5%
n =  1000   a pass rate of 70% is known to within  2.8%
n =  4000   a pass rate of 70% is known to within  1.4%
```

**Halving the error takes four times the sample.** A hundred replies give ±9 points; four hundred give
±4.5; a thousand, ±2.8. That arithmetic decides most practical questions:

- **To see a fall of 14 points**, as this week's release caused, a hundred replies per release would
  have done, just. The uniform tenth had 92 and 37, which is why its intervals overlapped.
- **To see a fall of 3 points**, nearly two thousand per period are needed, because both rates carry
  an error and the two add up. At this shop's volume that is more than a week of traffic, and judging
  all of it may be cheaper than waiting.
- **The size of the traffic does not matter**, as long as the sample is a small part of it. Four hundred
  replies say as much about a million as about ten thousand.

## Comparing two rates

"Did the release make it worse" is a question about two rates, and the honest answer comes from two
intervals: if they do not overlap, yes; if they overlap a lot, the sample cannot say. With the whole week,
73.5% to 79.4% against 57.6% to 66.7%: no overlap, the release made relevance worse by judge-1's
measure. With the uniform tenth, 65.3% to 82.7% against 40.9% to 71.3%: a large overlap, and the right
report is "probably worse, not shown". Lesson 14 does this properly for a change tested before release,
on the evaluation set, with a test made for two measurements of the same questions.
