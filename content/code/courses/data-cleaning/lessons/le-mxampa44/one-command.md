---
title: One command rebuilds everything
version: 1
---

Over sixteen lessons, the decisions ended up in small files: `years.py` and `consent.py` from
lesson 10, `ready.py` and `derive.py` from lesson 12, `survivors.csv` from lesson 5. Each one works
when imported. What is missing is the order, and **an order that lives in somebody's memory is a
pipeline nobody else can run**. So one script runs them all, from raw files to clean tables:

```schooling-example
{
  "language": "python",
  "file": "run.py",
  "parts": [
    {
      "code": "\"\"\"Rebuild the clean tables from raw/, in order, and record every value that changed.\"\"\"\nimport logging\nimport pathlib\n\nimport pandas as pd\n\n",
      "note": "What the script is for, in one line."
    },
    {
      "code": "logging.basicConfig(level=logging.INFO, format=\"%(name)s: %(message)s\")\nOUT = pathlib.Path(\"out\")\n\n\n",
      "note": "**Every log line names its step**, and goes to standard error, away from the data."
    },
    {
      "code": "def change(table, keys, column, before, after, rule):\n    return pd.DataFrame({\"table\": table, \"key\": keys, \"column\": column,\n                         \"before\": before, \"after\": after, \"rule\": rule})\n\n\n",
      "note": "One row of the change record: which table, which key, which column, before, after, and the rule."
    },
    {
      "code": "def build_customers():\n    log = logging.getLogger(\"customers\")\n    from consent import customers  # lesson 10: consent as True, False or blank\n    from years import customers as same  # lesson 10: the same table, with the century rule\n    assert customers is same\n",
      "note": "**The customers come from lesson 10's two files**, which change the same table; the `assert` makes sure of it."
    },
    {
      "code": "    written = customers[\"birth_year\"]\n    placeholder = written == \"1900\"\n    two = written.str.len() == 2\n",
      "note": "Which values the two rules touched, found from what was written."
    },
    {
      "code": "    log.info(f\"{len(customers)} rows, {placeholder.sum()} placeholders blanked, \"\n             f\"{two.sum()} years given a century, {customers['opt_in'].isna().sum()} consents unknown\")\n",
      "note": "**The step's counts**, in one line."
    },
    {
      "code": "    changes = pd.concat([\n        change(\"customers\", customers.loc[placeholder, \"customer_id\"], \"birth_year\", \"1900\", \"\",\n               \"placeholder, lesson 4\"),\n        change(\"customers\", customers.loc[two, \"customer_id\"], \"birth_year\", written[two],\n               customers.loc[two, \"birth\"].astype(str), \"century rule, lesson 10\")])\n",
      "note": "Every blanked placeholder and every two-digit year, recorded with its rule."
    },
    {
      "code": "    table = customers[[\"customer_id\", \"birth\", \"opt_in\"]].rename(columns={\"birth\": \"birth_year\"})\n    return table, changes\n\n\n",
      "note": "The clean customer table: code, year of birth and consent."
    },
    {
      "code": "def build_orders():\n    log = logging.getLogger(\"orders\")\n    from derive import orders  # lesson 12: decided totals, derived columns, corporate flag\n    from typos import wrong  # lesson 9: the seven totals typed ten times too big\n",
      "note": "**The orders come from lesson 12**, and the seven typed totals from lesson 9."
    },
    {
      "code": "    raw = pd.read_csv(\"raw/orders.csv\", dtype=str).drop_duplicates().set_index(\"order_id\")\n    before = pd.to_numeric(raw[\"total\"])\n    after = orders.set_index(\"order_id\")[\"total\"]\n    moved = after.index[after != before]\n    typo = moved.isin(wrong[\"order_id\"])\n",
      "note": "**What changed is found by comparing**, not remembered: raw total against decided total."
    },
    {
      "code": "    survivors = pd.read_csv(\"survivors.csv\", dtype=str)  # lesson 5\n    owner = orders[\"customer_id\"].map(dict(zip(survivors[\"customer_id\"], survivors[\"kept_id\"])))\n    rekeyed = owner.notna()\n",
      "note": "Lesson 5's map of second records, applied to the orders' customer codes."
    },
    {
      "code": "    log.info(f\"{len(orders)} rows, {typo.sum()} totals recomputed from lines, \"\n             f\"{(~typo).sum()} negative totals set to 0, {rekeyed.sum()} moved to a surviving \"\n             f\"customer, {orders['corporate'].sum()} flagged corporate\")\n",
      "note": "The step's counts."
    },
    {
      "code": "    changes = pd.concat([\n        change(\"orders\", moved, \"total\", before[moved].astype(str), after[moved].astype(str),\n               [\"typed total, lesson 9\" if t else \"coupon above basket, lesson 9\" for t in typo]),\n        change(\"orders\", orders.loc[rekeyed, \"order_id\"], \"customer_id\",\n               orders.loc[rekeyed, \"customer_id\"], owner[rekeyed], \"same person, lesson 5\")])\n    orders.loc[rekeyed, \"customer_id\"] = owner[rekeyed]\n",
      "note": "**Every changed total and every moved order recorded**, then the move applied."
    },
    {
      "code": "    columns = [\"order_id\", \"customer_id\", \"channel\", \"placed\", \"status\", \"total\", \"items\",\n               \"corporate\"]\n    return orders[columns], changes\n\n\n",
      "note": "The columns the clean order table keeps."
    },
    {
      "code": "if __name__ == \"__main__\":\n    OUT.mkdir(exist_ok=True)\n    customers, c1 = build_customers()\n    orders, c2 = build_orders()\n    changes = pd.concat([c1, c2])\n    customers.to_csv(OUT / \"customers.csv\", index=False)\n    orders.to_csv(OUT / \"orders.csv\", index=False)\n    changes.to_csv(OUT / \"changes.csv\", index=False)\n    logging.getLogger(\"run\").info(f\"{len(changes)} changes recorded in out/changes.csv\")\n",
      "note": "Build both, write the three files, and say how many changes were recorded."
    }
  ]
}
```

```
ana@lab:~/clean$ python run.py
customers: 2376 rows, 338 placeholders blanked, 105 years given a century, 57 consents unknown
orders: 28526 rows, 7 totals recomputed from lines, 137 negative totals set to 0, 2 moved to a surviving customer, 16 flagged corporate
run: 589 changes recorded in out/changes.csv
ana@lab:~/clean$ ls out
changes.csv
customers.csv
orders.csv
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l17-pipeline\" aria-label=\"A diagram of the pipeline. On the left, the raw files, read-only, with their fingerprints in raw.sha256. An arrow leads to run.py, one command that imports the lessons' modules. From it, arrows lead to two outputs in out/: the clean tables and the change record, and checks.py reads the outputs. A dashed outline around the code, the maps and raw.sha256 marks what is under version control; the raw files and out/ are outside it.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M188 20 L532 20 Q540 20 540 28 L540 262 Q540 270 532 270 L188 270 Q180 270 180 262 L180 28 Q180 20 188 20 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"360.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">under version control</text><rect x=\"20.0\" y=\"60.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">raw/</text><text x=\"90.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">read-only</text><rect x=\"200.0\" y=\"60.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">raw.sha256</text><text x=\"270.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fingerprints</text><rect x=\"200.0\" y=\"160.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">run.py</text><text x=\"270.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one command</text><rect x=\"380.0\" y=\"160.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">*.py, *.csv</text><text x=\"450.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the lessons' modules</text><rect x=\"570.0\" y=\"60.0\" width=\"130.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">out/*.csv</text><text x=\"635.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">clean tables</text><rect x=\"570.0\" y=\"160.0\" width=\"130.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">changes.csv</text><text x=\"635.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">change record</text><rect x=\"380.0\" y=\"60.0\" width=\"140.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">checks.py</text><text x=\"450.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">checks</text><path d=\"M160.0 88.0 L198.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M90 116 L90 188 L198 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M378.0 188.0 L342.0 188.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M270 216 L270 245 L635 245 L635 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M300 160 L300 138 L635 138 L635 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M568.0 88.0 L522.0 88.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"635.0\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rebuilt on every run</text></svg>", "caption": "What is kept and what is rebuilt. Everything inside the dashed line is versioned; the raw files are fingerprinted instead, and out/ is thrown away and made again."}
```

Three properties make this script worth more than the commands it replaces:

- **It starts from `raw/` every time.** Nothing it reads was written by a previous run, so there is
  no hidden state: delete `out/` and the next run puts back exactly the same files.
- **Each step reuses the lesson that decided it** instead of copying it. If the century rule ever
  changes, it changes in `years.py`, and the pipeline picks it up without anyone remembering where
  else it was pasted.
- **Each step says what it did**, in numbers: 338 placeholders, 105 centuries, 7 totals
  recomputed, 137 set to zero, 2 orders moved to a surviving customer, 16 flagged. A log line with a
  count is the difference between "the pipeline ran" and "the pipeline did what we expected". When
  next month's run says 412 placeholders, somebody will ask why, and that is the point.

The log goes to standard error through Python's `logging`, so it never mixes with the data and can
be kept in a file of its own. The outputs go to `out/`, which is disposable by design: everything in
it can be rebuilt by one command.
