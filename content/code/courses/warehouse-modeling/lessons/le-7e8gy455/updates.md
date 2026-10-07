---
title: Changing a row in a table of files
version: 1
---

Lesson 6 corrected a till error in the warehouse: the third line of order 112406 had been registered R$ 10.00 too
high. The same correction, on the Delta table:

```python
"""Correct one sale line, the till error of lesson 6, as a Delta update."""
from deltalake import DeltaTable

table = DeltaTable("lake/sales")
result = table.update(
    updates={"net_cents": "net_cents - 1000", "gross_cents": "gross_cents - 1000"},
    predicate="order_id = 112406 AND line_no = 3",
)
print(result)
```

```
ana@lab:~/wh$ python fix_line.py
{'num_added_files': 1, 'num_removed_files': 1, 'num_updated_rows': 1, 'num_copied_rows': 404066, 'execution_time_ms': 193, 'scan_time_ms': 11}
ana@lab:~/wh$ jq -c 'keys[0]' lake/sales/_delta_log/00000000000000000002.json
"commitInfo"
"add"
"remove"
ana@lab:~/wh$ python read_sales.py
version 2: 2 files, 887477 rows, net_cents 9574388852
```

The summary is the honest account of what an update costs in a table of immutable files. **One row was updated, and
404,066 were copied**: the whole of the file holding 2024 was read, the one row changed, and a new file written with
all of them. Commit 2 has an `add` for the new file and a `remove` for the old one. The table still has two files, a
new one for 2024 and the untouched one for 2025, and the total is 1,000 centavos lower, as the correction meant.

This strategy is called **copy on write**: a change rewrites every file it touches. It makes reads simple and fast,
because a reader only ever sees complete files, and it makes small changes expensive, because a one-row change to a
large file rewrites the file. Two things soften it:

- **Smaller files, by partition.** Only the 2024 file was rewritten, because the change touched nothing in 2025.
- **Deletion vectors**, which newer versions of the formats support: instead of rewriting a file to remove some
  rows, the commit records a small list of row positions to ignore, and the rewrite is put off until the file is
  compacted. This is the **merge on read** approach, which section 11 says Hudi made its speciality.

**Nothing was deleted from the disk.** The old 2024 file is still in its folder; commit 2 merely says it is no longer
part of the current version. The next section uses exactly that.
