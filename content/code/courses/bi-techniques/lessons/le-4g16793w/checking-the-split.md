---
title: Checking the split before reading the result
version: 1
---

Before anybody looks at conversion, two checks say whether the randomisation worked. They take a
minute and they catch the failures that make every later number meaningless.

```schooling-example
{"language": "python", "file": "srm.py", "parts": [{"code": "import pandas as pd\nfrom scipy.stats import chisquare\n\nvisits = pd.read_csv(\"experiment.csv\")\ncounts = visits[\"group\"].value_counts()\nprint(counts.to_string())\nresult = chisquare(counts.values)\nprint(f\"chi-square {result.statistic:.2f}, p = {result.pvalue:.3f}\")", "note": "The test for sample ratio mismatch: a chi-square test comparing the observed group sizes with an even split, the test of `statistics` lesson 16."}, {"code": "print(\"\\nshare on mobile, by group\")\nprint(visits.groupby(\"group\")[\"device\"].apply(lambda d: (d == \"mobile\").mean()).round(4).to_string())", "note": "A balance check: something the treatment cannot change should be the same in both groups."}, {"code": "broken = chisquare([50412, 48950])\nprint(f\"\\nanother test, 50,412 against 48,950: chi-square {broken.statistic:.2f}, p = {broken.pvalue:.1e}\")", "note": "The same check on the counts of a test whose split was broken."}], "output": "group\nnew    25392\nold    25008\nchi-square 2.93, p = 0.087\n\nshare on mobile, by group\ngroup\nnew    0.6802\nold    0.6806\n\nanother test, 50,412 against 48,950: chi-square 21.51, p = 3.5e-06"}
```

## Sample ratio mismatch

Panela's test planned an even split and got **25,392 visitors in the new group and 25,008 in the
old**. The chi-square test asks how surprising a gap that size is if the split were really fair:
p = 0.087. A fair coin produces a gap like that more than one time in twelve, so there is no
evidence of a problem.

The second test is different: p = 3.5 × 10⁻⁶, a gap a fair split would produce a few times in a million.
That is a **sample ratio mismatch**, SRM, and when it happens **the test's result is not
interpreted, whatever it says**. A broken split almost always means some visitors were lost from one
group and not the other, and the lost ones are rarely a random sample: a treatment page that crashes
on old phones loses exactly the visitors least likely to buy, and the treatment looks better for it.

Common causes worth knowing, because the fix is in the plumbing, not in the statistics:

- the treatment page loads more slowly and some visitors leave before they are counted;
- a bot or a crawler is filtered in one group and not the other;
- the assignment happens after a redirect that one group's browsers do not follow;
- the test was switched on for one group a few hours before the other.

Because the check is so cheap, **a strict threshold is used**, often p below 0.001: a real SRM
produces tiny p-values, and the check should not raise false alarms in test after test.

## Balance

The second check compares something the treatment cannot affect. The share of visitors on a phone
was 0.6802 in the new group and 0.6806 in the old, four ten-thousandths apart. A difference
here, in a characteristic fixed before the visitor saw anything, would mean the groups were built
differently. Checking one or two such characteristics is cheap insurance; checking twenty and
reporting the one that differs is lesson 11's problem in another form.
