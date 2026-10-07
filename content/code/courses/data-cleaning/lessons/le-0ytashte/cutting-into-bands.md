---
title: Cutting a number into bands
version: 1
---

**Binning** turns a number into a category: ages into bands, spending into tiers, delivery times
into on time and late. Reports need it, because nobody reads a table with one row per age. It is
also the transformation with the most ways to be quietly wrong, and the first is the edge.

```
ana@lab:~/clean$ python -c "import pandas as pd; from per_customer import per; a = per['age']; print((a == 25).sum()); print(pd.cut(a[a == 25], [18, 25, 35]).value_counts().to_string())"
35
age
(18, 25]    35
(25, 35]     0
```

35 customers were born in 2000 and turn 25 in 2025, and `pd.cut` with edges 18, 25 and 35 puts every one of them in the
**first** band. By default an interval is closed on the right, `(18, 25]`: it excludes 18 and
includes 25. Label that band "18-24", as most reports would, and 35 people are in a band their age
is not in.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-bin-edges\" aria-label=\"Two ways of cutting ages at 18, 25 and 35. With pandas' default, the bands are (18, 25] and (25, 35], so an age of exactly 25 falls in the first band. With right=False they are [18, 25) and [25, 35), so 25 starts the second band, which matches labels such as 18-24 and 25-34.\"><path d=\"M314.1 30.0 L314.1 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"314.1\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">25</text><text x=\"20.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">default</text><path d=\"M170.0 57.0 L314.1 57.0\" stroke=\"var(--amber)\" stroke-width=\"3\" fill=\"none\"></path><circle cx=\"170.0\" cy=\"57.0\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><circle cx=\"314.1\" cy=\"57.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"242.1\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">(18, 25]</text><path d=\"M314.1 83.0 L520.0 83.0\" stroke=\"var(--phosphor)\" stroke-width=\"3\" fill=\"none\"></path><circle cx=\"314.1\" cy=\"83.0\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><circle cx=\"520.0\" cy=\"83.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"417.1\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">(25, 35]</text><text x=\"545.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">25 falls in the first band</text><text x=\"20.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">right=False</text><path d=\"M170.0 147.0 L314.1 147.0\" stroke=\"var(--phosphor)\" stroke-width=\"3\" fill=\"none\"></path><circle cx=\"170.0\" cy=\"147.0\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><circle cx=\"314.1\" cy=\"147.0\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"242.1\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">[18, 25)</text><path d=\"M314.1 173.0 L520.0 173.0\" stroke=\"var(--amber)\" stroke-width=\"3\" fill=\"none\"></path><circle cx=\"314.1\" cy=\"173.0\" r=\"5\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><circle cx=\"520.0\" cy=\"173.0\" r=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"417.1\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">[25, 35)</text><text x=\"545.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">25 starts the second band</text><path d=\"M128.8 222.0 L561.2 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M170.0 222.0 L170.0 226.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"170.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18</text><path d=\"M314.1 222.0 L314.1 226.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"314.1\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">25</text><path d=\"M520.0 222.0 L520.0 226.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"520.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">35</text></svg>", "caption": "A filled end is included and a hollow end is not. The edges are the same; one argument decides which side of 25 the 35 customers born in 2000 land on."}
```

The fix is to decide which side is closed and to write labels that match it:

```schooling-example
{
  "language": "python",
  "file": "bands.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom per_customer import per\n\n"
    },
    {
      "code": "EDGES = [18, 25, 35, 45, 55, 65, 75]\nLABELS = [\"18-24\", \"25-34\", \"35-44\", \"45-54\", \"55-64\", \"65-74\"]\n",
      "note": "**Edges and labels written together**, so they can be read against each other."
    },
    {
      "code": "per[\"age_band\"] = pd.cut(per[\"age\"], EDGES, right=False, labels=LABELS)\n",
      "note": "**`right=False`**: each band includes its lower edge, so 25 starts \"25-34\"."
    },
    {
      "code": "if per[\"age_band\"].isna().sum() != per[\"age\"].isna().sum():\n    raise ValueError(\"an age fell outside the edges\")\n",
      "note": "**The check**: every blank band must be an unknown age, or something fell off an edge."
    },
    {
      "code": "per[\"spend_tier\"] = pd.qcut(per[\"revenue\"], 4, labels=[\"low\", \"mid-low\", \"mid-high\", \"high\"])\n\n",
      "note": "**Quartiles**: four tiers with a quarter of the customers each, edges taken from the data."
    },
    {
      "code": "if __name__ == \"__main__\":\n    print(per[\"age_band\"].value_counts(sort=False, dropna=False).to_string())\n    print(per.groupby(\"spend_tier\", observed=True)[\"revenue\"].agg([\"size\", \"min\", \"max\"]).round(2).to_string())\n",
      "note": "How many in each band, and where each tier starts and ends."
    }
  ]
}
```

```
ana@lab:~/clean$ python bands.py
age_band
18-24    207
25-34    301
35-44    282
45-54    277
55-64    268
65-74    267
NaN      671
            size      min       max
spend_tier                         
low          569     0.00    424.75
mid-low      568   426.35    892.10
mid-high     568   893.25   1568.80
high         568  1569.75  35522.50
```

With `right=False` each band is `[a, b)`, so 25 starts the band labelled "25-34", and every label
is true. Two more things in that output are decisions, not accidents:

- **The 671 blanks are kept.** They are customers with no known age, and `pd.cut` leaves them
  blank rather than inventing a band. Any value outside the edges would be blank too, which is why
  the edges run from 18 to 75: the youngest customer is 19 and the oldest 73, and **the check in
  the code, that the blanks are exactly the unknown ages,** proves nothing fell off either end.
- **The spend tiers are quartiles**, cut by `pd.qcut` so each holds a quarter of the customers.
  The edges come from the data: "high" starts at R$ 1,569.75 this year and will start somewhere
  else next year. That is right for "the top quarter of customers" and wrong for "customers who
  spent over R$ 1,500", which needs fixed edges written by hand.

A band is a summary, and summaries lose detail: two customers aged 25 and 34 look the same once
banded. **Keep the original column next to the band**, and derive the band again whenever the
edges change, rather than editing labels in a report.
