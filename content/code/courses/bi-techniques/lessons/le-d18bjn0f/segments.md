---
title: The segment that won
version: 1
---

The commonest form of the problem is the breakdown. A test that won overall is sliced by device,
weekday or region to see "where it worked", and some slice always stands out.

```schooling-example
{"language": "python", "file": "segments.py", "parts": [{"code": "import pandas as pd\nfrom statsmodels.stats.multitest import multipletests\nfrom statsmodels.stats.proportion import proportions_ztest\n\nvisits = pd.read_csv(\"experiment.csv\", parse_dates=[\"day\"])\nvisits[\"weekday\"] = visits[\"day\"].dt.day_name().str[:3]", "note": "Add the weekday, a natural way to slice a test."}, {"code": "rows = []\nfor column in (\"device\", \"weekday\"):\n    for value, part in visits.groupby(column):\n        g = part.groupby(\"group\")[\"converted\"].agg([\"sum\", \"count\"])\n        _, p = proportions_ztest(g[\"sum\"].values, g[\"count\"].values)\n        lift = (g.loc[\"new\", \"sum\"] / g.loc[\"new\", \"count\"] - g.loc[\"old\", \"sum\"] / g.loc[\"old\", \"count\"])\n        rows.append((f\"{column}={value}\", round(100 * lift, 2), p))", "note": "The same z-test as lesson 10, run separately in each of nine segments: two devices and seven weekdays."}, {"code": "table = pd.DataFrame(rows, columns=[\"segment\", \"lift, points\", \"p\"])\ntable[\"Holm\"] = multipletests(table[\"p\"], method=\"holm\")[1]\nprint(table.round(3).to_string(index=False))\nprint(f\"\\nsignificant at 5%: {(table['p'] < 0.05).sum()} of {len(table)} segments; \"\n      f\"after Holm: {(table['Holm'] < 0.05).sum()}\")", "note": "`multipletests` adjusts the nine p-values for having made nine comparisons. Holm's method is explained in the next section."}], "output": "       segment  lift, points     p  Holm\ndevice=desktop         -0.07 0.825 1.000\n device=mobile          0.62 0.006 0.056\n   weekday=Fri          0.14 0.771 1.000\n   weekday=Mon          0.31 0.531 1.000\n   weekday=Sat          0.08 0.879 1.000\n   weekday=Sun          0.07 0.884 1.000\n   weekday=Thu          0.51 0.313 1.000\n   weekday=Tue          0.70 0.136 0.954\n   weekday=Wed          0.96 0.046 0.364\n\nsignificant at 5%: 2 of 9 segments; after Holm: 0"}
```

Two of the nine segments are significant on their own. One of them is the kind of result that ends
up on a slide: **on mobile, the new checkout lifted conversion by 0.62 points, p = 0.006**, while on
desktop it did nothing. It matches lesson 7's hypothesis, that the old form lost people on phones,
almost too well.

**It is noise.** `panela.py` gives the new page exactly the same effect on every device; it does not
look at the device when deciding who converts. A phone gap this large appeared by chance among nine
slices, and the Wednesday result, 0.96 points with p = 0.046, is the same thing on a weekday nobody
had a theory about. After the correction in the last column, **neither is significant**: the mobile
segment's adjusted p is 0.056.

The mobile finding is dangerous precisely because it fits a story. A segment that confirms what the
team already believed is checked less than one that surprises them, and it is exactly as likely to
be chance. The honest use of it is a new hypothesis, "the one-step checkout helps more on phones",
tested in a new experiment designed for that question.
