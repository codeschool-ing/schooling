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
