---
title: Parsing by source, with the format written down
version: 1
---

**The fix for ambiguous dates is to parse each source with its own format, stated explicitly.** Not
`dayfirst=True` for the whole column and not the parser's guess, but a table of which system writes
which convention, applied row by row:

```schooling-example
{
  "language": "python",
  "file": "dates.py",
  "parts": [
    {
      "code": "import pandas as pd\n\ncustomers = pd.read_csv(\"raw/customers.csv\", dtype=str, keep_default_na=False,\n                        na_values=[\"\"]).drop_duplicates()\n"
    },
    {
      "code": "FORMATS = {\"site\": \"%Y-%m-%d\", \"app\": \"%m/%d/%Y\", \"store\": \"%d/%m/%Y\"}\n\n\n",
      "note": "**The convention of each source, written down**, proved in the previous section by counting witnesses."
    },
    {
      "code": "def parse(row):\n    text = row[\"signed_up\"]\n"
    },
    {
      "code": "    if row[\"signup_channel\"] in FORMATS:\n        return pd.to_datetime(text, format=FORMATS[row[\"signup_channel\"]], errors=\"coerce\")\n",
      "note": "A known source is parsed with its own format."
    },
    {
      "code": "    # the 2023 migration copied all three systems' records\n",
      "note": "The migration mixed all three conventions, so each of its values is decided on its own."
    },
    {
      "code": "    if \"-\" in text:\n        return pd.to_datetime(text, format=\"%Y-%m-%d\")\n",
      "note": "A hyphen means ISO, which has only one reading."
    },
    {
      "code": "    first, second = int(text[:2]), int(text[3:5])\n    if first > 12:\n        return pd.to_datetime(text, format=\"%d/%m/%Y\")\n    if second > 12:\n        return pd.to_datetime(text, format=\"%m/%d/%Y\")\n",
      "note": "A number above 12 is a witness: in first place it is a day, in second place the second number is a day."
    },
    {
      "code": "    return pd.NaT  # both readings are dates: nothing in the value decides\n\n\n",
      "note": "**When both numbers are 12 or less, nothing decides**, and the value stays blank instead of guessed."
    },
    {
      "code": "customers[\"signed\"] = customers.apply(parse, axis=1)\n",
      "note": "One parsed date per customer."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from dates import customers as c; print(c['signed'].isna().sum()); print(c.groupby('signup_channel')['signed'].agg(['min', 'max', 'count']))"
10
                      min        max  count
signup_channel                             
app            2023-03-01 2025-12-10    723
import-2023    2023-02-10 2023-09-26     35
site           2023-01-19 2025-12-10   1003
store          2023-02-20 2025-12-10    605
```

Ten values are left as `NaT`, pandas' missing date, and the minimum and maximum of every source are
plausible: nothing before 2023, when Quitanda Verde's records begin, and nothing after 10 December,
when the customer file was exported. **The minimum and maximum after parsing are the cheapest check
there is**: a wrong format produces dates in the future, or a cluster in January from a day-first
string read as month first.

The ten are the migration's honest residue:

```
ana@lab:~/clean$ python -c "from dates import customers as c; m = c[c['signed'].isna()]; print(m[['customer_id', 'signed_up', 'signup_channel']].head(4).to_string(index=False))"
customer_id  signed_up signup_channel
     C00012 03/06/2023    import-2023
     C00013 03/07/2023    import-2023
     C00054 01/06/2023    import-2023
     C00074 06/07/2023    import-2023
```

`03/06/2023` is the 3rd of June or the 6th of March, and both are dates the migration could have
held. **Nothing in the value decides, so the parser does not decide either.** The code says so in a
comment, and the count says how many: ten of 2,376, left blank rather than guessed. Somebody who
knows where each migrated record came from can fill them in; nobody should flip a coin for them.

## The same in SQL

`to_date` takes the format as its second argument, and a `CASE` chooses it by source:

```
ana@lab:~/clean$ psql -c "SELECT signup_channel, min(d), max(d) FROM (SELECT signup_channel, CASE signup_channel WHEN 'site' THEN to_date(signed_up, 'YYYY-MM-DD') WHEN 'app' THEN to_date(signed_up, 'MM/DD/YYYY') WHEN 'store' THEN to_date(signed_up, 'DD/MM/YYYY') END AS d FROM raw.customers) t GROUP BY 1"
 signup_channel |    min     |    max     
----------------+------------+------------
 site           | 2023-01-19 | 2025-12-10
 app            | 2023-03-01 | 2025-12-10
 import-2023    |            | 
 store          | 2023-02-20 | 2025-12-10
(4 rows)
```

The three ordinary sources agree with pandas exactly. The migration comes out blank because the
`CASE` gives it no format, which is the right default: a source with mixed conventions gets no
format until somebody writes the rule for it. **Never set a global date style and let it read
everything**; the database lesson 1 made is set to `DMY`, and a `::date` cast would have read every
app date day first without a word.