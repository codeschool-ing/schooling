---
title: Reading the table as it was
version: 1
---

Because old files stay on disk until somebody removes them, and the log records which files made up each version,
any earlier version of the table can be read again:

```python
"""Read the Delta table as it is now, or as it was at an earlier version."""
import sys

import pyarrow.compute as pc
from deltalake import DeltaTable

table = DeltaTable("lake/sales")
if len(sys.argv) > 1:
    table.load_as_version(int(sys.argv[1]))

data = table.to_pyarrow_table()
print(f"version {table.version()}: {len(table.file_uris())} files, "
      f"{data.num_rows} rows, net_cents {pc.sum(data['net_cents'])}")
```

```python
"""List the table's commits, oldest first."""
from deltalake import DeltaTable

for commit in reversed(DeltaTable("lake/sales").history()):
    print(commit["version"], commit["operation"], commit.get("operationParameters", {}))
```

```
ana@lab:~/wh$ python read_sales.py 1
version 1: 2 files, 887477 rows, net_cents 9574389852
ana@lab:~/wh$ python read_sales.py 0
version 0: 1 files, 404067 rows, net_cents 4172718581
ana@lab:~/wh$ python history.py
0 WRITE {'mode': 'Overwrite', 'partitionBy': '["year"]'}
1 WRITE {'partitionBy': '["year"]', 'mode': 'Append'}
2 UPDATE {'predicate': 'order_id = 112406 AND line_no = 3'}
```

- **Version 2**, the current one, has the correction: `net_cents` 9,574,388,852.
- **Version 1**, before it: 9,574,389,852, the figure every lesson until lesson 6's correction reported.
- **Version 0**: only 2024, one file, 404,067 rows.

And the history says what each commit was: two writes and the update, with its predicate.

This is what a lake without a table format cannot do, and it answers questions a warehouse is regularly asked:

- **"Why did last month's report say something different?"** Read the table as of the day the report ran.
- **"What did this bad load change?"** Compare the version before it with the version after.
- **"Undo it."** Restore the table to the earlier version, which is one more commit pointing back at the old files.

## The price, and the clean-up

Keeping every version means keeping every old file. A table updated every night accumulates rewritten copies,
and the bill for storage grows with them. **Vacuum** deletes data files that no version within a retention period
still needs:

```python
"""Which files would vacuum delete: those no current version still needs."""
from deltalake import DeltaTable

table = DeltaTable("lake/sales")
stale = table.vacuum(retention_hours=0, dry_run=True, enforce_retention_duration=False)
print(len(stale), "file(s) no longer referenced by the current version")
```

```
ana@lab:~/wh$ python vacuum.py
1 file(s) no longer referenced by the current version
ana@lab:~/wh$ find lake/sales -name "*.parquet" | wc -l
4
```

One file, the original 2024 one that commit 2 replaced, is no longer referenced. The run is a dry run, so it only
reports; a real one would delete it, and after that **version 0 and version 1 could no longer be read**. The retention
period is the trade: Delta's default keeps seven days, which is the window in which time travel works.

It is also the answer to a question lesson 12 raises about personal data. A customer who asks to be forgotten is
deleted in a new version, and is still in the old files until a vacuum removes them; a lakehouse that keeps months
of history keeps months of a person it promised to forget.
