---
title: Indexes in PostgreSQL
version: 1
---

Every search so far read all 40 rows, computed 40 distances and sorted them. That is exact, and on
40 rows it is instant. An index trades the exactness for speed: it answers from a structure built
in advance and reads a small part of the table. pgvector 0.6.0 offers two such structures, **HNSW**
and **IVFFlat**, and both are approximate. Lesson 15 explains how each one works and what its
parameters do. This section is about the PostgreSQL side: building one, and checking that a query
uses it.

## An index the planner ignores

The common belief is that creating an index makes the queries use it. Build an HNSW index on the
help centre and ask PostgreSQL how it would run the search:

```
ana@lab:~/emb$ psql -c "CREATE INDEX ON articles USING hnsw (embedding vector_cosine_ops)"
CREATE INDEX
ana@lab:~/emb$ psql -c "EXPLAIN (COSTS OFF) SELECT id FROM articles ORDER BY embedding <=> (SELECT embedding FROM queries WHERE id = 'q01') LIMIT 3"
                    QUERY PLAN                    
--------------------------------------------------
 Limit
   InitPlan 1 (returns $0)
     ->  Index Scan using queries_pkey on queries
           Index Cond: (id = 'q01'::text)
   ->  Sort
         Sort Key: ((articles.embedding <=> $0))
         ->  Seq Scan on articles
(7 rows)
```

**`Seq Scan on articles`: the index exists and the plan does not touch it.** PostgreSQL's planner
estimates the cost of each way to run a query and picks the cheapest. Forty rows fit in a few pages,
and reading them all is cheaper than walking a graph, so the planner reads them all. That is the
right decision, and it is also why a test on a small table proves nothing about the index. `EXPLAIN`
shows the plan without running the query; it is the only way to know which one you got.

## Twenty thousand rows

To see the index do its work, the table has to be big enough for a full read to cost something.
`noise.py` makes one: 20,000 random unit vectors with no text behind them, because what follows is
about the plan and not about the meaning.

```schooling-example
{
  "language": "python",
  "file": "noise.py",
  "parts": [
    {
      "code": "import numpy as np\nimport psycopg\nfrom pgvector.psycopg import register_vector\n\nrng = np.random.default_rng(14)\nX = rng.standard_normal((20000, 384)).astype(np.float32)\nX /= np.linalg.norm(X, axis=1, keepdims=True)",
      "note": "20,000 random vectors of 384 numbers, drawn from a normal distribution with a fixed seed and divided by their lengths. No text is behind them."
    },
    {
      "code": "with psycopg.connect() as conn:\n    conn.execute(\"CREATE TABLE noise (id integer PRIMARY KEY, embedding vector(384) NOT NULL)\")\n    register_vector(conn)\n    cur = conn.cursor()\n    with cur.copy(\"COPY noise (id, embedding) FROM STDIN WITH (FORMAT BINARY)\") as copy:\n        copy.set_types([\"integer\", \"vector\"])\n        for i, v in enumerate(X):\n            copy.write_row((i, v))\n    print(conn.execute(\"SELECT count(*) FROM noise\").fetchone()[0], \"rows in noise\")",
      "note": "`COPY` in binary format is PostgreSQL's bulk load, much faster than one INSERT per row. `set_types` tells psycopg what each column is."
    }
  ],
  "output": "ana@lab:~/emb$ python noise.py\n20000 rows in noise"
}
```

The same search, nearest three to row 7, before there is an index on `noise`:

```
ana@lab:~/emb$ psql -e -f before.sql
EXPLAIN (ANALYZE, COSTS OFF)
SELECT id FROM noise
ORDER BY embedding <=> (SELECT embedding FROM noise WHERE id = 7)
LIMIT 3;
                                           QUERY PLAN                                           
------------------------------------------------------------------------------------------------
 Limit (actual time=13.014..15.303 rows=3 loops=1)
   InitPlan 1 (returns $0)
     ->  Index Scan using noise_pkey on noise noise_1 (actual time=0.039..0.041 rows=1 loops=1)
           Index Cond: (id = 7)
   ->  Gather Merge (actual time=13.013..15.294 rows=3 loops=1)
         Workers Planned: 2
         Params Evaluated: $0
         Workers Launched: 2
         ->  Sort (actual time=6.371..6.372 rows=3 loops=3)
               Sort Key: ((noise.embedding <=> $0))
               Sort Method: top-N heapsort  Memory: 25kB
               Worker 0:  Sort Method: top-N heapsort  Memory: 25kB
               Worker 1:  Sort Method: top-N heapsort  Memory: 25kB
               ->  Parallel Seq Scan on noise (actual time=0.015..5.732 rows=6667 loops=3)
 Planning Time: 0.373 ms
 Execution Time: 15.740 ms
(16 rows)
```

Then build the index and run it again:

```
ana@lab:~/emb$ psql -e -f after.sql
Timing is on.
CREATE INDEX ON noise USING hnsw (embedding vector_cosine_ops);
CREATE INDEX
Time: 8262.853 ms (00:08.263)
Timing is off.
EXPLAIN (ANALYZE, COSTS OFF)
SELECT id FROM noise
ORDER BY embedding <=> (SELECT embedding FROM noise WHERE id = 7)
LIMIT 3;
                                           QUERY PLAN                                           
------------------------------------------------------------------------------------------------
 Limit (actual time=3.417..3.424 rows=3 loops=1)
   InitPlan 1 (returns $0)
     ->  Index Scan using noise_pkey on noise noise_1 (actual time=0.042..0.042 rows=1 loops=1)
           Index Cond: (id = 7)
   ->  Index Scan using noise_embedding_idx on noise (actual time=3.416..3.420 rows=3 loops=1)
         Order By: (embedding <=> $0)
 Planning Time: 0.484 ms
 Execution Time: 3.587 ms
(8 rows)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Two query plans for the same search, the three nearest of 20,000 rows. Without an index: a Limit above a Gather Merge, above 3 Sort nodes, each above a Parallel Seq Scan that read 6667 rows; execution time 15.740 ms. With the HNSW index: a Limit above one Index Scan using noise_embedding_idx that returned 3 rows; execution time 3.587 ms.\"><text x=\"185\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">without an index</text><rect x=\"115\" y=\"40\" width=\"140\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Limit</text><path d=\"M185 68 L185 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"100\" y=\"88\" width=\"170\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Gather Merge</text><path d=\"M185 116 L70 136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20\" y=\"138\" width=\"100\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Sort</text><path d=\"M70 166 L70 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"15\" y=\"188\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Parallel</text><text x=\"70\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Seq Scan</text><text x=\"70\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">rows=6667</text><path d=\"M185 116 L185 136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"135\" y=\"138\" width=\"100\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Sort</text><path d=\"M185 166 L185 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"130\" y=\"188\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Parallel</text><text x=\"185\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Seq Scan</text><text x=\"185\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">rows=6667</text><path d=\"M185 116 L300 136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"250\" y=\"138\" width=\"100\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Sort</text><path d=\"M300 166 L300 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"245\" y=\"188\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Parallel</text><text x=\"300\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Seq Scan</text><text x=\"300\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">rows=6667</text><text x=\"185\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">rows read by each</text><text x=\"185\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3 processes, each reads its share of the table</text><text x=\"185\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">Execution Time: 15.740 ms</text><path d=\"M380 30 L380 325\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"550\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\" font-weight=\"600\">with the HNSW index</text><rect x=\"480\" y=\"40\" width=\"140\" height=\"28\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Limit</text><path d=\"M550 68 L550 86\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"420\" y=\"88\" width=\"260\" height=\"44\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Index Scan using</text><text x=\"550\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">noise_embedding_idx</text><text x=\"550\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">rows=3</text><text x=\"550\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">walks the graph, reads no table in full</text><text x=\"550\" y=\"318\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">Execution Time: 3.587 ms</text></svg>", "caption": "The same query on the 20,000 rows of noise, from the two EXPLAIN ANALYZE outputs above. Without an index every row is read and sorted, split over parallel workers; with the HNSW index one index scan hands back the three rows. The times are this run's."}
```

**Before, three processes read about 6,667 rows each and sorted them; after, one index scan
returned the three rows.** The two `Execution Time` lines, `15.740 ms` and `3.587 ms`, are this
run's, on a machine other people were using, and the gap between them grows with the table: the
sequential scan reads every row and the index scan does not. The build took `8262.853 ms`, once, and
every later insert pays a little of that again to add itself to the graph. Lesson 18 weighs the
index on disk.

The index answer is approximate, and nothing above checked that its three rows are the exact
three. Lesson 15 measures how often an approximate index misses a true neighbour.

## The operator has to match the index

An index is built for one distance. The `vector_cosine_ops` in the `CREATE INDEX` above says this one
sorts by `<=>`, and nothing else. Ask for the L2 distance, or write the cosine as a similarity and
sort it the other way, and the planner cannot use it:

```
ana@lab:~/emb$ psql -e -f unused.sql
EXPLAIN (COSTS OFF)
SELECT id FROM noise
ORDER BY embedding <-> (SELECT embedding FROM noise WHERE id = 7)
LIMIT 3;
                      QUERY PLAN                      
------------------------------------------------------
 Limit
   InitPlan 1 (returns $0)
     ->  Index Scan using noise_pkey on noise noise_1
           Index Cond: (id = 7)
   ->  Sort
         Sort Key: ((noise.embedding <-> $0))
         ->  Seq Scan on noise
(7 rows)

EXPLAIN (COSTS OFF)
SELECT id FROM noise
ORDER BY 1 - (embedding <=> (SELECT embedding FROM noise WHERE id = 7)) DESC
LIMIT 3;
                                 QUERY PLAN                                  
-----------------------------------------------------------------------------
 Limit
   InitPlan 1 (returns $0)
     ->  Index Scan using noise_pkey on noise noise_1
           Index Cond: (id = 7)
   ->  Sort
         Sort Key: (('1'::double precision - (noise.embedding <=> $0))) DESC
         ->  Seq Scan on noise
(7 rows)
```

**Both plans went back to `Seq Scan on noise`**, with no warning: the queries still return the
right rows, slowly. The second one is the trap, because `1 - (embedding <=> q)` sorted descending is
the same order as `embedding <=> q` ascending. The planner does not do that algebra. An index serves
`ORDER BY` *column* *operator* *value*, ascending, with a `LIMIT`, and the operator must be the one
the operator class names:

| operator | distance | operator class |
|---|---|---|
| `<->` | L2 | `vector_l2_ops` |
| `<#>` | negative inner product | `vector_ip_ops` |
| `<=>` | cosine | `vector_cosine_ops` |

Write the `ORDER BY` in that shape and compute the similarity in the `SELECT` list, as `search.py`
does.

## IVFFlat, and an index that loses rows

The second kind of index sorts the rows into groups, `lists` of them, when it is built. A query
looks only in the group or groups nearest to the question. Here it is on the 40 articles, with the
100 lists that would suit a large table:

```
ana@lab:~/emb$ psql -c "CREATE INDEX ON articles USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100)"
NOTICE:  ivfflat index created with little data
DETAIL:  This will cause low recall.
HINT:  Drop the index until the table has more data.
CREATE INDEX
ana@lab:~/emb$ python search.py "how do I get my money back"
0.554  0.446  h18  Returning a gift
```

**The search asked for three articles and got one**, with no error. PostgreSQL printed a `NOTICE`
when the index was built, and nobody reads a notice in a deployment script. The planner chose the
new index over the HNSW one, which `\d articles` and `EXPLAIN` confirm:

```
ana@lab:~/emb$ psql -c "\d articles"
                 Table "public.articles"
  Column   |    Type     | Collation | Nullable | Default 
-----------+-------------+-----------+----------+---------
 id        | text        |           | not null | 
 category  | text        |           | not null | 
 lang      | text        |           | not null | 
 title     | text        |           | not null | 
 body      | text        |           | not null | 
 embedding | vector(384) |           | not null | 
Indexes:
    "articles_pkey" PRIMARY KEY, btree (id)
    "articles_embedding_idx" hnsw (embedding vector_cosine_ops)
    "articles_embedding_idx1" ivfflat (embedding vector_cosine_ops) WITH (lists='100')

ana@lab:~/emb$ psql -c "EXPLAIN (COSTS OFF) SELECT id FROM articles ORDER BY embedding <=> (SELECT embedding FROM queries WHERE id = 'q01') LIMIT 3"
                         QUERY PLAN                         
------------------------------------------------------------
 Limit
   InitPlan 1 (returns $0)
     ->  Index Scan using queries_pkey on queries
           Index Cond: (id = 'q01'::text)
   ->  Index Scan using articles_embedding_idx1 on articles
         Order By: (embedding <=> $0)
(6 rows)
```

And the setting that decides how many groups a query looks in:

```
ana@lab:~/emb$ psql -c "SELECT count(*) AS returned FROM (SELECT id FROM articles ORDER BY embedding <=> (SELECT embedding FROM queries WHERE id = 'q01') LIMIT 3) AS top" -c "SHOW ivfflat.probes"
 returned 
----------
        1
(1 row)

 ivfflat.probes 
----------------
 1
(1 row)
```

**`ivfflat.probes` is 1, so the query looked in one group, and that group held one article.** The
groups were computed from the 40 rows that existed when the index was built: 100 groups for 40
articles leaves most of them empty. This is the general rule for IVFFlat,
not a quirk of a tiny table. Its groups are learnt from the data present at `CREATE INDEX`, so it is
built after the table is loaded, and rebuilt when the data has changed a lot. HNSW has no such step
and can be created on an empty table. Lesson 15 explains `lists` and `probes`.

Dropping it brings the three rows back:

```
ana@lab:~/emb$ psql -c "DROP INDEX articles_embedding_idx1"
DROP INDEX
ana@lab:~/emb$ python search.py "how do I get my money back"
0.554  0.446  h18  Returning a gift
0.562  0.438  h15  When your refund arrives
0.601  0.399  h22  Charged twice for one order
```

The lesson to keep is the one `EXPLAIN` taught twice: **the index a query uses is the planner's
choice, and an approximate index can return fewer rows than the `LIMIT` without saying so.** Lesson
16 meets the HNSW version of that, and lesson 17 the version a filter causes. Both are found the same
way, by counting the rows a query returns on a table the size of production.
