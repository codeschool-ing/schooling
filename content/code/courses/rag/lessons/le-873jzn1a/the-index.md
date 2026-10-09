---
title: The vector index
version: 2
---

A table of vectors can already be searched: order the rows by distance to the question and take the
first few. PostgreSQL does that by computing the distance to every row, which for 137 chunks takes no
time at all and for ten million takes too long to wait for. An **index** makes the search approximate
and fast, and `embeddings-vectors` lessons 15 and 16 measured how: what HNSW builds, what `m`,
`ef_construction` and `ef_search` trade, and how recall drops as speed rises. This section only adds
the index to the table and checks that the planner uses it.

```
ana@vm:~/rag$ psql -c "CREATE INDEX ON chunks USING hnsw (embedding vector_cosine_ops)"
CREATE INDEX
ana@vm:~/rag$ psql -c "SET enable_seqscan = off" -c "EXPLAIN (COSTS OFF) SELECT path FROM chunks ORDER BY embedding <=> (SELECT embedding FROM chunks LIMIT 1) LIMIT 3"
SET
                      QUERY PLAN                       
-------------------------------------------------------
 Limit
   InitPlan 1 (returns $0)
     ->  Limit
           ->  Seq Scan on chunks chunks_1
   ->  Index Scan using chunks_embedding_idx on chunks
         Order By: (embedding <=> $0)
(6 rows)
```

**`vector_cosine_ops` matches the operator the search uses**, `<=>`, cosine distance; an index built
for one operator is ignored by a query ordering by another, without an error. The plan shows `Index
Scan using chunks_embedding_idx`, ordered by the cosine distance. The `SET enable_seqscan = off`
is there because with 130 rows the planner, rightly, prefers to read the table directly; it is a way
to see that the index *can* be used, not a setting to leave on.

## Three facts about the index that matter to retrieval

**It is approximate.** HNSW can miss a true nearest neighbour. On a corpus this size there is little for it to
miss, and on a large one the miss rate is what `ef_search` controls. A retrieval test that
passes against an exact search can fail against the index, which is why lesson 8 runs its tests
against the same index production uses.

**It interacts with filters.** A `WHERE status = 'current'` combined with an HNSW index can return
fewer rows than the `LIMIT` asked for, because the index finds the nearest rows first and the filter
throws some away afterwards. `embeddings-vectors` lesson 17 showed PostgreSQL doing exactly that, and
lesson 14 of this course meets it again when the filters arrive.

**It is rebuilt incrementally.** Rows inserted after the index exists are added to it as they arrive;
the nightly run of `ingest.py` does not have to rebuild anything. Deleted rows leave marks in the graph
that `VACUUM` cleans up, which on a table with heavy churn is worth scheduling.
