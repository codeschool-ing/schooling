---
title: Melting, and the column that is not a month
version: 1
---

Going from wide to long is called **melting** in pandas, `pivot_longer` in R and **unpivoting** in
Power Query and SQL. In pandas it is one call: name the columns that identify a row, and every other
column is folded into two, one for the old header and one for the value.

The obvious call, on the file as it is:

```
ana@lab:~/clean$ python -c "import pandas as pd; w = pd.read_csv('raw/targets_2025.csv'); long = w.melt(id_vars='loja', var_name='month', value_name='target'); print(len(long)); print(long['target'].sum(), w['Total'].sum())"
78
7602000 3801000
```

78 rows, not 72, and a yearly target of R$ 7,602,000 where the sheet says R$ 3,801,000. **`Total`
melted along with the months**: it became a thirteenth "month" for every shop, and every sum over
the long table now counts the year twice. Nothing failed. A chart of targets by month would even
look sensible, with one strange bar at the end that somebody might take for a forecast.

A total stored as a column is a **second record of the same fact**, which is exactly what lesson 9
used to catch the typed totals. So the right move is not to drop it blindly, but to check it first
and drop it after:

```schooling-example
{
  "language": "python",
  "file": "targets.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "wide = pd.read_csv(\"raw/targets_2025.csv\", dtype=str).set_index(\"loja\").astype(int)\n",
      "note": "The sheet as integers, one row per shop."
    },
    {
      "code": "MONTHS = [c for c in wide.columns if c != \"Total\"]\n",
      "note": "Every column except `Total`."
    },
    {
      "code": "# The Total column is a second record of the same targets: check it, then leave it behind.\noff = wide[MONTHS].sum(axis=1) != wide[\"Total\"]\nif off.any():\n    raise ValueError(f\"Total disagrees with the months for {list(wide.index[off])}\")\n\n",
      "note": "**The check**: each shop's months must add up to its `Total`. If not, stop and name the shop."
    },
    {
      "code": "MES = {\"jan\": 1, \"fev\": 2, \"mar\": 3, \"abr\": 4, \"mai\": 5, \"jun\": 6,\n       \"jul\": 7, \"ago\": 8, \"set\": 9, \"out\": 10, \"nov\": 11, \"dez\": 12}\n",
      "note": "**The months spelled out**, so no locale decides what `fev` means."
    },
    {
      "code": "targets = wide[MONTHS].reset_index().melt(id_vars=\"loja\", var_name=\"header\", value_name=\"target\")\n",
      "note": "**The melt**, of the months only: one row per shop and month."
    },
    {
      "code": "number = targets[\"header\"].str[:3].map(MES)\n",
      "note": "Each header's month number, from the dictionary."
    },
    {
      "code": "if number.isna().any():\n    raise ValueError(f\"unknown month headers: {sorted(targets.loc[number.isna(), 'header'].unique())}\")\n",
      "note": "**An unknown header stops the script** instead of becoming a blank month."
    },
    {
      "code": "year = 2000 + targets[\"header\"].str[-2:].astype(int)\ntargets[\"month\"] = pd.PeriodIndex.from_fields(year=year, month=number, freq=\"M\")\ntargets = targets.drop(columns=\"header\")\n",
      "note": "The year from the last two characters, and the two made into a `period[M]`; the text header goes."
    }
  ]
}
```

The first half of the file is that check. If any shop's `Total` disagrees with its months, the
script stops and names the shop, because then either a month or the total was typed wrong, and the
people who keep the sheet need to say which. Here every total agrees, so the months are melted
alone, and the long table sums to the sheet's own total:

```
ana@lab:~/clean$ python -c "from targets import targets; print(len(targets), targets['target'].sum()); print(targets.head(3).to_string(index=False)); print(targets['month'].dtype)"
72 3801000
     loja  target   month
Pinheiros   52000 2025-01
   Cambuí   14000 2025-01
 Botafogo   23000 2025-01
period[M]
```

72 rows and R$ 3,801,000. **Count the rows and sum the values after every reshape**: a melt must
produce rows times columns, and the sum must not move. Both numbers are cheap, and between them
they catch the stray total, a forgotten column and a duplicated shop.
