---
title: Billed bytes against the bytes actually read
version: 1
---

**The bytes BigQuery bills are not the bytes it reads.** It bills logical bytes, the uncompressed size
of every value by its type, and it reads its own compressed files, which are much smaller. The two
numbers come from different places and answer different questions: the logical bytes are a price list,
fixed and checkable before a query runs, and the bytes read are what the engine actually moved. On
BigQuery you see only the first. On DuckDB, reading Parquet, you can see both, and setting them side
by side shows what kind of number the bill is.

## The district query, in Parquet bytes

**A Parquet file records, for every column of every row group, how many bytes it occupies**, compressed
and uncompressed. `parquet_metadata` reads that out of the footers of September's files, for the two
columns the district query projects:

```
ana@laptop:~/gcp$ python3 ask.py "SELECT path_in_schema AS column_name, sum(total_compressed_size) AS on_disk, sum(total_uncompressed_size) AS uncompressed FROM parquet_metadata('warehouse/orders/dt=2026-09-*/*.parquet') WHERE path_in_schema IN ('district', 'total_cents') GROUP BY ALL ORDER BY column_name"
┌─────────────┬─────────┬──────────────┐
│ column_name │ on_disk │ uncompressed │
│   varchar   │ int128  │    int128    │
├─────────────┼─────────┼──────────────┤
│ district    │  230035 │       229830 │
│ total_cents │ 2748124 │      4179766 │
└─────────────┴─────────┴──────────────┘

ana@laptop:~/gcp$ python3 ask.py "SELECT path_in_schema AS column_name, encodings, compression FROM parquet_metadata('warehouse/orders/dt=2026-09-29/*.parquet') WHERE path_in_schema IN ('district', 'total_cents')"
┌─────────────┬────────────────────────────┬─────────────┐
│ column_name │         encodings          │ compression │
│   varchar   │          varchar           │   varchar   │
├─────────────┼────────────────────────────┼─────────────┤
│ district    │ PLAIN, RLE, RLE_DICTIONARY │ SNAPPY      │
│ total_cents │ PLAIN, RLE, RLE_DICTIONARY │ SNAPPY      │
└─────────────┴────────────────────────────┴─────────────┘
```

**Together they are 2,978,159 bytes on disk, against the 15,023,069 BigQuery would bill.** Three things
make the difference, and each is worth naming.

**`dt` costs nothing on disk and 4,759,056 bytes on the bill.** In these files the date is the name of
the folder, and DuckDB read it without touching a column. In a BigQuery table, `dt` is a `DATE` column
like any other, 8 bytes a row, and a query that filters on it is billed for it.

**`district` is 230,035 bytes on disk and about 5.5 million on the bill.** The bill counts 2 bytes plus
the name, for every one of the 594,882 orders. Parquet wrote each name once per row group, in a
dictionary, and then a small number per row saying which entry it is: the `RLE_DICTIONARY` encoding the
second query shows. Eight districts compress to almost nothing, and the bill does not care.

**`total_cents` is the one column where the two agree in kind**: 2,748,124 bytes on disk against
4,759,056 on the bill. Totals repeat far less than districts do, so the dictionary saves less, and
Snappy, the compression the files use, takes the uncompressed 4,179,766 down by about a third.

```
ana@laptop:~/gcp$ python3 ask.py "SELECT path_in_schema AS column_name, encodings, compression FROM parquet_metadata('warehouse/orders/dt=2026-09-29/*.parquet') WHERE path_in_schema IN ('district', 'total_cents')"
┌─────────────┬────────────────────────────┬─────────────┐
│ column_name │         encodings          │ compression │
│   varchar   │          varchar           │   varchar   │
├─────────────┼────────────────────────────┼─────────────┤
│ district    │ PLAIN, RLE, RLE_DICTIONARY │ SNAPPY      │
│ total_cents │ PLAIN, RLE, RLE_DICTIONARY │ SNAPPY      │
└─────────────┴────────────────────────────┴─────────────┘
```

## Why the bill is logical

**Because a price list has to be knowable in advance.** If BigQuery billed the bytes it actually read,
the price of a query would depend on how well its storage had compressed each block that day, on the
encoding it chose, on whether a recent load had left some blocks less compressed than others. Nobody
could compute it before running the query, and a dry run would be a guess. Logical bytes depend only on
the values and their types, so `bqbill.py`, the dry run and the invoice all agree. The cost of that
predictability is that compression, which Google's storage does very well, is a saving Google keeps on
the query side and shares only through the physical storage model of lesson 13.

**The same rule reaches past queries.** The pricing page bills the **Storage Read API**, the fast path
that tools such as Spark and pandas use to pull a table out of BigQuery, "according to the total amount
of data read", with "the size of the data ... calculated based on the column's data type": logical bytes
again, at 1.98 USD per TiB in `southamerica-east1`, with 300 TiB a month free. A notebook that reads a
table through it pays for the logical size of the columns it asks for, however small the table is on
disk.

## The habit this lesson leaves

**Before a query runs often, know three numbers about it.** The bytes it will be billed, from a dry run
or from `bqbill.py`. The plan, to check that it reads the columns and partitions you expected: DuckDB's
here, the execution graph on BigQuery once it has run. And, on a reservation, the slot time from the
graph, which is the bill there. The first two cost nothing to obtain and the third costs one run, and
together they catch the query that costs a fortune before it has cost one.
