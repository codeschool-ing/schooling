---
title: The table
version: 2
---

The vectors go into PostgreSQL with pgvector, in the `rag` database, the same engine
`embeddings-vectors` used in its lessons 14 to 18. A dedicated vector database would serve as well;
the reason for PostgreSQL here is that the chunks' metadata is relational data, and the filters of
lesson 14 are `WHERE` clauses.

```schooling-example
{
  "language": "python",
  "file": "ingest.py",
  "parts": [
    {
      "code": "SCHEMA = \"\"\"\nCREATE TABLE IF NOT EXISTS chunks (\n    id          text PRIMARY KEY,\n    doc_id      text NOT NULL,\n    doc_version text NOT NULL,\n    status      text NOT NULL,\n    audience    text NOT NULL,\n    owner       text NOT NULL,\n    updated     date NOT NULL,\n    path        text NOT NULL,\n    position    int  NOT NULL,\n    text        text NOT NULL,\n    tokens      int  NOT NULL,\n    model       text NOT NULL,\n    embedding   vector(384) NOT NULL\n);\nCREATE INDEX IF NOT EXISTS chunks_doc ON chunks (doc_id);\n\"\"\"",
      "note": "One row per chunk. Beside the vector: where the chunk came from (`doc_id`, `path`, `position`), what state its document is in (`doc_version`, `status`, `updated`), who may read it (`audience`), who keeps it true (`owner`), and how it was made (`tokens`, `model`)."
    },
    {
      "code": "def chunks_of(doc_id, meta, body):\n    \"\"\"Every chunk of one document, with the metadata the search will filter on.\"\"\"\n    for position, (path, text) in enumerate(structured(body, SIZE)):\n        digest = hashlib.sha256(f\"{path}\\n{text}\".encode()).hexdigest()[:12]\n        yield {\"id\": f\"{doc_id}:{digest}\", \"doc_id\": doc_id, \"doc_version\": meta[\"version\"],\n               \"status\": meta[\"status\"], \"audience\": meta[\"audience\"], \"owner\": meta[\"owner\"],\n               \"updated\": meta[\"updated\"], \"path\": path, \"position\": position, \"text\": text,\n               \"tokens\": len(enc.encode(text)), \"model\": MODEL}",
      "note": "The id is the document's id and a hash of the chunk's path and text. Two runs over unchanged text produce the same id, and one changed word produces a different one."
    }
  ]
}
```

## Every column has a reader

```
ana@vm:~/rag$ psql -c "\d chunks"
                   Table "public.chunks"
   Column    |    Type     | Collation | Nullable | Default 
-------------+-------------+-----------+----------+---------
 id          | text        |           | not null | 
 doc_id      | text        |           | not null | 
 doc_version | text        |           | not null | 
 status      | text        |           | not null | 
 audience    | text        |           | not null | 
 owner       | text        |           | not null | 
 updated     | date        |           | not null | 
 path        | text        |           | not null | 
 position    | integer     |           | not null | 
 text        | text        |           | not null | 
 tokens      | integer     |           | not null | 
 model       | text        |           | not null | 
 embedding   | vector(384) |           | not null | 
Indexes:
    "chunks_pkey" PRIMARY KEY, btree (id)
    "chunks_doc" btree (doc_id)
```

A column nobody reads is a column nobody keeps correct, so each of these has a job later in the course:

| column | read by |
| --- | --- |
| `id` | the next section: deciding what to embed again |
| `doc_id`, `position` | citations, and reassembling a document's chunks in order |
| `path` | the source header in the prompt, lesson 7, and small-to-big retrieval |
| `status`, `updated`, `doc_version` | the filters on what is current, lesson 14 |
| `audience`, `owner` | the filters on who may read, lesson 14, and who to tell when a chunk is wrong |
| `tokens` | the context budget, lesson 12, and cost per query, lesson 17 |
| `model` | the check that every vector came from the same model |

Lesson 2 argued that the cheapest moment to store a document's audience, owner, version and status
is the first time it is cut into chunks. This table is that moment: all four are copied from each
document's front matter by `chunks_of`, so a document that declares them can never reach the index
without them.

## What is in it

```
ana@vm:~/rag$ psql -c "SELECT doc_id, count(*) AS chunks, sum(tokens) AS tokens FROM chunks GROUP BY doc_id ORDER BY doc_id"
         doc_id          | chunks | tokens 
-------------------------+--------+--------
 affiliate-api           |     10 |    706
 ebooks-and-audiobooks   |     10 |    543
 finance-refund-controls |      8 |    368
 gift-cards              |      5 |    268
 payments-and-invoices   |     10 |    536
 privacy-notice          |      9 |    512
 returns-policy          |     17 |    918
 returns-policy-2025     |      7 |    304
 seller-agreement        |     11 |    582
 shipping-and-delivery   |     14 |    722
 support-handbook        |     15 |    770
 terms-of-sale           |     14 |    674
 warehouse-runbook       |      7 |    417
(13 rows)

ana@vm:~/rag$ psql -c "SELECT id, path, status, audience FROM chunks WHERE doc_id = 'returns-policy' ORDER BY position LIMIT 4"
             id              |                        path                        | status  | audience 
-----------------------------+----------------------------------------------------+---------+----------
 returns-policy:fbe325d9ffef | Returns and refunds policy > The return window     | current | public
 returns-policy:cbd2372c3344 | Returns and refunds policy > The return window     | current | public
 returns-policy:0652374b6c43 | Returns and refunds policy > The return window     | current | public
 returns-policy:c459a83c0029 | Returns and refunds policy > How to start a return | current | public
(4 rows)
```

The returns policy became 17 chunks, three of them in *The return window*. Their token counts add up
to 918 against 1,113 for the whole file in lesson 1: the difference is the front matter, the title and
the headings, which are in `path` rather than in `text`. The ids are the document's id followed by
twelve hexadecimal characters, and the next section is about where those come from.
