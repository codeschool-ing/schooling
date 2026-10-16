---
title: When pandas is the wrong tool
version: 1
---

**pandas holds the whole table in memory and runs each operation on one processor core.** Within
those two limits it is the most flexible tool for tables in Python, and this course has used it for
everything. Past them, the honest answer is a different tool, and knowing where the limits are saves
a day of fighting them.

The memory limit first. A rough rule from this lesson's measurements: the table needs about the
size of the file once typed, and more than that while it is still text. On a machine with 16 GB, a CSV of a
gigabyte or two is comfortable, ten gigabytes is a project, and fifty is the wrong tool. Before
reaching for another one, the cheap steps of this lesson come first, in this order:

1. **Read fewer columns**, with `usecols` or Parquet's `columns`.
2. **Give the columns their types** at reading time, with `dtype` and `parse_dates`.
3. **Store as Parquet** what you will read more than once.
4. **Read in chunks** when the question adds up.
5. **Work on a sample** while writing the analysis, and run it on the whole at the end.

A sample of a tenth, reproducible because of lesson 8's seed:

```python
sample = typed.sample(frac=0.1, random_state=2025)
len(sample), round(sample["bike"].eq("electric").mean(), 3), round(typed["bike"].eq("electric").mean(), 3)
```

```
(3334, np.float64(0.345), np.float64(0.35))
```

A tenth of the rows gives the electric share to within half a percentage point, and every cell of a
notebook runs ten times faster while you are still deciding what to compute.

## The tools past the limit

When those steps are not enough, three kinds of tool take over. None of them is installed in this
course's lab, and none is needed for its data; they are named here so that the day a file does not
fit, you know what to look for.

| tool | what it is | why it helps |
|---|---|---|
| **DuckDB** | a database that runs inside your Python process, queried in SQL | reads CSV and Parquet directly from disk, uses every core, and does not need the table in memory |
| **Polars** | a DataFrame library with a different interface from pandas | uses every core, and its lazy mode plans the whole query before reading the file |
| **a database server** | PostgreSQL and the like | the data lives there, and only the answer comes to your notebook |

All three answer the median question of the last section correctly on a file larger than memory,
because they can sort and count without holding everything at once. Each has its own way of writing a
query, and lesson 10's `read_sql` is how a result comes back into pandas when the heavy part is done.

**pandas stays the tool for the last step**: the table that fits, the chart, the notebook a person
reads. The skill is noticing when the step before it belongs somewhere else.
