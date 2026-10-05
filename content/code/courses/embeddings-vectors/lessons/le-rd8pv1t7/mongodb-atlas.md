---
title: MongoDB Atlas
version: 1
---

Not every shop runs PostgreSQL. If Marginalia kept its catalogue in MongoDB, the same argument would
apply: put the vectors beside the documents they describe. **MongoDB Atlas**, MongoDB's hosted
service, does that with two pieces that pgvector folds into one. The vector is an ordinary field of
the document, an array of numbers. The index that searches it is a separate object, a **vector
search index**, defined beside the collection.

**Atlas was not run for this lesson.** It is a hosted service and this machine cannot reach it, and
the `pymongo` driver is not among the lab's libraries. Both programs below are written from MongoDB's
documented API and printed nothing here; no output is shown because none was produced.

## Documents with a vector field

```schooling-example
{
  "language": "python",
  "file": "atlas_setup.py",
  "parts": [
    {
      "code": "import json\nimport os\nfrom pymongo import MongoClient\nfrom pymongo.operations import SearchIndexModel\nfrom minilm import embed\n\narticles = MongoClient(os.environ[\"ATLAS_URI\"])[\"shop\"][\"articles\"]",
      "note": "`ATLAS_URI` would hold the cluster's connection string. A database and a collection are created the first time something is written to them."
    },
    {
      "code": "help = [json.loads(line) for line in open(\"data/help.jsonl\")]\nV = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])\narticles.insert_many([\n    {\"_id\": h[\"id\"], \"category\": h[\"category\"], \"title\": h[\"title\"],\n     \"body\": h[\"body\"], \"embedding\": v.tolist()}\n    for h, v in zip(help, V)])",
      "note": "Each article becomes one document, with its id as `_id` and its vector as a plain list of 384 numbers beside the title and the body. `tolist()` turns the NumPy array into numbers the driver can encode."
    },
    {
      "code": "articles.create_search_index(SearchIndexModel(\n    name=\"articles_vector\",\n    type=\"vectorSearch\",\n    definition={\"fields\": [\n        {\"type\": \"vector\", \"path\": \"embedding\",\n         \"numDimensions\": 384, \"similarity\": \"cosine\"},\n        {\"type\": \"filter\", \"path\": \"category\"},\n    ]},\n))",
      "note": "The vector search index is defined separately: the field that holds the vector, its dimension and the similarity, and a field queries will filter on. Atlas builds it in the background after this call returns."
    }
  ]
}
```

**The index definition carries the same two facts every vector store fixes at creation**, the ones
lesson 11 named: the dimension and the metric. `similarity` takes `euclidean`, `cosine` or
`dotProduct`, Atlas's names for the three operators of this lesson's second section. A field that a
query will filter on is declared in the index as well, with `type: "filter"`, because the filter is
applied inside the index search rather than after it; lesson 17 explains why that matters.

The document itself accepts any array. Nothing in a MongoDB collection insists that `embedding` has
384 numbers, the way `vector(384)` did, so the place that knows the dimension is the index, which
MongoDB's documentation says enforces `numDimensions` when it indexes and when it queries. The insert
itself is not refused, so a check at write time has to be your own.

## The search is a stage of a pipeline

MongoDB writes a query of several steps as an **aggregation pipeline**, a list of stages each of
which transforms the documents the previous one produced. The vector search is a stage called
`$vectorSearch`, and it has to be the first:

```schooling-example
{
  "language": "python",
  "file": "atlas_search.py",
  "parts": [
    {
      "code": "import os\nfrom pymongo import MongoClient\nfrom minilm import embed\n\narticles = MongoClient(os.environ[\"ATLAS_URI\"])[\"shop\"][\"articles\"]\nq = embed(\"how do I get my money back\")[0]",
      "note": "The same collection, and the question embedded by the same model as the stored articles, on the caller's side."
    },
    {
      "code": "pipeline = [\n    {\"$vectorSearch\": {\n        \"index\": \"articles_vector\",\n        \"path\": \"embedding\",\n        \"queryVector\": q.tolist(),\n        \"numCandidates\": 100,\n        \"limit\": 3,\n        \"filter\": {\"category\": \"returns\"},\n    }},",
      "note": "The first stage names the index and the field, sends the question's vector, gathers 100 candidates, keeps 3, and filters on `category`, which the index declared as a filter field."
    },
    {
      "code": "    {\"$project\": {\"_id\": 1, \"title\": 1,\n                  \"score\": {\"$meta\": \"vectorSearchScore\"}}},\n]",
      "note": "A later stage keeps the id and the title and adds the score, which the search stage leaves as metadata on each document."
    },
    {
      "code": "for doc in articles.aggregate(pipeline):\n    print(doc)",
      "note": "`aggregate` runs the pipeline on the server and returns the documents in order of score."
    }
  ]
}
```

Two of its fields have no counterpart in the SQL of this lesson. `numCandidates` is how many
neighbours the approximate search gathers before keeping the best `limit`; it plays the part that
`hnsw.ef_search` plays in pgvector, which lesson 16 met, and here it is written in every query
instead of set for the session. It cannot be smaller than `limit`. Setting `exact: true` instead runs
an exact search over every document, the equivalent of PostgreSQL's sequential scan.

The score needs care. **`vectorSearchScore` is not a cosine.** For `cosine` and `dotProduct`
indexes, MongoDB's documentation says the score is normalised as (1 + cosine) / 2, so it runs from 0
to 1 where pgvector's `1 - (a <=> b)` runs from −1 to 1. A threshold tuned on one cannot be copied to
the other; convert it, or tune it again on the scores the new system returns.

## Written now, found later

pgvector's index is part of the table: the `INSERT` that adds a row adds it to the index in the same
transaction, and the next query finds it. **Atlas keeps its search indexes up to date from the
collection in the background**, and MongoDB's documentation calls them eventually consistent. A
document written a moment ago may not be found by `$vectorSearch` yet, and a newly created index
cannot be queried until its first build has finished, and the driver's `list_search_indexes()`
reports when it can. A test that inserts and immediately searches has to wait for that.
