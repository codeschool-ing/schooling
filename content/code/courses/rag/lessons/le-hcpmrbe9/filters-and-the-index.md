---
title: Filters and the vector index
version: 1
---

Every search in this course has been exact: PostgreSQL compares the question with every row that
passes the `WHERE` and returns the nearest. At Marginalia's 137 chunks that is instant. At a few
hundred thousand, a team adds the HNSW index that `embeddings-vectors` built, and the index changes
how a filter behaves. Lesson 5 warned about it and lesson 6 deferred it to here.

`index.py` runs one search restricted to the finance team's documents, 8 chunks of the 137, asking
for five, first as an exact scan and then with the planner told to use the index:

```
ana@lab:~/rag$ psql -qc "CREATE INDEX ON chunks USING hnsw (embedding vector_cosine_ops)"
ana@lab:~/rag$ python index.py "When does an order get held for manual fraud review?"
sequential scan on : 5 of 5
sequential scan off: 3 of 5
ana@lab:~/rag$ psql -qc "DROP INDEX chunks_embedding_idx"
```

**Five rows exactly, three through the index.** The index does not know about the filter. It walks
its graph to the nearest few dozen vectors, 40 by default in pgvector 0.6 (`hnsw.ef_search`), and
PostgreSQL then applies the `WHERE` to those; when only a few of them are finance chunks, only a few
come back, however many exist. Nothing reports the shortfall. The search returns fewer rows than the
`LIMIT` asked for, and the reader gets a thinner answer for a reason no log will show.

Permission filters make this worse than status filters, because they are strictest exactly where it
matters: the reader who may see one small audience is the one whose results the index starves. Three
remedies, in the order to reach for them:

- **Exact search on a small subset.** When the filter leaves a few thousand rows, an exact scan of
  them is fast, and the planner can be steered to it. The 8 finance chunks never needed an index.
- **A partial index per audience**: `CREATE INDEX … WHERE audience = 'finance'`, so the finance
  search walks a graph that contains only finance chunks.
- **A newer pgvector.** Version 0.8 added iterative index scans, which keep walking the graph until
  enough rows pass the filter. The lab pins 0.6.0, and the setting does not exist there.

Whichever is used, the check is lesson 8's, run with the index in place: recall measured on an
unindexed table says nothing about the indexed one.
