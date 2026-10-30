---
title: Direct Lake: a report that reads the files
version: 1
---

**Power BI has always had two ways to read data, and Direct Lake is a third that exists because
the data is already Delta in OneLake.** This section is taught from Microsoft's documentation and
was not run; Power BI has no emulator and needs a tenant.

## Import and DirectQuery

The two older modes are a trade between speed and freshness:

- **Import** copies the data into the semantic model, Power BI's own compressed in-memory store, on
  a schedule. Reports are fast, because the data is in memory in the engine's format, and as stale
  as the last refresh. A refresh reads every row again, which for a large table is the biggest job
  of the night.
- **DirectQuery** keeps no copy: every visual on every report sends a query to the source, such as
  a warehouse, while somebody waits. Reports are as fresh as the source and as slow as it, and every
  person who opens a page runs queries against it.

## What Direct Lake does instead

**Direct Lake loads columns straight from the Delta table's Parquet files into the in-memory
engine, when a report first needs them.** There is no import copy to refresh and no SQL query per
visual. The Parquet in OneLake is already a column format, so the engine reads the columns a report
uses and leaves the rest on storage, much as DuckDB did with the two columns of the sixth section's
question.

**A refresh in Direct Lake is called framing, and it copies no data.** It points the semantic model at
the table's latest version, which is the newest commit in `_delta_log`, the log the sixth section
downloaded. Framing takes seconds where an import takes as long as reading the table, and it can
happen every time the nightly job finishes. Between two framings the report keeps showing the
version it was framed on, so a half-loaded night is never on a dashboard.

## Where it falls back, and why the files decide

**Direct Lake has limits per capacity size**, which Microsoft documents as guardrails: how many rows
a table may have, how many Parquet files and row groups, how large the model may grow in memory. A
table past a guardrail either falls back to DirectQuery, through the SQL analytics endpoint, or
fails, according to a setting on the model. Some things fall back always, such as reading a SQL view
rather than a table.

**Fallback is quiet**: the report still works, and every visual becomes a SQL query, slower and
billed as one. The guardrails count files and row groups, not only rows, so a table written as
thousands of small files reaches them long before its size would. That is where Fabric's bill meets
the file layout, which is the next lesson's subject: compaction there is what keeps a Direct Lake
model in Direct Lake.

**V-Order is Fabric's own contribution to the files.** It is an optimisation applied when Parquet
is written, by sorting and encoding the data so that the in-memory engine reads it faster; the
result is still standard Parquet, and any reader, `deltalake` and DuckDB included, reads it as
such. The table the sixth section wrote has no V-Order, because only Fabric's engines apply it.
