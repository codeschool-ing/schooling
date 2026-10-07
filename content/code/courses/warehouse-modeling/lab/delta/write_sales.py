"""Write one year of fact_sales from the warehouse into a Delta table on the lake."""
import sys

import duckdb
from deltalake import write_deltalake

year, mode = int(sys.argv[1]), sys.argv[2]

con = duckdb.connect("wh.duckdb", read_only=True)
rows = con.sql(f"""
    SELECT f.*, d.year
    FROM fact_sales f JOIN dim_date d USING (date_key)
    WHERE d.year = {year}
""").to_arrow_table()

write_deltalake("lake/sales", rows, mode=mode, partition_by=["year"])
print(f"wrote {rows.num_rows} rows of {year} with mode={mode}")
