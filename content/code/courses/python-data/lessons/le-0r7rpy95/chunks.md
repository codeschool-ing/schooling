---
title: Chunks, for a file larger than memory
version: 1
---

**`read_csv(chunksize=n)` reads a file `n` rows at a time, so a file larger than memory can be
processed one piece at a time.** Each piece is an ordinary DataFrame; what you keep between pieces is
up to you, and it decides which questions this can answer.

The big file of the last section, made again for this one and counted by plan, two hundred thousand
rows at a time:

```python
big.to_csv("big.csv", index=False)
total = None
pieces = 0
for chunk in pd.read_csv("big.csv", chunksize=200_000, usecols=["plan"]):
    counts = chunk["plan"].value_counts()
    total = counts if total is None else total.add(counts, fill_value=0)
    pieces += 1
pieces, total.astype(int)
```

```
(6,
 plan
 annual    703140
 day       296970
 Name: count, dtype: int64)
```

Six pieces, five full and one of the 110 rows left over, and the counts are thirty times the counts of
lesson 13, as they should be. At no point was more than one piece in memory, plus the running total
of two numbers.

`add(..., fill_value=0)` matters: a plan absent from one chunk would otherwise turn the total for it
into `NaN`, the alignment rule of lesson 9 working against you.

## What chunks can answer

A count, a sum, a minimum and a maximum combine across pieces: the total of totals is the total. A
mean combines too, if you keep its sum and its count rather than the mean itself. **A median does
not**: the median of six medians is not the median of the file, and no small running summary gives it.
The same goes for anything that needs every value at once, a sort, a distinct count over many values,
a `groupby` with a key per row.

```python
lengths = []
for chunk in pd.read_csv("big.csv", chunksize=200_000, usecols=["started_at", "ended_at"],
                         parse_dates=["started_at", "ended_at"], date_format=fmt):
    minutes = (chunk["ended_at"] - chunk["started_at"]).dt.total_seconds() / 60
    lengths.append(minutes.median())
round(np.median(lengths), 3), round(typed["ended_at"].sub(typed["started_at"]).dt.total_seconds().div(60).median(), 3)
```

```
(np.float64(14.183), np.float64(14.183))
```

Here the two happen to agree to three decimals, because each chunk is a copy of the same year and its
median is the year's median. On real data, where January's chunk and July's chunk differ, the median
of medians drifts away from the true one, and nothing in the result says so. **Chunks suit questions
that add up.** For the others, the next section names the tools.

```python
os.remove("big.csv")
```
