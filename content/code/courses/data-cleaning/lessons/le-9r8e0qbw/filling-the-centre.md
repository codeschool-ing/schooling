---
title: Filling with the centre, and what it does to the spread
version: 1
---

**Filling a blank with the mean or the median keeps the average where it was and shrinks
everything else.** Every filled row lands at the same value, in the middle, so the spread falls,
correlations weaken and any count of extremes is understated. Whether that matters depends on what
the column will be used for.

The delivery times again:

```python
from minutes import own, report

report("recorded only", own["minutes"].dropna())
report("blanks as the mean", own["minutes"].fillna(own["minutes"].mean()))
report("blanks as the median", own["minutes"].fillna(own["minutes"].median()))
```

```
ana@lab:~/clean$ python fill_centre.py
recorded only          mean  59.4  sd 21.1  late 10.5%
blanks as the mean     mean  59.4  sd 20.8  late 10.2%
blanks as the median   mean  59.3  sd 20.8  late 10.2%
```

Filled with the mean, the mean does not move — it cannot, since every new value equals it. The
standard deviation falls from 21.1 to 20.8. And the share of late deliveries falls from 10.5% to
10.2%, because 456 deliveries of two hours or more were moved to 59 minutes. **For MNAR blanks the
centre is the wrong guess in a known direction**: lesson 3 established that every missing value is
at least 120.

## Measured against the truth

Birth years are a fairer test, because nothing in lesson 3 suggested that the blanks hide older or
younger customers. The lab's truth file has every real birth year, so each fill can be scored:

```schooling-example
{
  "language": "python",
  "file": "birth_impute.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom customers import customers\n\n"
    },
    {
      "code": "truth = pd.read_csv(\"/var/lib/clean-data/truth/people.csv\", dtype={\"birth_year\": \"Int64\"})\nboth = customers.merge(truth[[\"customer_id\", \"birth_year\"]], on=\"customer_id\",\n                       suffixes=(\"\", \"_true\"))\n",
      "note": "**The lab's truth file**, joined by customer id. No real data set has this column; it is what lets each fill be scored."
    },
    {
      "code": "blank = both[\"birth_year\"].isna()\nfills = {\n    \"true values\": both[\"birth_year_true\"],\n",
      "note": "The true values, as the yardstick."
    },
    {
      "code": "    \"overall median\": both[\"birth_year\"].fillna(both[\"birth_year\"].median()),\n",
      "note": "**The overall median** for every blank."
    },
    {
      "code": "    \"median by channel\": both[\"birth_year\"].fillna(\n        both.groupby(\"signup_channel\")[\"birth_year\"].transform(\"median\")),\n",
      "note": "The median of the customer's own signup channel, the simplest imputation from similar rows."
    },
    {
      "code": "    \"random draw\": both[\"birth_year\"].fillna(pd.Series(\n        both[\"birth_year\"].dropna().sample(blank.sum(), replace=True, random_state=1).values,\n        index=both.index[blank])),\n}\n",
      "note": "**A random draw** from the years that were recorded, with a fixed seed so the run repeats."
    },
    {
      "code": "for label, filled in fills.items():\n    error = (filled[blank] - both.loc[blank, \"birth_year_true\"]).abs().mean()\n    print(f\"{label:18} mean {filled.mean():6.1f}  sd {filled.std():4.1f}  \"\n          f\"error on the filled rows {error:4.1f}\")\n",
      "note": "For each fill, the mean and spread of the whole column, and the average error on the rows that were filled."
    }
  ]
}
```

```
ana@lab:~/clean$ python birth_impute.py
true values        mean 1979.7  sd 16.2  error on the filled rows  0.0
overall median     mean 1979.8  sd 13.3  error on the filled rows 14.1
median by channel  mean 1979.9  sd 13.3  error on the filled rows 14.1
random draw        mean 1979.7  sd 16.3  error on the filled rows 18.9
```

Read the columns separately, because they answer different questions:

- **the mean** survives every fill: 1979.7 against 1979.8, 1979.9 and 1979.7;
- **the spread** shrinks with the median, from 16.2 to 13.3 years, and survives the random draw;
- **the error per row** is 14.1 years with the median and 18.9 with a random draw.

No fill gets an individual birth year right; the median is wrong by fourteen years on average.
**Imputation is for summaries, never for the person in the row.** The median serves an average and
damages a spread; a random draw from the observed values — called a hot deck — keeps the spread and
is worse for each row. Filling by channel changed nothing here, which is itself a finding: the
channel carries no information about age in this data, so it cannot help predict it.
