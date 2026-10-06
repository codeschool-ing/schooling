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
