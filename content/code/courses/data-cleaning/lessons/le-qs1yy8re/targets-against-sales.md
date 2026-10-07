---
title: Targets against sales
version: 1
---

The question the commercial team asked was never "what are the targets". It was "how did each shop
do against its target". With both tables long, that is a join on two columns:

```schooling-example
{
  "language": "python",
  "file": "actuals.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom money import reais\nfrom ready import orders\n\n",
      "note": "Lesson 7's `reais` and lesson 12's orders with their decided totals."
    },
    {
      "code": "shops = pd.read_csv(\"raw/store_sales.csv\", sep=\";\", encoding=\"latin-1\", dtype=str)\n",
      "note": "The shops' till file, Latin-1 and semicolons, as lesson 2 found it."
    },
    {
      "code": "shops[\"month\"] = pd.to_datetime(shops[\"data\"], format=\"%d/%m/%Y\").dt.to_period(\"M\")\n",
      "note": "Each sale's month, from its `dd/mm/yyyy` date."
    },
    {
      "code": "shops[\"amount\"] = shops[\"total\"].map(reais).astype(float)\n\n",
      "note": "Each amount in reais, through the function that refuses anything it cannot read."
    },
    {
      "code": "online = orders[orders[\"status\"] == \"delivered\"].copy()\n",
      "note": "**Only delivered orders**: a cancelled or refunded order is not a sale."
    },
    {
      "code": "online[\"loja\"] = \"Online\"\nonline[\"month\"] = online[\"placed\"].dt.to_period(\"M\")\nonline[\"amount\"] = online[\"total\"]\n\n",
      "note": "The online channel gets a shop name, a month and an amount, the same three columns as the shops."
    },
    {
      "code": "sales = pd.concat([shops[[\"loja\", \"month\", \"amount\"]], online[[\"loja\", \"month\", \"amount\"]]])\n",
      "note": "**One long table of sales**, both sources stacked."
    },
    {
      "code": "actuals = sales.groupby([\"loja\", \"month\"], as_index=False)[\"amount\"].sum()\n",
      "note": "**One row per shop and month**: the grain of the targets."
    }
  ]
}
```

```schooling-example
{
  "language": "python",
  "file": "attainment.py",
  "parts": [
    {
      "code": "from actuals import actuals\nfrom targets import targets\n\n",
      "note": "Both long tables."
    },
    {
      "code": "both = targets.merge(actuals, on=[\"loja\", \"month\"], how=\"left\", validate=\"one_to_one\",\n                     indicator=True)\n",
      "note": "**The join on two columns**, each target keeping its row, checked one to one, with an indicator."
    },
    {
      "code": "missing = both[both[\"_merge\"] == \"left_only\"]\nif len(missing):\n    raise ValueError(f\"targets with no sales: {missing[['loja', 'month']].values.tolist()}\")\n",
      "note": "**A target with no sales stops the script**, naming the shop and month."
    },
    {
      "code": "both[\"attainment\"] = both[\"amount\"] / both[\"target\"]\n\n",
      "note": "Attainment per shop and month: sales over target."
    },
    {
      "code": "if __name__ == \"__main__\":\n    year = both.groupby(\"loja\")[[\"target\", \"amount\"]].sum()\n    year[\"attainment\"] = (year[\"amount\"] / year[\"target\"]).round(3)\n    print(year.round(2).sort_values(\"attainment\").to_string())\n",
      "note": "**The year from the sums**, not from an average of monthly ratios."
    }
  ]
}
```

```
ana@lab:~/clean$ python attainment.py
            target      amount  attainment
loja                                      
Pinheiros   660000   631457.60        0.96
Savassi     204000   210877.70        1.03
Botafogo    294000   311434.20        1.06
Online     2286000  2493548.15        1.09
Cambuí      180000   199280.80        1.11
Batel       177000   195875.40        1.11
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l13-attainment\" aria-label=\"Horizontal bars of each shop's sales in 2025 as a share of its target, against a line at 100%: Pinheiros 96%, Savassi 103%, Botafogo 106%, Online 109%, Batel 111%, Cambuí 111%. Only Pinheiros is short of the line.\"><text x=\"120.0\" y=\"51.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Pinheiros</text><rect x=\"130.0\" y=\"40.0\" width=\"414.6\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.6\" y=\"51.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">96%</text><text x=\"120.0\" y=\"82.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Savassi</text><rect x=\"130.0\" y=\"71.0\" width=\"447.9\" height=\"22.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"583.9\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">103%</text><text x=\"120.0\" y=\"113.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Botafogo</text><rect x=\"130.0\" y=\"102.0\" width=\"459.0\" height=\"22.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"113.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">106%</text><text x=\"120.0\" y=\"144.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Online</text><rect x=\"130.0\" y=\"133.0\" width=\"472.7\" height=\"22.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"608.7\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">109%</text><text x=\"120.0\" y=\"175.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Batel</text><rect x=\"130.0\" y=\"164.0\" width=\"479.5\" height=\"22.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.5\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">111%</text><text x=\"120.0\" y=\"206.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Cambuí</text><rect x=\"130.0\" y=\"195.0\" width=\"479.8\" height=\"22.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"615.8\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">111%</text><path d=\"M563.3 30.0 L563.3 39.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M563.3 63.0 L563.3 70.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M563.3 94.0 L563.3 101.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M563.3 125.0 L563.3 132.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M563.3 156.0 L563.3 163.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M563.3 187.0 L563.3 194.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M563.3 218.0 L563.3 240.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"563.3\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">target</text></svg>", "caption": "Sales over target for the year, from the sums rather than an average of months. The largest shop is the only one short."}
```

Five of the six beat their target. Pinheiros, the largest shop, fell short at 96%;
Cambuí and Batel finished 11% over, and the online channel, which carries the most money, 9% over.

Four things in those two files are the earlier lessons at work:

- **The sales are counted the same way as everywhere else in the course.** Shop amounts go through
  lesson 7's `reais`, online totals through lesson 12's `ready.py`, and only delivered orders
  count, because a cancelled or refunded order is not a sale.
- **The join key is two columns**, shop and month, and both are typed the same on both sides: a
  shop name as text, a month as `period[M]`.
- **`validate="one_to_one"`** checks that neither side has two rows for one shop and month. Long
  tables built by `melt` and by `groupby` should both pass, and if either ever does not, the join
  stops before it fans out.
- **A target with no sales stops the script.** A left join keeps every target, and the indicator
  says whether it found its month. A shop that sold nothing in a month is possible, but it is a
  finding to look at, not a blank to divide by.

The attainment is a derived column in the sense of lesson 12, computed at the grain of shop and
month. The yearly table is computed again from the sums, rather than by averaging the twelve
monthly ratios, because **an average of ratios weights a slow month the same as a busy one**.
