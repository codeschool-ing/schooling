---
title: The numbers, all of them
version: 1
---

Lesson 9's checks passed: the split was fair and the groups balanced. Only now is conversion looked
at. **A result is reported as counts, rates, the difference with its interval, and the test**, never
as a p-value alone and never as a relative lift alone.

```schooling-example
{"language": "python", "file": "result.py", "parts": [{"code": "import pandas as pd\nfrom statsmodels.stats.proportion import confint_proportions_2indep, proportions_ztest\n\nvisits = pd.read_csv(\"experiment.csv\", parse_dates=[\"day\"])"}, {"code": "def compare(data, label):\n    groups = data.groupby(\"group\")[\"converted\"].agg([\"sum\", \"count\"])\n    new, old = groups.loc[\"new\"], groups.loc[\"old\"]\n    rate_new, rate_old = new[\"sum\"] / new[\"count\"], old[\"sum\"] / old[\"count\"]", "note": "For each group, the visitors who converted and the visitors in total."}, {"code": "    z, p = proportions_ztest([new[\"sum\"], old[\"sum\"]], [new[\"count\"], old[\"count\"]])\n    low, high = confint_proportions_2indep(new[\"sum\"], new[\"count\"], old[\"sum\"], old[\"count\"])", "note": "The two-proportion z-test of `statistics` lesson 16, two-sided by default, and a 95% confidence interval for the difference between the two rates."}, {"code": "    print(label)\n    print(f\"  old {old['sum']:,} of {old['count']:,} = {rate_old:.2%}\")\n    print(f\"  new {new['sum']:,} of {new['count']:,} = {rate_new:.2%}\")\n    print(f\"  difference {100 * (rate_new - rate_old):+.2f} points, \"\n          f\"95% interval {100 * low:+.2f} to {100 * high:+.2f}\")\n    print(f\"  relative lift {rate_new / rate_old - 1:+.1%}, z = {z:.2f}, p = {p:.3f}\")", "note": "Everything a reader needs: counts, rates, the difference in points with its interval, the relative lift, and the test."}, {"code": "compare(visits, \"all three weeks\")\ncompare(visits[visits[\"day\"] >= \"2025-03-17\"], \"weeks 2 and 3 only\")", "note": "The whole test, as planned, and the two weeks after the novelty of lesson 9."}], "output": "all three weeks\n  old 1,070 of 25,008 = 4.28%\n  new 1,187 of 25,392 = 4.67%\n  difference +0.40 points, 95% interval +0.03 to +0.76\n  relative lift +9.3%, z = 2.15, p = 0.032\nweeks 2 and 3 only\n  old 711 of 16,688 = 4.26%\n  new 733 of 16,912 = 4.33%\n  difference +0.07 points, 95% interval -0.36 to +0.51\n  relative lift +1.7%, z = 0.33, p = 0.739"}
```

Over the three weeks, as planned, **the new checkout converted 4.67% of visitors and the old one
4.28%**: a difference of +0.40 points, or +9.3% in relative terms. The test gives z = 2.15 and
p = 0.032.

In the last two weeks, after the novelty had faded, the difference is +0.07 points, with an interval
from −0.36 to +0.51, and p = 0.739.

The control converted at 4.28%, close to the 4.2 per cent the plan assumed in lesson 8, so the test
had about the power it was designed for. That check is worth making every time: a baseline far from
the plan's means the test was really sized for a different effect.

The next three sections read these lines one at a time.
