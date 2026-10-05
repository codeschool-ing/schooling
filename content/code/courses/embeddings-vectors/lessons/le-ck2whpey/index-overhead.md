---
title: What an index adds
version: 1
---

The usual picture of an index comes from ordinary databases: a B-tree on an id, a few bytes per
row pointing back at the table. A vector index is not that. To compare a query with a vector, the
index has to have the vector, and **most vector indexes keep their own copy of every one**. How
much that costs depends on the index and on where it lives.

## In pgvector, each index is another copy

Lesson 14 built these indexes to make a query fast. Here they are built to be weighed, on the two
tables from the last section:

```sql
SET maintenance_work_mem = '512MB';
\timing on
CREATE INDEX v384_hnsw  ON v384  USING hnsw (embedding vector_cosine_ops);
CREATE INDEX v1536_hnsw ON v1536 USING hnsw (embedding vector_cosine_ops);
CREATE INDEX v384_ivf   ON v384  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX v1536_ivf  ON v1536 USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
\timing off
SELECT i.indexrelid::regclass         AS "index",
       pg_relation_size(i.indexrelid) AS bytes,
       pg_relation_size(i.indexrelid) / c.reltuples::bigint AS per_row
  FROM pg_index i JOIN pg_class c ON c.oid = i.indrelid
 WHERE c.relname IN ('v384', 'v1536')
 ORDER BY 1;
```

```
ana@lab:~/emb$ psql -f index.sql
SET
Timing is on.
CREATE INDEX
Time: 7385.761 ms (00:07.386)
CREATE INDEX
Time: 46553.018 ms (00:46.553)
CREATE INDEX
Time: 790.394 ms
CREATE INDEX
Time: 2351.658 ms (00:02.352)
Timing is off.
   index    |   bytes   | per_row 
------------+-----------+---------
 v384_pkey  |    466944 |      23
 v1536_pkey |    466944 |      23
 v384_hnsw  |  40968192 |    2048
 v1536_hnsw | 163848192 |    8192
 v384_ivf   |  33284096 |    1664
 v1536_ivf  | 164667392 |    8233
(6 rows)
```

**The HNSW index on 384 dimensions is 2,048 bytes a row, more than the table's 1,676.** It holds the
vector and, beside it, the links to the vector's neighbours in the graph that lesson 15 describes.
At 1536 dimensions it is 8,192 bytes a row: one whole 8 KB page per vector. The IVFFlat indexes,
which store each vector once inside its cell, come to 1,664 and 8,233 bytes a row, about the size of
the table again.

So a table with both indexes holds every vector three times. You would rarely keep two vector
indexes on one column in production, but **one index already doubles the bill**, and the figure shows by how
much against the numbers themselves.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Four horizontal bars, each measured in multiples of the raw numbers of one vector, four bytes per dimension. In pgvector at 384 dimensions a vector costs a table row of 1676 bytes, an HNSW index entry of 2048 and an IVFFlat entry of 1664: three and a half times the raw size. At 1536 dimensions, 8371, 8192 and 8233 bytes, about four times. An hnswlib file costs 1684.6 bytes a vector at 384 dimensions and 6292.6 at 1536, close to the raw size.\"><rect x=\"190\" y=\"20\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"210\" y=\"27\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">table row</text><rect x=\"293.4\" y=\"20\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"313.4\" y=\"27\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">HNSW index</text><rect x=\"403.4\" y=\"20\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"423.4\" y=\"27\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">IVFFlat index</text><rect x=\"533.2\" y=\"20\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"553.2\" y=\"27\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">vector + links</text><path d=\"M190 260 L190 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"190\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0×</text><path d=\"M302 62 L302 72\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M302 104 L302 124\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M302 156 L302 176\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M302 208 L302 228\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M302 260 L302 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"302\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1×</text><path d=\"M414 62 L414 72\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M414 104 L414 124\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M414 156 L414 176\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M414 208 L414 228\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M414 260 L414 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"414\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2×</text><path d=\"M526 62 L526 72\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M526 104 L526 124\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M526 156 L526 176\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M526 208 L526 228\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M526 260 L526 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"526\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3×</text><path d=\"M638 62 L638 72\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M638 104 L638 124\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M638 156 L638 176\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M638 208 L638 228\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M638 260 L638 280\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"638\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4×</text><text x=\"638\" y=\"314\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">multiples of 4 × d bytes</text><text x=\"308\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the numbers alone</text><text x=\"178\" y=\"88\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">pgvector, 384 dims</text><rect x=\"190\" y=\"74\" width=\"122.2\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"251.1\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--ink)\">1676</text><rect x=\"312.2\" y=\"74\" width=\"149.3\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"386.9\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--ink)\">2048</text><rect x=\"461.5\" y=\"74\" width=\"121.3\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"522.2\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1664</text><text x=\"178\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">hnswlib file, 384 dims</text><rect x=\"190\" y=\"126\" width=\"122.8\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"251.4\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1684.6</text><text x=\"178\" y=\"192\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">pgvector, 1536 dims</text><rect x=\"190\" y=\"178\" width=\"152.6\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"266.3\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--ink)\">8371</text><rect x=\"342.6\" y=\"178\" width=\"149.3\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"417.3\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--ink)\">8192</text><rect x=\"491.9\" y=\"178\" width=\"150.1\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"567\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">8233</text><text x=\"178\" y=\"244\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">hnswlib file, 1536 dims</text><rect x=\"190\" y=\"230\" width=\"114.7\" height=\"28\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"247.4\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">6292.6</text></svg>", "caption": "Bytes per vector, drawn against the vector's own numbers. A file adds a tenth or less; pgvector stores the vector in the table and again in each index, so a table with both indexes holds it three times."}
```

## Outside the database, the graph is a tenth on top

hnswlib and FAISS keep an index as one file, and the numbers inside it are stored once:

```schooling-example
{
  "language": "python",
  "file": "graphs.py",
  "parts": [
    {
      "code": "import os\nimport time\nimport faiss\nimport hnswlib\nimport numpy as np\n\nN = 20_000\nfor d in (384, 1536):\n    X = np.load(f\"v{d}.npy\")\n    flat = os.path.getsize(f\"flat{d}.faiss\")",
      "note": "The flat index's size is the yardstick every other structure is divided by."
    },
    {
      "code": "    t = time.perf_counter()\n    h = hnswlib.Index(space=\"ip\", dim=d)\n    h.init_index(max_elements=N, M=16, ef_construction=64)\n    h.add_items(X, np.arange(N))\n    h.save_index(f\"hnsw{d}.bin\")\n    took = time.perf_counter() - t",
      "note": "An HNSW graph in hnswlib with the same two parameters pgvector uses by default, `M=16` and `ef_construction=64`, timed from creation to the saved file."
    },
    {
      "code": "    t = time.perf_counter()\n    ivf = faiss.index_factory(d, \"IVF100,Flat\", faiss.METRIC_INNER_PRODUCT)\n    ivf.train(X)\n    ivf.add(X)\n    faiss.write_index(ivf, f\"ivf{d}.faiss\")\n    took_ivf = time.perf_counter() - t",
      "note": "An IVF index from FAISS: 100 cells, found by k-means, with the vectors stored as they are in each cell. Training is part of the build, so it is inside the timer."
    },
    {
      "code": "    for f, s in ((f\"hnsw{d}.bin\", took), (f\"ivf{d}.faiss\", took_ivf)):\n        size = os.path.getsize(f)\n        print(f\"{f:>14}  {size:>11,}  {size / N:7.1f} per vector  \"\n              f\"{size / flat:5.2f}x flat  built in {s:5.2f} s\")",
      "note": "Size per vector, size against the flat file, and how long the build took."
    }
  ]
}
```

```
ana@lab:~/emb$ python graphs.py
   hnsw384.bin   33,691,896   1684.6 per vector   1.10x flat  built in  1.82 s
  ivf384.faiss   31,034,539   1551.7 per vector   1.01x flat  built in  0.90 s
  hnsw1536.bin  125,851,896   6292.6 per vector   1.02x flat  built in 11.13 s
 ivf1536.faiss  123,655,339   6182.8 per vector   1.01x flat  built in  3.26 s
```

**hnswlib's HNSW file is 1.10 times the flat file at 384 dimensions and 1.02 times at 1536.** The
links cost a roughly fixed number of bytes per vector, set by `M`, so the bigger the vector the
smaller their share. The FAISS IVF file is 1.01 times flat at both sizes: a list of 100 centroids
and an id per vector. The structure of an index is cheap; **what is expensive is a second copy of
the vectors**, and that is a choice of pgvector's design rather than a law of HNSW.

## Building it is the slow part

Read the `Time:` lines again. pgvector took `7385.761 ms` for the HNSW index on 384 dimensions and
`46553.018 ms` on 1536, against `790.394 ms` and `2351.658 ms` for IVFFlat. hnswlib, outside the
database, built its graphs in 1.82 s and 11.13 s. **HNSW is the expensive index to build**,
because every vector added is a search through the graph built so far.

The `SET` at the top of `index.sql` matters for that. pgvector builds the graph much faster when
it fits into `maintenance_work_mem`, whose default is 64 MB; the HNSW index on 1536 dimensions
alone came to 163,848,192 bytes. Raise it for the session that builds the index, not for the
whole server.

## A limit you meet at 3072 dimensions

text-embedding-3-large and gemini-embedding-001 return 3072 numbers by default. Try to index
them in the lab's pgvector:

```
ana@lab:~/emb$ psql -c "CREATE TABLE v3072 (embedding vector(3072))" -c "CREATE INDEX ON v3072 USING hnsw (embedding vector_cosine_ops)"
CREATE TABLE
ERROR:  column cannot have more than 2000 dimensions for hnsw index
```

**pgvector 0.6.0 refuses an HNSW index on more than 2,000 dimensions.** The table accepts the
column; the index does not. In this version you either shorten the vectors, with the `dimensions`
parameter lesson 7 used or by truncating them yourself, or you search every row without an index.
pgvector 0.7.0 added a `halfvec` type, two bytes a number, that can be indexed at up to 4,000
dimensions; it is not in the lab's 0.6.0 and nothing in this lesson ran it.
