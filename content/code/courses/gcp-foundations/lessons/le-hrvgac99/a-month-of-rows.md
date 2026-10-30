---
title: A month of rows
version: 1
---

**The lab has no bill, so it makes one**: a month of rows in the export's shape, written by a program the
student can read, and queried with the same SQL a real export would take. Every number in this section and
the next is the program's invention; what is real is the shape of the rows and what the queries do with
them. The engine is DuckDB, installed into the lab's virtual environment in lesson 1, because BigQuery has no
emulator and DuckDB reads the same nested rows.

Make a directory and save this as `~/gcp/export/make_export.py`:

```sh
mkdir -p ~/gcp/export && cd ~/gcp/export
```

```schooling-example
{"language": "python", "file": "make_export.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Writes one invented month of a Cloud Billing export, in the export's shape.\n\n    python3 make_export.py > october.jsonl\n\nEvery row is made up: the projects are the planner's, the SKU names are\nwritten like Google's, and the prices are examples, not Google's.\n\"\"\"\nimport json\nimport random\nfrom datetime import date, timedelta\n\n", "note": "What the program is for, said in its first lines: every row it writes is invented, in the shape of the real export. Nothing in it reads a bill."}, {"code": "rng = random.Random(14)\nMONTH = date(2026, 10, 1)\n\n", "note": "A seeded random number generator, so the month comes out the same on every run, and the month itself: October 2026."}, {"code": "# project, service, SKU, unit, units a day, example price per unit, team label\nLINES = [\n    ('planner-prod', 'Compute Engine', 'N2 Instance Core running in Sao Paulo', 'hour', 96, 0.045, 'planner'),\n    ('planner-prod', 'Compute Engine', 'N2 Instance Ram running in Sao Paulo', 'gibibyte hour', 384, 0.006, 'planner'),\n    ('planner-prod', 'Compute Engine', 'Network Inter Region Data Transfer Out', 'gibibyte', 40, 0.14, 'planner'),\n    ('planner-staging', 'Compute Engine', 'N2 Instance Core running in Sao Paulo', 'hour', 24, 0.045, 'planner'),\n    ('planner-dev', 'Cloud Pub/Sub', 'Message Delivery Basic', 'tebibyte', 0.02, 60.0, 'data'),\n    ('planner-dev', 'Compute Engine', 'N2 Instance Core running in Sao Paulo', 'hour', 12, 0.045, None),\n    ('planner-network', 'Networking', 'Cloud NAT Gateway Uptime', 'hour', 24, 0.0014, 'network'),\n]\n\n", "note": "Seven lines of the planner's bill, one per project and SKU: how many units a day each uses, an **example** price per unit, and the `team` label the resource carries. The machine in `planner-dev` carries none; somebody forgot it, and the next section finds it."}, {"code": "def credits(service, cost, day):\n    if service == 'Compute Engine' and day > 7:\n        return [{'name': 'Sustained Usage Discount', 'amount': round(-0.2 * cost, 6),\n                 'type': 'SUSTAINED_USAGE_DISCOUNT'}]\n    if service == 'Cloud Pub/Sub' and day == 1:\n        return [{'name': 'Free Tier', 'amount': round(-cost, 6), 'type': 'FREE_TIER'}]\n    return []\n\n", "note": "Credits, the negative amounts of lesson 13. Compute Engine earns a sustained use credit once a machine has run a week of the month, a simplification of the tiers; Pub/Sub's first day is covered by the free tier."}, {"code": "for day in range(1, 32):\n    start = MONTH + timedelta(days=day - 1)\n    for project, service, sku, unit, per_day, price, team in LINES:\n        amount = round(per_day * rng.uniform(0.9, 1.1), 4)\n        cost = round(amount * price, 6)\n        print(json.dumps({\n            'billing_account_id': '012345-6789AB-CDEF01',\n            'service': {'description': service},\n            'sku': {'description': sku},\n            'usage_start_time': f'{start}T00:00:00Z',\n            'project': {'id': project},\n            'labels': [{'key': 'team', 'value': team}] if team else [],\n            'location': {'region': 'southamerica-east1'},\n            'cost': cost,\n            'currency': 'USD',\n            'usage': {'amount': amount, 'unit': unit},\n            'credits': credits(service, cost, day),\n            'invoice': {'month': '202610'},\n            'cost_type': 'regular',\n        }))\n", "note": "One row per day per line, with the usage varied by up to a tenth either way. The row's fields are a subset of the standard export's columns, with the same names and the same nesting: `service.description`, `labels` as a list of key and value, `credits` as a list."}]}
```

Then a short program that runs one SQL file against the month, calling the rows `export`. Save it as
`ask.py`:

```python
#!/usr/bin/env python3
"""Runs one SQL file against the month in october.jsonl, as a table named export.

    python3 ask.py QUERY.sql
"""
import sys

import duckdb

con = duckdb.connect()
con.sql("CREATE VIEW export AS SELECT * FROM read_json_auto('october.jsonl')")
print(con.sql(open(sys.argv[1]).read()))
```

Write the month, and ask how many lines it has, over which days, for how much. Save the question as
`month.sql`:

```sql
SELECT count(*) AS lines,
       min(usage_start_time) AS first_day,
       max(usage_start_time) AS last_day,
       round(sum(cost), 2) AS gross
FROM export
```

```
ana@laptop:~/gcp/export$ python3 make_export.py > october.jsonl
ana@laptop:~/gcp/export$ python3 ask.py month.sql
┌───────┬─────────────────────┬─────────────────────┬────────┐
│ lines │      first_day      │      last_day       │ gross  │
│ int64 │      timestamp      │      timestamp      │ double │
├───────┼─────────────────────┼─────────────────────┼────────┤
│   217 │ 2026-10-01 00:00:00 │ 2026-10-31 00:00:00 │ 469.05 │
└───────┴─────────────────────┴─────────────────────┴────────┘
```

Seven lines a day for 31 days, 469.05 dollars before credits. **That total is not the bill**: the credits are
in a column of their own, and the next section subtracts them.

## The shape of a row

Ask DuckDB what it made of the columns. Save as `columns.sql`:

```sql
SELECT column_name, column_type FROM (DESCRIBE export)
```

```
ana@laptop:~/gcp/export$ python3 ask.py columns.sql
┌────────────────────┬─────────────────────────────────────────────────────────┐
│    column_name     │                       column_type                       │
│      varchar       │                         varchar                         │
├────────────────────┼─────────────────────────────────────────────────────────┤
│ billing_account_id │ VARCHAR                                                 │
│ service            │ STRUCT(description VARCHAR)                             │
│ sku                │ STRUCT(description VARCHAR)                             │
│ usage_start_time   │ TIMESTAMP                                               │
│ project            │ STRUCT(id VARCHAR)                                      │
│ labels             │ STRUCT("key" VARCHAR, "value" VARCHAR)[]                │
│ location           │ STRUCT(region VARCHAR)                                  │
│ cost               │ DOUBLE                                                  │
│ currency           │ VARCHAR                                                 │
│ usage              │ STRUCT(amount DOUBLE, unit VARCHAR)                     │
│ credits            │ STRUCT("name" VARCHAR, amount DOUBLE, "type" VARCHAR)[] │
│ invoice            │ STRUCT("month" VARCHAR)                                 │
│ cost_type          │ VARCHAR                                                 │
└────────────────────┴─────────────────────────────────────────────────────────┘
  13 rows                                                            2 columns
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l14-row\" aria-label=\"One row of the invented export, from 8 October, drawn as its fields. On the left, plain fields and groups of fields read with a dot: service.description is Compute Engine, sku.description is N2 Instance Core running in Sao Paulo, project.id is planner-prod, cost is 3.965359 as a floating-point number. On the right, two lists that belong to the same row: labels, holding one entry with key team and value planner, and credits, holding one entry named Sustained Usage Discount with a negative amount. A note says a list can be empty, and that a label is found by looking inside the list, not by naming a column.\"><rect x=\"20.0\" y=\"20.0\" width=\"680.0\" height=\"230.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one row</text><text x=\"40.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">service.description</text><text x=\"40.0\" y=\"81.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Compute Engine</text><text x=\"40.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">sku.description</text><text x=\"40.0\" y=\"115.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">N2 Instance Core running in Sao Paulo</text><text x=\"40.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">project.id</text><text x=\"40.0\" y=\"149.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planner-prod</text><text x=\"40.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">usage.amount</text><text x=\"40.0\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">88.1191 hour</text><text x=\"40.0\" y=\"202.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">cost</text><text x=\"40.0\" y=\"217.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3.965359</text><text x=\"40.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">groups of fields, read with a dot</text><rect x=\"420.0\" y=\"56.0\" width=\"260.0\" height=\"66.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"432.0\" y=\"72.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">labels: a list</text><text x=\"432.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">key team, value planner</text><rect x=\"420.0\" y=\"136.0\" width=\"260.0\" height=\"82.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"432.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">credits: a list</text><text x=\"432.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Sustained Usage Discount</text><text x=\"432.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">amount -0.793072</text><text x=\"550.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">either list may be empty</text><text x=\"360.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a label is found inside the list, never as a column</text></svg>", "caption": "Fields are read with a dot; labels and credits are lists inside the row."}
```

Three things about that shape are the three things every query of the real export has to deal with:

| column | in BigQuery | what it means for a query |
|---|---|---|
| `service`, `sku`, `project`, `location`, `usage` | `STRUCT` | a group of fields, read with a dot: `project.id`, `sku.description` |
| `labels`, `credits` | `ARRAY` of `STRUCT` | **a list per row**: a row has as many labels and credits as it has, and none is a column of its own |
| `cost` | `FLOAT64` | **a floating-point number**, not integer cents |

The first is a matter of syntax. The second is why a label cannot be grouped by directly: there is no
`labels.team` column, only a list in which a `team` entry may or may not be. The third is a choice Google
made, and it is why every total in this lesson is rounded at the end and never along the way: a sum of
floating-point amounts can be a fraction of a cent off, and rounding each row first would make it more.

The real export has many more columns than the program writes: the SKU's and the service's ids, the
project's number and its ancestors in the tree, the times the row was exported, the price and the
currency-conversion rate among them. The ones above are the ones the planner's questions need.
