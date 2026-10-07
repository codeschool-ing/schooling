---
title: In pandas
version: 1
---

```schooling-example
{
  "language": "python",
  "file": "task.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "orders = pd.read_csv(\"raw/orders.csv\", dtype=str).drop_duplicates()\n",
      "note": "Everything as text, and **exact repeated rows removed**, comparing every column."
    },
    {
      "code": "orders = orders[orders[\"status\"] == \"delivered\"].copy()\n",
      "note": "Delivered orders only."
    },
    {
      "code": "orders[\"total\"] = pd.to_numeric(orders[\"total\"]).clip(lower=0)\n",
      "note": "**A negative total becomes zero.**"
    },
    {
      "code": "site = orders[\"channel\"] == \"site\"\nutc = pd.to_datetime(orders.loc[site, \"ordered_at\"], format=\"%Y-%m-%dT%H:%M:%SZ\", utc=True)\norders.loc[site, \"placed\"] = utc.dt.tz_convert(\"America/Sao_Paulo\").dt.tz_localize(None)\norders.loc[~site, \"placed\"] = pd.to_datetime(orders.loc[~site, \"ordered_at\"],\n                                              format=\"%Y-%m-%d %H:%M:%S\")\n",
      "note": "**The two clocks**: the site's UTC times converted to São Paulo, the app's read as they are."
    },
    {
      "code": "december = pd.to_datetime(orders[\"placed\"]) >= \"2025-12-01\"\n\n",
      "note": "December, in local time."
    },
    {
      "code": "result = orders.groupby(\"channel\").agg(orders=(\"total\", \"size\"), revenue=(\"total\", \"sum\"))\nresult[\"december\"] = orders[december].groupby(\"channel\")[\"total\"].sum()\nprint(result.round(2).to_string())\n",
      "note": "Orders and revenue per channel, and December's revenue beside them."
    }
  ]
}
```

```
ana@lab:~/clean$ python task.py
         orders     revenue   december
channel                               
app       11851  1065555.60  132925.45
site      14659  1436387.75  281616.15
```

The same numbers, to the centavo. The structure is the one this course has used throughout: read
everything as text, decide each type on purpose, and only then compute.

What pandas brings that SQL does not is the space between the steps. **Every intermediate result is
a table you can look at**, print, count and plot, which is why the exploration of lesson 15 and the
fuzzy matching of lesson 5 were written in it. What it asks in return is discipline about the
defaults: `read_csv` guesses types unless told not to, `errors="coerce"` hides what it loses, and
`groupby` drops blank keys unless `dropna=False` is passed. Each of those was a lesson of its own.

The money here is a float, unlike SQL's `numeric`. For sums of a few thousand values that rounds to
the same centavo, as the output shows; lesson 7 converted the shops' amounts with `Decimal`
precisely because a long enough chain of float arithmetic eventually does not.
