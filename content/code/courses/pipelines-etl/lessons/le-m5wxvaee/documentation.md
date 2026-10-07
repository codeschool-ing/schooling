---
title: Documentation that is built, not written apart
version: 1
---

The questions people ask about a mart are always the same ones: what does a row mean, which day is
`order_date`, are cancelled orders in it, where does it come from. Answers kept in a wiki go stale
the first time the model changes and nobody remembers the wiki. **dbt keeps them in the project**,
beside the tests, in the same YAML:

```
version: 2

models:
  - name: daily_sales
    description: >
      Books and revenue by day, shop and category, counting completed sales only.
      One row per combination that sold anything. Read by the morning report.
    columns:
      - name: order_date
        description: The day of the sale in São Paulo, not in UTC.
        data_tests: [not_null]
      - name: revenue_cents
        description: Sum of quantity times unit price, in cents of a real.
  - name: fact_sales
    description: >
      One row per order line sold. Incremental: each run replaces the newest day it
      has and every day after it, so changes to older days need a full refresh.
    columns:
      - name: customer_id
        description: Null for a sale at a till to nobody, and for a customer erased on request.
```

A `description` is plain text, on the model or on any column, and the YAML is a place for tests too:
`order_date` gets a `not_null` while it is there. Then dbt builds the documentation, and Ana reads
it back with a short script of her own, which the rest of this section explains:

```
"""What dbt docs knows about one model: its description from the project,
its columns' types from the database, and what it depends on."""
import json
import sys

model = f"model.shop.{sys.argv[1]}"
manifest = json.load(open("shop/target/manifest.json"))
catalog = json.load(open("shop/target/catalog.json"))
node, table = manifest["nodes"][model], catalog["nodes"][model]
print(node["description"].strip())
for name, col in table["columns"].items():
    said = node["columns"].get(name, {}).get("description", "")
    print(f"  {name:<14}{col['type']:<10}{said}")
print("depends on:", ", ".join(manifest["parent_map"][model]))
print("used by:   ", ", ".join(manifest["child_map"][model]))
```

```
ana@vm:~/etl/shop$ dbt docs generate 2>&1 | tail -n 2
06:31:32  Building catalog
06:31:32  Catalog written to /home/ana/etl/shop/target/catalog.json
ana@vm:~/etl/shop$ ls target
catalog.json
compiled
graph.gpickle
graph_summary.json
index.html
manifest.json
osi_document.json
partial_parse.msgpack
run
run_results.json
semantic_manifest.json
ana@vm:~/etl$ python docs.py daily_sales
Books and revenue by day, shop and category, counting completed sales only. One row per combination that sold anything. Read by the morning report.
  order_date    date      The day of the sale in São Paulo, not in UTC.
  shop_id       integer   
  category      text      
  books         integer   
  revenue_cents bigint    Sum of quantity times unit price, in cents of a real.
depends on: model.shop.int_sales, model.shop.stg_books
used by:    exposure.shop.morning_report, test.shop.not_null_daily_sales_order_date.eadffc112b
```

`dbt docs generate` writes two files that matter. `manifest.json` is everything dbt knows about the
project: every model, test, source and exposure, its description, its compiled SQL, and the graph.
`catalog.json` is what the **database** says: every column of every relation dbt built, with its
type. `index.html` is a single-page site that reads the two, and `dbt docs serve` serves it on a
local port; it has a page per model and draws the graph.

The site is the usual way to read it. The files are the useful way to use it, because they are
JSON: Ana's `docs.py` puts the two halves together for one model, from the command line. Look at what came from where. The model's description and two columns' came from her YAML; the
types came from PostgreSQL; the dependencies came from the `ref`s. `shop_id`, `category` and
`books` have no description, and the output shows it plainly — **the gaps in the documentation are
as visible as the rest of it**, which is the first step to filling them.

Not every column needs a sentence. The ones that do are the ones where a reasonable person would
guess wrong: a date in São Paulo time where UTC was possible, money in cents, a null that means
something.
