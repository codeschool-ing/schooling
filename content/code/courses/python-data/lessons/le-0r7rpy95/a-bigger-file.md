---
title: A bigger file, and reading less of it
version: 1
---

**Reading a file costs time in proportion to what is read, so the fastest read is the one that reads
less**: fewer columns, a format that stores columns apart, types that need no parsing. With 33,337
rows none of it is visible, so this section makes a file thirty times larger.

A million trips, the year repeated thirty times with new ids, written both as CSV and as Parquet:

```python
big = pd.concat([trips] * 30, ignore_index=True)
big["trip_id"] = np.arange(1, len(big) + 1)
big.to_csv("big.csv", index=False)
big.to_parquet("big.parquet")
len(big), os.path.getsize("big.csv"), os.path.getsize("big.parquet")
```

```
(1000110, 69259150, 10343421)
```

The same million rows are 69 MB as CSV and 10 MB as Parquet. Parquet, as lesson 10 showed, stores
each column apart, compressed, with its type, and a column of two words repeated a million times
compresses to almost nothing.

Reading each, timed with `time.perf_counter`, a clock that only counts forward:

```python
start = time.perf_counter()
from_csv = pd.read_csv("big.csv")
t_csv = time.perf_counter() - start

start = time.perf_counter()
from_parquet = pd.read_parquet("big.parquet")
t_parquet = time.perf_counter() - start

round(t_csv, 2), round(t_parquet, 2)
```

```
(2.35, 0.43)
```

Your times will differ, and the order will not. The CSV reader parses a million lines of text,
character by character, and guesses each column's type; the Parquet reader copies typed columns that
are already laid out the way pandas wants them.

## Only the columns you need

A question about plans needs one column of seven:

```python
start = time.perf_counter()
plans = pd.read_parquet("big.parquet", columns=["plan"])
t_one = time.perf_counter() - start

start = time.perf_counter()
plans_csv = pd.read_csv("big.csv", usecols=["plan"])
t_one_csv = time.perf_counter() - start

round(t_one, 3), round(t_one_csv, 2)
```

```
(0.027, 0.43)
```

Parquet reads one column without touching the others, which is the whole point of storing columns
apart. `usecols` saves the CSV reader the work of keeping the other six, but it still has to read
every line of the file to find the one field it wants, so it saves less. **Ask for the columns you
need, and store what you will read again as Parquet.**

The files are not needed again; they can go:

```python
os.remove("big.csv")
os.remove("big.parquet")
```
