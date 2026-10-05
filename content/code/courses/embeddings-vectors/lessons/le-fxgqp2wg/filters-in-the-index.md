---
title: Filters in the index
version: 1
---

Neither order is good everywhere, so the vector databases have done what pgvector 0.6.0 does not:
they take the filter **with** the query and decide inside the engine how to apply it. The
interface looks the same in each, a vector, a k and a condition, and what differs is what happens
to the condition. The three that ran in lessons 12 and 13 all ran here, on the help centre, with
the same question and the filter `lang = 'pt'`.

## Chroma

```schooling-example
{
  "language": "python",
  "file": "chroma_filter.py",
  "parts": [
    {
      "code": "import chromadb\nfrom minilm import embed\nfrom store import help, ids, D\n\nclient = chromadb.PersistentClient(path=\"chroma\")\ncol = client.create_collection(\"help\", configuration={\"hnsw\": {\"space\": \"cosine\"}})\ncol.add(ids=ids, embeddings=D,\n        metadatas=[{\"lang\": h[\"lang\"], \"category\": h[\"category\"]} for h in help])",
      "note": "The 40 articles go in with their vectors and two metadata fields each."
    },
    {
      "code": "q = embed(\"how do I return a book\")\nr = col.query(query_embeddings=q, n_results=3, where={\"lang\": \"pt\"})\nprint(r[\"ids\"][0])\nr = col.query(query_embeddings=q, n_results=3,\n              where={\"$and\": [{\"lang\": \"en\"}, {\"category\": \"returns\"}]})\nprint(r[\"ids\"][0])",
      "note": "`where` takes a dictionary: a field and a value, or `$and` and `$or` around several."
    }
  ],
  "output": "ana@lab:~/emb$ python chroma_filter.py\n['h40', 'h39', 'h38']\n['h14', 'h17', 'h16']"
}
```

**Chroma returned three Portuguese articles**, the same three the pre-filter found in
`filtered.py`, in the same order. The `where` condition decided which records could be returned
before the three were picked, so the shortfall from the post-filtering section does not happen. The
second query combines two fields with `$and`. Chroma also has `where_document`, which filters on the
stored text itself, for instance on whether it contains a word.

## LanceDB

LanceDB lets you choose, which makes it the clearest place to see the difference between the two
orders on one table:

```schooling-example
{
  "language": "python",
  "file": "lance_filter.py",
  "parts": [
    {
      "code": "import lancedb\nfrom minilm import embed\nfrom store import help, D\n\ndb = lancedb.connect(\"lance\")\ntable = db.create_table(\"help\", [{\"id\": h[\"id\"], \"lang\": h[\"lang\"], \"vector\": v}\n                                 for h, v in zip(help, D)])\nq = embed(\"how do I return a book\")[0]",
      "note": "A table with a `vector` column and a `lang` column, one row per article."
    },
    {
      "code": "for prefilter in (True, False):\n    rows = (table.search(q).metric(\"cosine\")\n            .where(\"lang = 'pt'\", prefilter=prefilter).limit(3).to_list())\n    print(f\"prefilter={prefilter}:\", [r[\"id\"] for r in rows])",
      "note": "The same filter twice. `prefilter` says whether it is applied before the search or after it."
    }
  ],
  "output": "ana@lab:~/emb$ python lance_filter.py\nprefilter=True: ['h40', 'h39', 'h38']\nprefilter=False: []"
}
```

**`prefilter=True`, the default, returned the three Portuguese articles; `prefilter=False` returned
none**, the same empty list `post_filter` gave for the same question. With no vector index on a
40-row table, LanceDB searched exactly either way, so the only difference between the two lines is
the order. On a large table with an ANN index the trade from the pre-filtering section applies, and
the parameter is how you choose a side of it per query.

## Qdrant

This is Qdrant's Python client in **local mode**, the in-process implementation lesson 13 used,
because the Qdrant server was out of reach from the lab:

```schooling-example
{
  "language": "python",
  "file": "qdrant_filter.py",
  "parts": [
    {
      "code": "from qdrant_client import QdrantClient, models\nfrom minilm import embed\nfrom store import help, D\n\nclient = QdrantClient(path=\"qdrant\")\nclient.create_collection(\"help\", vectors_config=models.VectorParams(\n    size=384, distance=models.Distance.COSINE))\nclient.upsert(\"help\", points=[\n    models.PointStruct(id=i, vector=v.tolist(), payload={\"article\": h[\"id\"], \"lang\": h[\"lang\"]})\n    for i, (h, v) in enumerate(zip(help, D))])",
      "note": "Qdrant in local mode: the collection lives in a directory and the search runs inside this Python process. Each point carries a payload, Qdrant's word for metadata."
    },
    {
      "code": "client.create_payload_index(\"help\", \"lang\", models.PayloadSchemaType.KEYWORD)",
      "note": "A payload index is what the Qdrant server uses to filter inside its HNSW graph."
    },
    {
      "code": "only_pt = models.Filter(must=[models.FieldCondition(key=\"lang\", match=models.MatchValue(value=\"pt\"))])\nhits = client.query_points(\"help\", query=embed(\"how do I return a book\")[0].tolist(),\n                           query_filter=only_pt, limit=3)\nprint([p.payload[\"article\"] for p in hits.points])",
      "note": "A filter is a `Filter` of conditions; `must` means every condition has to hold."
    }
  ],
  "output": "ana@lab:~/emb$ python qdrant_filter.py\n/home/ana/emb/qdrant_filter.py:11: UserWarning: Payload indexes have no effect in the local Qdrant. Please use server Qdrant if you need payload indexes.\n  client.create_payload_index(\"help\", \"lang\", models.PayloadSchemaType.KEYWORD)\n['h40', 'h39', 'h38']"
}
```

**The filtered query returned the three Portuguese articles.** The warning comes from how local
mode works: it scores every point and applies the filter as a mask, which is exact and needs no
index, so it ignores the payload index and says so.

The **server** is where the payload index matters, and it was not run here. Qdrant documents its
approach as **filterable HNSW**. With a payload index on a field, the server estimates how many
points a filter passes, and when it passes few, it searches them exactly, which is a pre-filter.
Otherwise it walks the HNSW graph and checks the condition during the walk, so rejected points do
not use up the result list the way they did in pgvector. It also adds links to the graph for
indexed values, so that the part of the graph a filter leaves is still connected. That design
removes the trade from the previous two sections, at the cost of creating the payload indexes
before loading the data.

## What to look for in a database

Three questions sort the engines you will meet, and each one has an answer in its documentation:

- Does the filter run before, after or during the search? After is the one that shrinks k,
  silently.
- Does a filtered query still return k results when k rows pass? If it does not, find the
  setting that makes it, such as `hnsw.ef_search` in pgvector 0.6.0 or iterative scans in 0.8.0.
- Does the field need an index of its own? Qdrant's server wants a payload index; PostgreSQL
  uses a B-tree on the column, or a partial index for a value you filter on often.

Then measure it on your own data, as `ten.sql` did: count what a filtered query returns, for
filters of different widths, before trusting a page of results to it.
