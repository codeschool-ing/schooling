---
title: Filling with a constant
version: 1
---

**A constant is the right fill when the meaning of the blank is known and is that constant.** The
website's blank discount is zero, so zero is not an estimate; it is the value. Everywhere else, a
constant is a guess that every row will share.

The commonest wrong constant is zero for a number. Filling the own fleet's missing delivery times
with zero:

```schooling-example
{
  "language": "python",
  "file": "minutes.py",
  "parts": [
    {
      "code": "import pandas as pd\n\norders = pd.read_csv(\"raw/orders.csv\", dtype=str, keep_default_na=False,\n                     na_values=[\"\"]).drop_duplicates()\n",
      "note": "The orders without their repeats, read as text."
    },
    {
      "code": "own = orders[(orders[\"courier\"] == \"propria\") & (orders[\"status\"] != \"cancelled\")].copy()\nown[\"minutes\"] = pd.to_numeric(own[\"delivery_minutes\"])\n\n\n",
      "note": "The own fleet's deliveries, cancelled orders left out, with the time as a number and the blanks as `NaN`."
    },
    {
      "code": "def report(label, minutes):\n    print(f\"{label:22} mean {minutes.mean():5.1f}  sd {minutes.std():4.1f}  \"\n          f\"late {(minutes >= 90).mean() * 100:4.1f}%\")\n",
      "note": "**One line per strategy**: the mean, the spread and the share of late deliveries, which is what the operations report reads. The same three numbers for every fill makes them comparable."
    }
  ]
}
```

```python
from minutes import own, report

report("recorded only", own["minutes"].dropna())
report("blanks as zero", own["minutes"].fillna(0))
```

```
ana@lab:~/clean$ python fill_zero.py
recorded only          mean  59.4  sd 21.1  late 10.5%
blanks as zero         mean  57.7  sd 23.1  late 10.2%
```

The mean drops from 59.4 to 57.7 minutes and the share of late deliveries from 10.5% to 10.2%. **456
deliveries that took two hours or more are now recorded as instantaneous** — the exact opposite of
what happened — and every summary moves in the flattering direction. It looks like a small effect
because 456 rows are 3% of the column; per row, it is the largest error any strategy could make.

Constants that are right more often:

| blank | constant | why it is right |
|---|---|---|
| a website discount | `0` | the source writes no coupon as a blank |
| a category nobody recorded | `unknown` | it keeps the row and says plainly what is not known |
| a count of events in a period with no events | `0` | no event happened, so the count is zero |

The second row is the general lesson. **For a label, the honest constant is a word that says the
value is unknown**, and a chart that shows an `unknown` bar is a chart telling the truth about its
data. For a number there is no such word, which is why flags exist — the last of this lesson's
moves.
