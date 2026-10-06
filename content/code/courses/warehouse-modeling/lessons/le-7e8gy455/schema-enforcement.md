---
title: Refusing the wrong shape
version: 1
---

Section 3 watched a lake take a file with a renamed column without a murmur. A Delta table records its schema in the
log and checks every write against it. This program appends a row with one column too many, `shipping_cents`:

```python
"""Append a row whose shape does not match the table: one column too many."""
import sys

import pyarrow as pa
from deltalake import DeltaTable, write_deltalake

table = DeltaTable("lake/sales")
row = table.to_pyarrow_table().slice(0, 1)
row = row.append_column("shipping_cents", pa.array([1490], pa.int64()))

if len(sys.argv) > 1 and sys.argv[1] == "merge":
    write_deltalake("lake/sales", row, mode="append", schema_mode="merge")
    print("appended, and the table now has", len(DeltaTable("lake/sales").schema().fields), "columns")
else:
    write_deltalake("lake/sales", row, mode="append")
```

```
ana@lab:~/wh$ python bad_append.py 2>&1 | tail -1
_internal.SchemaMismatchError: Cannot cast schema, number of fields does not match: 13 vs 12
ana@lab:~/wh$ python history.py | tail -1
2 UPDATE {'predicate': 'order_id = 112406 AND line_no = 3'}
ana@lab:~/wh$ python bad_append.py merge
appended, and the table now has 13 columns
```

- **The plain append is refused**: thirteen columns offered, twelve in the table. The history afterwards still ends
  at commit 2, so nothing was written; the refusal happened before the commit, which is the only place a refusal is
  worth anything.
- **With `schema_mode="merge"` the same append succeeds** and the table gains the column. Every earlier row reads it
  as empty.

That is the difference between a lake and a table, in one decision. **Evolving the schema is a deliberate act that
somebody writes down**, rather than something that happens to the table because one file was different. The website
team's renamed column of section 3 would have been stopped at the door with an error naming it, and the people who
could fix it would have been the ones to see it.

What schema enforcement does not do is check meaning. A column renamed in the source and written to the right name in
the table passes; so does a price in reais where centavos were meant. Those need the kind of checks lesson 5 ran on a
type 2 dimension, and that `pipelines-etl` makes part of every load.
