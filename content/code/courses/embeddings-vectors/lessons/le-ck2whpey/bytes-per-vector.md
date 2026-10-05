---
title: Bytes per vector
version: 1
---

The size of a vector store is decided the day you choose the model, long before you choose a
database. It is the number of dimensions times four bytes, times the number of rows. People tend
to expect a database to shrink that, or at least to add nothing to it. This section measures what
it really adds.

## Four bytes a number

Every coordinate is a `float32`, so a vector costs **4 × d bytes**, whatever text it came from.
That is 1,536 bytes for the 384 numbers of all-MiniLM-L6-v2 (lesson 1 printed it), 6,144 for the
1536 of text-embedding-3-small, and twice that again for the 3072 of text-embedding-3-large or
gemini-embedding-001. The dimension is printed in the `dims` column of the price sheet that section 05 of this lesson
quotes, and it is the one number on that sheet that you pay for every month rather than once.

Because the contents of the numbers make no difference to their size, the measurements in this
lesson use random vectors of length 1 instead of embeddings: 20,000 of them, at 384 and at 1536
dimensions, from a helper six lines long.

```python
import numpy as np


def unit_vectors(n, d, seed=18):
    """n random vectors of d float32 numbers, each of length 1."""
    rng = np.random.default_rng(seed)
    X = rng.standard_normal((n, d), dtype=np.float32)
    return X / np.linalg.norm(X, axis=1, keepdims=True)
```

## In a file, nothing is added

```schooling-example
{
  "language": "python",
  "file": "files.py",
  "parts": [
    {
      "code": "import os\nimport faiss\nimport numpy as np\nfrom synth import unit_vectors\n\nN = 20_000",
      "note": "`unit_vectors` is the six-line helper above. Twenty thousand rows is enough for every size to settle into a per-vector figure."
    },
    {
      "code": "for d in (384, 1536):\n    X = unit_vectors(N, d)\n    np.save(f\"v{d}.npy\", X)\n    flat = faiss.IndexFlatIP(d)\n    flat.add(X)\n    faiss.write_index(flat, f\"flat{d}.faiss\")",
      "note": "For each dimension, the same vectors three ways: in memory, as NumPy's `.npy` file, and as a FAISS flat index written to disk."
    },
    {
      "code": "    print(f\"{d:5} dims  in memory {X.nbytes:>11,}  {X.nbytes // N:>5} per vector\")\n    for f in (f\"v{d}.npy\", f\"flat{d}.faiss\"):\n        size = os.path.getsize(f)\n        print(f\"{f:>16}  {size:>11,}  {size / N:>7.1f} per vector\")",
      "note": "The bytes in memory, and each file's size divided by the number of vectors. Whatever is above 4 × d per vector is the format's own overhead."
    }
  ]
}
```

```
ana@lab:~/emb$ python files.py
  384 dims  in memory  30,720,000   1536 per vector
        v384.npy   30,720,128   1536.0 per vector
   flat384.faiss   30,720,045   1536.0 per vector
 1536 dims  in memory 122,880,000   6144 per vector
       v1536.npy  122,880,128   6144.0 per vector
  flat1536.faiss  122,880,045   6144.0 per vector
```

**A file costs 4 × d bytes per vector and nothing more.** NumPy's `.npy` puts a header of 128
bytes in front of the whole array and FAISS's flat index 45, so over 20,000 vectors neither moves
the per-vector column off `1536.0` or `6144.0`. That is the floor: the numbers, laid end to end.

## In PostgreSQL, a row costs more than its vector

The same vectors in pgvector, one table per dimension, measured by a query that splits a table
into its parts:

```schooling-example
{
  "language": "python",
  "file": "load.py",
  "parts": [
    {
      "code": "import sys\nimport numpy as np\nimport psycopg\nfrom pgvector.psycopg import register_vector\n\nd = int(sys.argv[1])\nX = np.load(f\"v{d}.npy\")",
      "note": "Read back the `.npy` that `files.py` wrote, for the dimension given on the command line."
    },
    {
      "code": "with psycopg.connect(autocommit=True) as conn:\n    conn.execute(\"CREATE EXTENSION IF NOT EXISTS vector\")\n    register_vector(conn)\n    conn.execute(f\"CREATE TABLE v{d} (id bigint PRIMARY KEY, embedding vector({d}))\")",
      "note": "A table with nothing but an id and the vector, so that its size is the vector's cost and the row's."
    },
    {
      "code": "    copy = f\"COPY v{d} (id, embedding) FROM STDIN WITH (FORMAT BINARY)\"\n    with conn.cursor().copy(copy) as cp:\n        cp.set_types([\"int8\", \"vector\"])\n        for i, v in enumerate(X):\n            cp.write_row((i, v))\n    conn.execute(f\"VACUUM ANALYZE v{d}\")\n    print(f\"v{d}: {len(X)} rows\")",
      "note": "`COPY` in binary is the fast way to load rows; `VACUUM ANALYZE` leaves the table's statistics, including its row count, up to date."
    }
  ]
}
```

```sql
SELECT c.relname                          AS "table",
       c.reltuples::bigint                AS "rows",
       pg_relation_size(c.oid)            AS heap,
       pg_relation_size(c.reltoastrelid)  AS toast,
       pg_indexes_size(c.oid)             AS indexes,
       pg_total_relation_size(c.oid) / c.reltuples::bigint AS per_row
  FROM pg_class c
 WHERE c.relname IN ('v384', 'v1536')
 ORDER BY 1 DESC;
```

```
ana@lab:~/emb$ python load.py 384 && python load.py 1536
v384: 20000 rows
v1536: 20000 rows
ana@lab:~/emb$ psql -f sizes.sql
 table | rows  |   heap   |   toast   | indexes | per_row 
-------+-------+----------+-----------+---------+---------
 v384  | 20000 | 33030144 |         0 |  466944 |    1676
 v1536 | 20000 |  1212416 | 163840000 |  466944 |    8371
(2 rows)
```

The two rows pay their overhead in different ways, so read them apart.

**At 384 dimensions a row costs 1,676 bytes to hold 1,536 bytes of numbers.** pgvector stores a
vector as its 4 × d bytes plus a header of 8, and PostgreSQL adds its own header and a pointer to
every row. A page of 8 KB only takes whole rows, so the space left at the end of each page is
wasted. `indexes` is the primary key, 466,944 bytes in both tables.

**At 1536 dimensions the table proper is almost empty.** `heap` is 1,212,416 bytes and `toast` is
163,840,000. A vector of 1536 dimensions, over 6 KB, is too big to share a page with its
neighbours, so PostgreSQL moves it out of the row into the table's **TOAST** storage, cut into chunks, and leaves a pointer
behind. pgvector 0.6.0 declares its type `STORAGE external`, which means moved out and never
compressed. Counting everything, a row costs 8,371 bytes for 6,144 bytes of numbers.

Nothing here is a defect, and both overheads are fixed per row. What it means in practice is that
**the raw arithmetic understates what a database will hold**, so when you budget, multiply by
the measured `per_row` and not by 4 × d. And that is still before any index, which is the next
section.
