---
title: The calculation, by hand and by library
version: 1
---

The arithmetic is short enough to write out, and writing it out is the best way to see which input
does what.

```schooling-example
{"language": "python", "file": "samplesize.py", "parts": [{"code": "from math import ceil, sqrt\n\nfrom scipy.stats import norm\nfrom statsmodels.stats.power import NormalIndPower\nfrom statsmodels.stats.proportion import proportion_effectsize\n\nbaseline, mde = 0.042, 0.006\nalpha, power = 0.05, 0.80\np1, p2 = baseline, baseline + mde", "note": "The four inputs. `p1` is the control's rate and `p2` the treatment's if the effect is exactly the MDE."}, {"code": "z_alpha = norm.ppf(1 - alpha / 2)\nz_power = norm.ppf(power)\npooled = (p1 + p2) / 2\nn = (z_alpha * sqrt(2 * pooled * (1 - pooled))\n     + z_power * sqrt(p1 * (1 - p1) + p2 * (1 - p2))) ** 2 / mde ** 2\nprint(f\"z for alpha {z_alpha:.3f}, z for power {z_power:.3f}\")\nprint(f\"by hand:     {ceil(n):,} visitors in each group\")", "note": "The standard formula for comparing two proportions. `norm.ppf` turns a probability into a distance on the normal curve: 1.96 for a two-sided 5 per cent, 0.84 for 80 per cent power. The square of the MDE in the denominator is the line to remember."}, {"code": "effect = proportion_effectsize(p2, p1)\nn_sm = NormalIndPower().solve_power(effect_size=effect, alpha=alpha, power=power)\nprint(f\"statsmodels: {ceil(n_sm):,} visitors in each group (effect size h = {effect:.4f})\")", "note": "statsmodels does it through Cohen's h, an effect size that rescales the two proportions so the variance is the same everywhere. A slightly different approximation, so a slightly different number."}], "output": "z for alpha 1.960, z for power 0.842\nby hand:     18,739 visitors in each group\nstatsmodels: 18,719 visitors in each group (effect size h = 0.0290)"}
```

**About nineteen thousand visitors in each group**, 18,739 by the textbook formula and 18,719 by statsmodels'
approximation. The difference of 20 visitors does not matter: a sample size is a planning
number, and the convention is to take the larger and round up.

Read the formula once more for its shape. The numerator is the noise: two z-values for the two
risks, times the spread of a proportion near 4 per cent. The denominator is the signal, the MDE,
**squared**. Everything else being equal, the sample grows with the square of how small an effect
you want to see.

## Where the formula comes from

`statistics` lesson 12 gave the standard error of a proportion, `sqrt(p(1 − p)/n)`. The test of
lesson 10 will compare the difference of two rates with its standard error; the sample size is the
`n` at which a true difference of exactly the MDE sits far enough from zero that, 80 per cent of the
time, it lands beyond the 5 per cent threshold. The two z-values are those two distances, added.
