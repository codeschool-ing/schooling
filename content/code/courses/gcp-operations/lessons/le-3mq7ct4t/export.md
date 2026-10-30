---
title: Asking the billing export who spent what
version: 1
---

**The billing export writes every line of the bill, as it accrues, into a BigQuery dataset, with the project,
the service, the SKU, the resource and its labels on each row.** It is the only place where "what did team X spend
on Cloud Run last month?" is one query. Exporting needs a billing account, and BigQuery has no emulator, so neither
is here. What runs is a month of the shop's export, generated into a SQLite table that keeps the export's column names
for the columns these queries use, and the same SQL you would run in BigQuery, give or take a dialect.
`gcp-foundations` lesson 14 turns the export on; this lesson reads it.

The program that makes the month, in `~/gcp/billing.py`:

```python
# billing.py
"""billing.py: a month of the shop's billing export, flattened, into SQLite.

The real export to BigQuery is nested (labels is an array of key and value,
project and service are records). This table keeps the export's names for the
columns the lesson queries, one row per resource per day. Generated, seeded.
"""
import random
import sqlite3

rng = random.Random(23)
ROWS = [  # project, folder, service, sku, resource, team label, cost a day (USD)
    ("planner-prod", "shop", "Cloud Run", "CPU Allocation Time", "shop-api", "shop", 9.40),
    ("planner-prod", "shop", "Cloud Run", "Memory Allocation Time", "shop-api", "shop", 2.10),
    ("planner-prod", "shop", "Cloud Logging", "Log Storage", "_Default", None, 1.30),
    ("planner-prod", "shop", "Cloud Storage", "Standard Storage", "planner-prod-order-exports", "shop", 0.60),
    ("planner-prod", "shop", "Compute Engine", "E2 Instance Core", "batch-1", "data", 2.90),
    ("planner-prod", "shop", "Compute Engine", "E2 Instance Core", "old-migration", None, 1.45),
    ("planner-prod", "shop", "Compute Engine", "Storage PD Capacity", "disk-restore-test", None, 0.85),
    ("planner-dev", "shop", "Cloud Build", "Build time", "shop-api", "shop", 0.70),
    ("planner-dev", "shop", "Artifact Registry", "Storage", "shop", "shop", 0.25),
    ("planner-dev", "sandbox", "Compute Engine", "E2 Instance Core", "sandbox-ana", None, 1.10),
]

db = sqlite3.connect("billing.db")
db.execute("DROP TABLE IF EXISTS export")
db.execute("""CREATE TABLE export (usage_start_time TEXT, project_id TEXT, folder TEXT,
    service TEXT, sku TEXT, resource_name TEXT, label_team TEXT, cost REAL)""")
for day in range(1, 31):
    for project, folder, service, sku, resource, team, daily in ROWS:
        cost = round(daily * rng.uniform(0.85, 1.15), 2)
        db.execute("INSERT INTO export VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                   (f"2026-09-{day:02d}", project, folder, service, sku, resource, team, cost))
db.commit()
print(db.execute("SELECT count(*), round(sum(cost), 2) FROM export").fetchone())
```

And a small program that runs one query and prints the rows, in `~/gcp/q.py`:

```python
# q.py
"""q.py: run one SQL query against billing.db and print the rows."""
import sqlite3
import sys

for row in sqlite3.connect("billing.db").execute(sys.argv[1]):
    print(*row, sep="\t")
```

```
ana@laptop:~/gcp$ python3 billing.py
(300, 623.07)
```

Three hundred rows, ten resources over thirty days, 623.07 USD in all.

## By project, and by folder

```
ana@laptop:~/gcp$ python3 q.py "SELECT project_id, round(sum(cost), 2) FROM export GROUP BY 1 ORDER BY 2 DESC"
planner-prod	561.62
planner-dev	61.45
ana@laptop:~/gcp$ python3 q.py "SELECT folder, round(sum(cost), 2) FROM export GROUP BY 1 ORDER BY 2 DESC"
shop	590.13
sandbox	32.94
```

Production is nine-tenths of the month. The folders cut differently: `sandbox-ana` lives in `planner-dev` but in the
`sandbox` folder, so the folder total moves it out of the shop's own line. In BigQuery the folder is not a column: the
export carries the project's ancestry, `project.ancestors`, and the query unnests it to find the folder.

## By label

```
ana@laptop:~/gcp$ python3 q.py "SELECT coalesce(label_team, '(no label)'), round(sum(cost), 2), round(100 * sum(cost) / (SELECT sum(cost) FROM export), 1) FROM export GROUP BY 1 ORDER BY 2 DESC"
shop	395.9	63.5
(no label)	139.86	22.4
data	87.31	14.0
```

Team `shop` spent 63.5% and team `data` 14.0%. **And 22.4% belongs to nobody**: 139.86 USD a month with no `team`
label. In BigQuery the same question reads the labels array:
`(SELECT value FROM UNNEST(labels) WHERE key = 'team')`. The next section is about that 22.4%.
