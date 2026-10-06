---
title: A contract, checked by a program
version: 1
---

A **data contract** is an agreement between the producer of a dataset and its consumers, written so that a machine
can check it. Its core is the schema: which columns, with which types. Around that it carries what the schema cannot
say: the grain, the owner, rules the data must satisfy. Ana's contract for `fact_sales` is a JSON file:

```json
{
  "table": "fact_sales",
  "owner": "sales analytics",
  "grain": "one row per line of an order that was not cancelled",
  "columns": {
    "date_key": "INTEGER",
    "shop_key": "BIGINT",
    "book_key": "BIGINT",
    "customer_key": "BIGINT",
    "promotion_key": "BIGINT",
    "order_id": "BIGINT",
    "line_no": "BIGINT",
    "quantity": "BIGINT",
    "gross_cents": "BIGINT",
    "discount_cents": "BIGINT",
    "net_cents": "BIGINT"
  },
  "not_null": ["date_key", "shop_key", "book_key", "customer_key", "net_cents"],
  "unique": ["order_id", "line_no"]
}
```

And the program that checks the warehouse against it, under forty lines of Python:

```python
"""Check a table in the warehouse against its contract; exit 1 on any breach."""
import json
import sys

import duckdb

contract = json.load(open(sys.argv[1]))
table = contract["table"]
con = duckdb.connect("wh.duckdb", read_only=True)
breaches = []

actual = dict(con.execute(
    "SELECT column_name, data_type FROM duckdb_columns() WHERE table_name = ?",
    [table]).fetchall())
for column, wanted in contract["columns"].items():
    if column not in actual:
        breaches.append(f"column {column} is missing")
    elif actual[column] != wanted:
        breaches.append(f"column {column} is {actual[column]}, contract says {wanted}")

for column in contract["not_null"]:
    if column in actual:
        n = con.sql(f"SELECT count(*) FROM {table} WHERE {column} IS NULL").fetchone()[0]
        if n:
            breaches.append(f"{n} rows with no {column}")

key = ", ".join(contract["unique"])
n = con.sql(f"SELECT count(*) FROM (SELECT {key} FROM {table} GROUP BY ALL HAVING count(*) > 1)").fetchone()[0]
if n:
    breaches.append(f"{n} values of ({key}) appear more than once")

for b in breaches:
    print("BREACH:", b)
print(f"{table}: {len(contract['columns'])} columns checked, breaches: {len(breaches)}")
sys.exit(1 if breaches else 0)
```

```
ana@lab:~/wh$ python3 check_contract.py fact_sales.contract.json; echo "exit status $?"
fact_sales: 11 columns checked, breaches: 0
exit status 0
ana@lab:~/wh$ duckdb wh.duckdb -c "ALTER TABLE fact_sales RENAME COLUMN discount_cents TO discount"
ana@lab:~/wh$ python3 check_contract.py fact_sales.contract.json; echo "exit status $?"
BREACH: column discount_cents is missing
fact_sales: 11 columns checked, breaches: 1
exit status 1
```

The first run finds nothing: eleven columns of the right types, no empty keys, no line counted twice. Then somebody
renames `discount_cents` to `discount`, the kind of tidying that seems harmless from inside the team that owns the
table, and the check fails with **a message naming the column and an exit status of 1**.

That exit status is the point. A check that prints a warning is read when somebody remembers; a check that exits 1
stops a deployment. **The contract belongs in the producer's pipeline**, run before a change is published. The
rename is then refused on the producer's side, where it was made and can be undone, rather than discovered by every
dashboard that read `discount_cents`, the way section 3 of lesson 10 found a renamed column too late.

A contract written by hand in JSON is a teaching version. In practice the same idea comes as dbt's model contracts,
as test suites in data quality tools, and as the Open Data Contract Standard, a YAML format kept by an open project
under the Linux Foundation. `pipelines-etl` lesson 16 builds them into a pipeline. What all of them share is the move
this section makes: **the promise is a file, and the file is executed**.
