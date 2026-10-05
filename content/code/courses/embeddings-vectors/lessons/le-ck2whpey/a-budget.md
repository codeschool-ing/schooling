---
title: A budget
version: 1
---

Everything in this lesson so far fits in one program. The example is a corpus bigger than
Marginalia's: **two million chunks of 300 tokens**, embedded with text-embedding-3-small at its
1536 dimensions and kept in PostgreSQL with an HNSW index. The prices come from the sheet saved in
section 05 of this lesson and the bytes per row from the 1536-dimension table measured in section
02, read back from the database rather than typed in.

```schooling-example
{
  "language": "python",
  "file": "budget.py",
  "parts": [
    {
      "code": "import json\nimport psycopg\n\nprices = {p[\"model\"]: p for p in json.load(open(\"prices.json\"))}\nsmall, large = prices[\"text-embedding-3-small\"], prices[\"text-embedding-3-large\"]\nCHUNKS, PER = 2_000_000, 300\ntokens = CHUNKS * PER\nGB = 1e9",
      "note": "The two models from the sheet and the size of the example: two million chunks of 300 tokens."
    },
    {
      "code": "with psycopg.connect() as conn:\n    row, hnsw = conn.execute(\"\"\"SELECT pg_table_size('v1536') / 20000.0,\n                                       pg_relation_size('v1536_hnsw') / 20000.0\"\"\").fetchone()\nprint(f\"measured at 1536 dims: {row:.0f} B a row, {hnsw:.0f} B a row of HNSW\")",
      "note": "What a row really costs in Postgres at 1536 dimensions, read from the table and the HNSW index measured earlier in this lesson, not assumed."
    },
    {
      "code": "print(f\"{CHUNKS:,} chunks x {PER} tokens = {tokens:,} tokens\")\nprint(f\"embed once, {small['model']}:  ${tokens / 1e6 * small['usd_per_mtok']:.2f}\"\n      f\"  (batch ${tokens / 1e6 * small['batch_usd_per_mtok']:.2f})\")\nprint(f\"raw float32 vectors:     {CHUNKS * small['dims'] * 4 / GB:6.2f} GB\")\nprint(f\"table in Postgres:       {CHUNKS * float(row) / GB:6.2f} GB\")\nprint(f\"HNSW index in Postgres:  {CHUNKS * float(hnsw) / GB:6.2f} GB\")",
      "note": "Embedding once, at the standard price and the batch price, and the space the vectors take as raw numbers, as a table and as an HNSW index."
    },
    {
      "code": "churn = 0.05\nprint(f\"re-embed {churn:.0%} a month:     ${tokens * churn / 1e6 * small['usd_per_mtok']:.2f}\")\nprint(f\"move to {large['model']}: ${tokens / 1e6 * large['usd_per_mtok']:.2f}\"\n      f\"  raw vectors {CHUNKS * large['dims'] * 4 / GB:.2f} GB,\"\n      f\" {CHUNKS * (small['dims'] + large['dims']) * 4 / GB:.2f} GB while both exist\")",
      "note": "Two things that come back: re-embedding the share of chunks that change each month, and moving the whole corpus to the larger model."
    }
  ]
}
```

```
ana@lab:~/emb$ python budget.py
measured at 1536 dims: 8348 B a row, 8192 B a row of HNSW
2,000,000 chunks x 300 tokens = 600,000,000 tokens
embed once, text-embedding-3-small:  $12.00  (batch $6.00)
raw float32 vectors:      12.29 GB
table in Postgres:        16.70 GB
HNSW index in Postgres:   16.38 GB
re-embed 5% a month:     $0.60
move to text-embedding-3-large: $78.00  raw vectors 24.58 GB, 36.86 GB while both exist
```

## Reading the bill

**Embedding the whole corpus once costs $12.00**, or $6.00 through the Batch API at the sheet's
batch price, which lesson 7 described and nothing here ran. That is the line people worry about,
and it is the cheapest line on the page.

**The vectors are 12.29 GB as raw numbers and over twice that in Postgres**: 16.70 GB of
table and 16.38 GB of HNSW index, from the 8348 and 8192 bytes a row measured at 1536 dimensions.
That is disk you pay for every month, and the index is the part that has to fit in memory,
because a search hops from page to page through the graph and every page not in memory is a read
from disk. What a GB of memory or disk costs depends on where you run, and no sheet in this course
prices it; multiply these sizes by your own host's prices.

**Keeping up is cheap.** If 5% of the chunks change in a month, re-embedding them costs $0.60. The
share is the program's assumption, not a measurement; put in your own.

**Changing the model is where the money is.** Moving to text-embedding-3-large costs $78.00 in
tokens, its raw vectors are 24.58 GB, and while the old and new vectors both exist they are 36.86
GB before either table or index overhead. There is a second catch at that dimension: the lab's
pgvector cannot build an HNSW index on 3072 dimensions at all, as section 03 showed, so the move
also means shortening the vectors or upgrading the extension.

## What changes the bill

Three levers, each measured earlier in this lesson:

| lever | where it was measured | what it moves |
|---|---|---|
| a smaller dimension | `shrink.py`, WordLlama cut to 128 and 64 | every byte line, at a cost in neighbours |
| fewer bytes per number | `shrink.py`, float16 and int8 | every byte line, nearly free down to int8 |
| one copy of the vectors | `graphs.py`, hnswlib against pgvector | the index line |

The token line, the one with a dollar sign printed beside it, barely moves with any of them. **A
vector store is mostly a storage bill**, and the size of every row is fixed the day the model is
chosen. Choose the dimension with that in mind, as lesson 10's decision table asks, and measure
`per_row` on your own database before you multiply.
