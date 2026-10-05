---
title: Pre-filtering
version: 1
---

The other order is to filter first and search only what passes. That is **pre-filtering**, and it
has the property post-filtering lacks: **it returns k results whenever k rows pass the filter**,
and they are the k nearest of those rows. `pre_filter` in `store.py` did it in three lines, and it
found three Portuguese articles where post-filtering found none.

Its price is the one lesson 11 put on every exact search: the time is proportional to the number of
rows searched. When the filter is narrow, that is a gift, because the filter has already thrown
most of the collection away. When the filter passes most of the rows, a pre-filter is a brute-force
search over nearly everything, with no index to help.

## What it costs, measured

`prefilter_cost.py` makes 200,000 random vectors, marks one row in 100 `pt`, one in 10 `es` and the
rest `en`, and times one exact pre-filtered query for each language:

```schooling-example
{
  "language": "python",
  "file": "prefilter_cost.py",
  "parts": [
    {
      "code": "import timeit\nimport numpy as np\n\nrng = np.random.default_rng(17)\nN = 200_000\nD = rng.standard_normal((N, 384), dtype=np.float32)\nD /= np.linalg.norm(D, axis=1, keepdims=True)\nrow = np.arange(N)\nlang = np.where(row % 100 == 0, \"pt\", np.where(row % 10 == 1, \"es\", \"en\"))\nq = D[7]",
      "note": "200,000 random unit vectors, and a language for each row decided by its number: one in 100 `pt`, one in 10 `es`, the rest `en`."
    },
    {
      "code": "def pre_filter(value, k=10):\n    allowed = np.flatnonzero(lang == value)\n    scores = D[allowed] @ q\n    top = np.argpartition(-scores, k)[:k]\n    return allowed[top[np.argsort(-scores[top])]]",
      "note": "The pre-filter as an exact search over the rows that pass: `argpartition` finds the best `k` without sorting the rest, and only those `k` are sorted."
    },
    {
      "code": "for value in (\"pt\", \"es\", \"en\"):\n    seconds = min(timeit.repeat(lambda: pre_filter(value), number=1, repeat=20))\n    print(f\"lang = {value!r}: {np.sum(lang == value):7,} rows searched  {seconds * 1000:6.1f} ms\")",
      "note": "Time one query for a filter that keeps 1% of the rows, one that keeps 10% and one that keeps 89%, the best of 20 runs each."
    }
  ],
  "output": "ana@lab:~/emb$ python prefilter_cost.py\nlang = 'pt':   2,000 rows searched     0.7 ms\nlang = 'es':  20,000 rows searched     4.5 ms\nlang = 'en': 178,000 rows searched    83.3 ms"
}
```

**Searching the Portuguese 2,000 took 0.7 ms; searching the English 178,000 took 83.3 ms.** The
same code, the same machine, more than a hundred times the time for 89 times the rows. That
is the shape to remember: the cost of a pre-filter follows the size of what passes.

So the two orders fail in opposite places. **Post-filtering fails when the filter is narrow**: it
returns too few rows. **Pre-filtering is slow when the filter is wide**: it is exact and searches
too many. A filter that passes 1% of the rows wants the pre-filter, one that passes
nearly all of them loses little to a post-filter, and the hard cases are in between.

## Pre-filtering inside PostgreSQL

PostgreSQL decides the order itself, from its cost estimates, and the post-filtering section saw
it choose the index and filter afterwards. Two things change its mind.

**Turning the vector index off for the query** leaves the planner a scan that filters every row and
then sorts the ones that pass by distance: an exact pre-filter. Lesson 16 used `SET
enable_indexscan = off` for the same purpose, and it is a sound choice when you know the filter is
narrow.

**A partial index** is an HNSW index over only the rows that pass a condition, built with a
`WHERE` on the `CREATE INDEX`. The planner uses it for queries with the same condition, and since
every row in it already passes, there is nothing left to filter out:

```
ana@lab:~/emb$ psql -c "CREATE INDEX ON messages USING hnsw (embedding vector_cosine_ops) WHERE lang = 'pt'"
CREATE INDEX
ana@lab:~/emb$ psql -f ten.sql
 query_row | pt | es 
-----------+----+----
         1 | 10 |  6
         2 | 10 |  3
         3 | 10 |  3
         4 | 10 |  2
         5 | 10 |  2
         6 | 10 |  4
         7 | 10 |  3
         8 | 10 |  3
(8 rows)
```

**Every query row got its 10 Portuguese rows.** The Spanish column is unchanged, because the new
index only covers `lang = 'pt'`; Spanish queries still go through the full index and its filter.
A partial index is one more index to build and keep up to date for each value you give it. So it
suits a field with a few values that matter, such as a language or a status, and not one with a
value per customer. The tenants section of this lesson comes back to that.

PostgreSQL also offers **partitioning**, a table split by a column's value into smaller tables,
each with its own index. It does the same job at a larger grain, and it was not run here.
