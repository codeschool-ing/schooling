---
title: A lake is files, kept as they arrived
version: 1
---

A warehouse decides the shape of its data before any of it arrives: a staging table, a model, types
checked at the door. A **data lake** turns that round. It is storage, usually object storage, where
every file is kept as it arrived, in whatever format it came in, and the shape is decided by whoever
reads it, when they read it.

Ana's lake is a directory on the lab's disk, standing in for a bucket. She drops the shop's order export
into it as it is:

```
ana@lab:~/wh$ mkdir -p lake/raw/orders && cp extract/orders.csv lake/raw/orders/orders_2025-12-31.csv
ana@lab:~/wh$ duckdb -c "SELECT count(*) AS orders, min(ordered_at) AS first, max(ordered_at) AS last FROM read_csv('lake/raw/orders/*.csv')"
┌────────┬──────────────────────────┬──────────────────────────┐
│ orders │          first           │           last           │
│ int64  │ timestamp with time zone │ timestamp with time zone │
├────────┼──────────────────────────┼──────────────────────────┤
│ 577468 │ 2024-01-01 01:26:22-03   │ 2025-12-31 23:22:18-03   │
└────────┴──────────────────────────┴──────────────────────────┘
```

No table was created, no type declared, nothing loaded. The file is in a folder, and DuckDB read it in
place, worked out the types from its contents, and answered. That is the lake's whole offer:

- **A new source is a folder, not a project.** Logs from the website, images of book covers, a partner's
  price list, a stream of clicks: each lands as files and can be kept before anybody knows what it is for.
- **Storage is cheap**, the cheapest storage `cloud` lesson 5 priced, and it holds anything, structured or
  not.
- **Any engine can read it.** The files are CSV, JSON or Parquet, formats every tool speaks, so the same
  folder serves DuckDB, Spark, a Python notebook and a cloud warehouse at once. That is lesson 7's separation
  of storage and compute, with the storage open to everybody.

The price for that freedom is paid by the reader, and the next two sections show the bill.
