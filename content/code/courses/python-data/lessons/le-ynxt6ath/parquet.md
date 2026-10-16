---
title: Parquet, which keeps the types
version: 1
---

**Parquet is a binary, column-oriented file format that stores each column with its type,
compressed.** It is what pandas, Spark, DuckDB and most data warehouses exchange when nobody needs to
open the file in a text editor. pandas reads and writes it through `pyarrow`, the seventh library of
lesson 1.

Give the trips real types first, the datetimes from two sections ago, and write the table to CSV
and to Parquet:

```python
typed = pd.read_csv("trips.csv", parse_dates=["started_at", "ended_at"])
typed.to_csv("typed.csv", index=False)
typed.to_parquet("typed.parquet")
pd.read_csv("typed.csv").dtypes["started_at"], pd.read_parquet("typed.parquet").dtypes["started_at"]
```

```
(<StringDtype(na_value=nan)>, dtype('<M8[us]'))
```

**The CSV lost the type and the Parquet file kept it.** Written to CSV, a datetime becomes text,
and reading it back gives text again unless you repeat `parse_dates`. Parquet stores that
`started_at` is a datetime, and every reader of the file gets it back as one.

```python
{name: os.path.getsize(name) for name in ("trips.csv", "trips.jsonl", "typed.parquet")}
```

```
{'trips.csv': 2267957, 'trips.jsonl': 5335481, 'typed.parquet': 834853}
```

The same 33,337 trips: the Parquet file is under half the size of the CSV, and a sixth of the JSON.
A column holds values of one type, often repeating, `annual` thousands of times, and stored
together they compress far better than rows of mixed text.

## Reading only some columns

Because the file is organised by column, reading two columns reads only those two from disk:

```python
pd.read_parquet("typed.parquet", columns=["start_station", "bike"]).shape
```

```
(33337, 2)
```

From a CSV, `usecols` still has to scan every line to find its commas. From Parquet, the other five
columns are never touched. Lesson 20 uses that on a file large enough for it to matter.

**Parquet is the format to keep your own intermediate results in**: a cleaned table saved as Parquet
comes back exactly as you left it, types and all. CSV is the format to give to people and to tools
you do not control.

| format | keeps the types | the trips on disk | reads part of a file |
|---|---|---|---|
| CSV | no: everything is text, and `read_csv` guesses | 2.3 MB | rows with `nrows`; columns only by scanning |
| JSON Lines | partly: numbers and text, and `read_json` guesses dates | 5.3 MB | no |
| Excel | numbers and dates, not pandas' own types | (the weather: 12 KB) | sheets, and rows with `nrows` |
| Parquet | yes, every column's dtype | 0.8 MB | columns, without reading the rest |
| SQL | the database's types | in the database | whatever the query asks for |
