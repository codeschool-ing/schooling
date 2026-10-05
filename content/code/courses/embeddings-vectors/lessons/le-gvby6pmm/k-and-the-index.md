---
title: k and the index
version: 1
---

So far k has been yours to choose. With an approximate index it is partly the index's. Lesson 15
showed that HNSW searches by walking a graph and keeping a list of the best candidates it has seen,
and that the length of that list, **ef**, is the dial between speed and recall. What lesson 15 did
not need to say is what happens when you ask for more results than that list holds. Two libraries
answer it in opposite ways.

## pgvector returns fewer rows

`fill.py` puts 2,000 rows into a PostgreSQL table and builds an HNSW index on them. The vectors are
random, not embeddings of any text, because what follows is a property of the index and not of the
data:

```python
import numpy as np
import psycopg
from pgvector.psycopg import register_vector

rng = np.random.default_rng(16)
V = rng.standard_normal((2000, 384)).astype(np.float32)
V /= np.linalg.norm(V, axis=1, keepdims=True)

with psycopg.connect(autocommit=True) as conn:
    conn.execute("CREATE EXTENSION IF NOT EXISTS vector")
    register_vector(conn)
    conn.execute("CREATE TABLE points (id int PRIMARY KEY, embedding vector(384))")
    with conn.cursor().copy("COPY points FROM STDIN WITH (FORMAT BINARY)") as copy:
        copy.set_types(["int4", "vector"])
        for i, v in enumerate(V):
            copy.write_row((i, v))
    conn.execute("CREATE INDEX ON points USING hnsw (embedding vector_cosine_ops)")
```

And `top100.sql` asks for the 100 nearest neighbours of row 7, counting what comes back:

```sql
SELECT count(*) AS returned
FROM (SELECT id FROM points
      ORDER BY embedding <=> (SELECT embedding FROM points WHERE id = 7)
      LIMIT 100) AS top;
```

```
ana@lab:~/emb$ python fill.py
ana@lab:~/emb$ psql -c "SHOW hnsw.ef_search"
ERROR:  unrecognized configuration parameter "hnsw.ef_search"
ana@lab:~/emb$ psql -f top100.sql -c "SHOW hnsw.ef_search"
 returned 
----------
       40
(1 row)

 hnsw.ef_search 
----------------
 40
(1 row)
```

**The query asked for 100 rows and got 40**, with no error and no warning. pgvector's HNSW search
keeps `hnsw.ef_search` candidates, 40 unless you set it, and the index scan stops when they run out.
`LIMIT 100` cannot ask for more than the scan produces. The first `SHOW` failed because the setting
belongs to pgvector's library, which a session loads the first time it uses a vector; after the
query, the same `SHOW` prints the 40. The plan confirms the index is doing the
work:

```
ana@lab:~/emb$ psql -c "EXPLAIN (COSTS OFF) SELECT id FROM points ORDER BY embedding <=> (SELECT embedding FROM points WHERE id = 7) LIMIT 100"
                       QUERY PLAN                        
---------------------------------------------------------
 Limit
   InitPlan 1 (returns $0)
     ->  Index Scan using points_pkey on points points_1
           Index Cond: (id = 7)
   ->  Index Scan using points_embedding_idx on points
         Order By: (embedding <=> $0)
(6 rows)
```

Raise `ef_search` to 100 and the 100 rows come back. Turn the index off and PostgreSQL sorts every
row by distance, which is exact, and the 100 come back too:

```
ana@lab:~/emb$ psql -c "SET hnsw.ef_search = 100" -f top100.sql
SET
 returned 
----------
      100
(1 row)

ana@lab:~/emb$ psql -c "SET enable_indexscan = off" -f top100.sql
SET
 returned 
----------
      100
(1 row)
```

That last result is the proof that the 40 belonged to the index. The table had 2,000 rows the
whole time.

This was run on pgvector 0.6.0, the version in the lab. pgvector 0.8.0 added **iterative index
scans**, which keep searching when a scan runs out before the `LIMIT` is filled; lesson 17 meets
the problem they solve in its sharpest form. They are not in 0.6.0, and nothing in this lesson
used them.

## hnswlib quietly searches wider

The same 2,000 vectors in hnswlib, with its search breadth set to 10 and 100 neighbours asked for:

```schooling-example
{
  "language": "python",
  "file": "ef.py",
  "parts": [
    {
      "code": "import hnswlib\nimport numpy as np\n\nrng = np.random.default_rng(16)\nV = rng.standard_normal((2000, 384)).astype(np.float32)\nV /= np.linalg.norm(V, axis=1, keepdims=True)\nindex = hnswlib.Index(space=\"cosine\", dim=384)\nindex.init_index(max_elements=2000)\nindex.add_items(V, np.arange(2000))",
      "note": "2,000 random unit vectors, the same seed as `fill.py`, in an hnswlib index with its default parameters."
    },
    {
      "code": "index.set_ef(10)\nlabels, distances = index.knn_query(V[7], k=100)\nprint(\"ef:\", index.ef, \" asked for 100, got\", labels.shape[1])",
      "note": "Set the search breadth to 10 and ask for 100 neighbours."
    }
  ],
  "output": "ana@lab:~/emb$ python ef.py\nef: 10  asked for 100, got 100"
}
```

**hnswlib returned all 100.** It searches with the larger of `ef` and `k`, so asking for more than
`ef` widens the search for that query, and `index.ef` still says 10 afterwards. That is the
friendlier behaviour, and it means the cost of a query in hnswlib grows with k even when you never
touched `ef`.

## What to do with it

The rule that covers both is one line: **the index's search breadth must be at least k**, and
larger than k if you want good recall. In pgvector that is a setting you own:

```sql
SET hnsw.ef_search = 100;
```

`SET` lasts for the session, `SET LOCAL` for one transaction, and `ALTER DATABASE ... SET` makes it
the default for new connections. Put it where every query that uses a large `LIMIT` will get it,
and add a test that counts the rows a large `LIMIT` returns, because a short result looks exactly
like a search that had fewer good answers.
