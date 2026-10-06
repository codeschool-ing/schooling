---
title: Inside a Parquet file
version: 1
---

**Parquet** is the open columnar file format that lessons 7 to 10 keep writing. It is the common
language of analytics: DuckDB, Spark, BigQuery, Snowflake, Redshift, pandas and every lakehouse table format
read and write it, so a file written by one is a table to all the others.

Its structure, from the outside in:

- **The file** holds a schema, the column names and types, and its metadata at the end, in a **footer**.
  A reader reads the footer first, so it knows where everything is before it reads any data.
- **Row groups** divide the rows into blocks, 122,880 rows each in the files DuckDB writes here.
- **Column chunks** sit inside each row group: each column's values stored together, with their own
  encoding and statistics.
- **Pages** divide a column chunk further, and are the unit that is compressed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The layout of a Parquet file as nested boxes. The file contains row groups, here eight, then a footer. Each row group contains one column chunk per column, from date_key to net_cents. Each column chunk contains pages of encoded values. The footer holds the schema and, for every row group and column, the position, size, encoding and minimum and maximum, so a reader can decide what to read before reading it.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"280\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">fact_sales.parquet</text><rect x=\"24\" y=\"45\" width=\"470\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">row group 0 · 122,880 rows</text><rect x=\"36\" y=\"75\" width=\"105\" height=\"52\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"88\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">date_key</text><rect x=\"44\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"75\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"106\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"149\" y=\"75\" width=\"105\" height=\"52\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"201\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop_key</text><rect x=\"157\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"188\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"219\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"262\" y=\"75\" width=\"105\" height=\"52\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"314\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">…</text><rect x=\"375\" y=\"75\" width=\"105\" height=\"52\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"427\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">net_cents</text><rect x=\"383\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"414\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"445\" y=\"101\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"24\" y=\"150\" width=\"470\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">row group 1 · 122,880 rows</text><rect x=\"36\" y=\"180\" width=\"105\" height=\"52\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"88\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">date_key</text><rect x=\"44\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"75\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"106\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"149\" y=\"180\" width=\"105\" height=\"52\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"201\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop_key</text><rect x=\"157\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"188\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"219\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"262\" y=\"180\" width=\"105\" height=\"52\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"314\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">…</text><rect x=\"375\" y=\"180\" width=\"105\" height=\"52\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"427\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">net_cents</text><rect x=\"383\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"414\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"445\" y=\"206\" width=\"27\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"259\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">… six more row groups …</text><rect x=\"510\" y=\"45\" width=\"186\" height=\"230\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"603\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">footer</text><text x=\"522\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">schema: names, types</text><text x=\"522\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">per row group, per column:</text><text x=\"522\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">where it starts</text><text x=\"522\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">how many bytes</text><text x=\"522\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">which encoding</text><text x=\"522\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">minimum and maximum</text><text x=\"259\" y=\"285\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">small boxes are pages</text></svg>", "caption": "A Parquet file: row groups of column chunks of pages, and a footer that says where everything is."}
```

The schema and the file-level metadata of `fact_sales.parquet`:

```
ana@lab:~/wh$ duckdb -c "SELECT name, type FROM parquet_schema('fact_sales.parquet')"
┌────────────────┬─────────┐
│      name      │  type   │
│    varchar     │ varchar │
├────────────────┼─────────┤
│ duckdb_schema  │ NULL    │
│ date_key       │ INT32   │
│ shop_key       │ INT64   │
│ book_key       │ INT64   │
│ customer_key   │ INT64   │
│ promotion_key  │ INT64   │
│ order_id       │ INT64   │
│ line_no        │ INT64   │
│ quantity       │ INT64   │
│ gross_cents    │ INT64   │
│ discount_cents │ INT64   │
│ net_cents      │ INT64   │
└────────────────┴─────────┘
  12 rows        2 columns
ana@lab:~/wh$ duckdb -c "SELECT num_rows, num_row_groups, format_version, created_by FROM parquet_file_metadata('fact_sales.parquet')"
┌──────────┬────────────────┬────────────────┬──────────────────────────────────────────┐
│ num_rows │ num_row_groups │ format_version │                created_by                │
│  int64   │     int64      │     int64      │                 varchar                  │
├──────────┼────────────────┼────────────────┼──────────────────────────────────────────┤
│   887477 │              8 │              1 │ DuckDB version v1.5.6 (build 069cc9f9b5) │
└──────────┴────────────────┴────────────────┴──────────────────────────────────────────┘
```

The types are the file's own, `INT32` and `INT64`, and they are shared by every engine that reads Parquet.
`num_row_groups` is 8, and the footer records which software wrote the file.

**Everything this lesson measured is in that footer**: the sizes per column in section 04, the encodings in
section 05, the minimum and maximum per row group in section 09. A reader that wants one column of March
opens the footer, picks the row groups whose statistics include March, and reads the chunks of that one
column inside them. On a file in object storage, those are a handful of byte ranges out of a large file,
which is what makes lesson 7's separation of storage and compute fast enough to use.

What Parquet does not have is any notion of a change: a Parquet file is written once, whole, and never
edited. A table that changes is many files and a record of which ones are current, which is lesson 10.
