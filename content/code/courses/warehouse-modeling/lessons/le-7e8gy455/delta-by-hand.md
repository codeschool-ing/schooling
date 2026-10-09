---
title: A Delta table, by hand
version: 2
---

Lesson 1 installed the `deltalake` library, delta-rs, a Rust implementation of Delta Lake with a Python interface.
No server and no cluster: a Delta table is a folder, and the library is what reads and writes the log in it.

Ana's first program takes one year of `fact_sales` from the warehouse and writes it into a Delta table on the
lake, partitioned by year:

```schooling-example
{
  "language": "python",
  "file": "write_sales.py",
  "parts": [
    {
      "code": "\"\"\"Write one year of fact_sales from the warehouse into a Delta table on the lake.\"\"\"\nimport sys\n\nimport duckdb\nfrom deltalake import write_deltalake\n\n",
      "note": "Two libraries and nothing else: DuckDB to read the warehouse, `deltalake` to write the table. Neither needs a server."
    },
    {
      "code": "year, mode = int(sys.argv[1]), sys.argv[2]\n\n",
      "note": "The year to copy, and the mode: `overwrite` replaces the table, `append` adds to it. Both become a commit."
    },
    {
      "code": "con = duckdb.connect(\"wh.duckdb\", read_only=True)\nrows = con.sql(f\"\"\"\n    SELECT f.*, d.year\n    FROM fact_sales f JOIN dim_date d USING (date_key)\n    WHERE d.year = {year}\n\"\"\").to_arrow_table()\n\n",
      "note": "The warehouse is opened read-only, and one year of sales comes out as an Arrow table, the columnar format in memory that both libraries speak, so nothing is converted row by row."
    },
    {
      "code": "write_deltalake(\"lake/sales\", rows, mode=mode, partition_by=[\"year\"])\nprint(f\"wrote {rows.num_rows} rows of {year} with mode={mode}\")",
      "note": "One call writes the Parquet files under `year=…` and then the commit in `_delta_log`. Until the commit exists, the new files are not part of the table."
    }
  ]
}
```

She writes 2024 first, replacing anything that was there, and then appends 2025:

```
ana@lab:~/wh$ python write_sales.py 2024 overwrite
wrote 404067 rows of 2024 with mode=overwrite
ana@lab:~/wh$ python write_sales.py 2025 append
wrote 483410 rows of 2025 with mode=append
ana@lab:~/wh$ find lake/sales -type f | sort | sed "s/part-.*parquet/part-….parquet/"
lake/sales/_delta_log/00000000000000000000.json
lake/sales/_delta_log/00000000000000000001.json
lake/sales/year=2024/part-….parquet
lake/sales/year=2025/part-….parquet
```

Two years, two folders, one Parquet file in each, and a folder called `_delta_log` with two numbered files in
it. **The Parquet files are the data, and they are ordinary Parquet**: DuckDB, Spark or anything else could read
them directly. The two JSON files are the table: commit 0 created it with the 2024 file, commit 1 added the
2025 file.

The partition folders are named the way lesson 7's were, `year=2024`. Delta records the partition values in the
log too, so a reader that knows the format does not have to parse folder names, and a reader that does not still
sees the familiar layout.

From here on, every change to this table goes through the library and becomes one more commit in the log. The
next section opens the log.
