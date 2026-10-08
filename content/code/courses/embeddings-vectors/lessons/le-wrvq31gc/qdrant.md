---
title: Qdrant, in local mode
version: 1
---

Qdrant is a vector database server, open source and written in Rust, that you run yourself or rent
as Qdrant Cloud. Its Python client also has a **local mode**: give it a `path` instead of a URL and
it runs a Python implementation of the same API inside your process, storing the data in a
directory. **Local mode is what ran here.** The Qdrant server is a separate program the machine this
course was recorded on could not fetch, so everything below is the client on its own, and this section says where that differs
from the real thing.

```schooling-example
{
  "language": "python",
  "file": "qd.py",
  "parts": [
    {
      "code": "import json\nfrom qdrant_client import QdrantClient\nfrom qdrant_client.models import (Distance, FieldCondition, Filter, MatchValue,\n                                  PointStruct, VectorParams)\nfrom minilm import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nX = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])",
      "note": "The articles and their vectors, as before."
    },
    {
      "code": "client = QdrantClient(path=\"qdrant\")\nclient.create_collection(\"help\", vectors_config=VectorParams(size=384, distance=Distance.COSINE))",
      "note": "`path=` is local mode: no server, a directory. The collection is created with its size and its distance."
    },
    {
      "code": "client.upsert(\"help\", points=[\n    PointStruct(id=int(h[\"id\"][1:]), vector=v.tolist(),\n                payload={\"article\": h[\"id\"], \"category\": h[\"category\"], \"title\": h[\"title\"]})\n    for h, v in zip(help, X)])\nprint(client.count(\"help\").count, \"points\")",
      "note": "A point is an id, a vector and a payload. The id has to be an integer or a UUID, so h15 becomes 15 again; the article id travels in the payload."
    },
    {
      "code": "q = embed(\"how do I get my money back\")[0].tolist()\nfor p in client.query_points(\"help\", query=q, limit=3).points:\n    print(f\"{p.score:.4f}  {p.id}  {p.payload['title']}\")",
      "note": "The nearest three, each with its score."
    },
    {
      "code": "ebooks = Filter(must=[FieldCondition(key=\"category\", match=MatchValue(value=\"ebooks\"))])\nfor p in client.query_points(\"help\", query=q, query_filter=ebooks, limit=3).points:\n    print(f\"{p.score:.4f}  {p.id}  {p.payload['title']}\")",
      "note": "A filter that keeps only the e-book articles."
    }
  ],
  "output": "ana@lab:~/emb$ python qd.py\n40 points\n0.4456  18  Returning a gift\n0.4376  15  When your refund arrives\n0.3994  22  Charged twice for one order\n0.3905  33  Refunds for e-books\n0.1633  35  Lending and sharing e-books\n0.1624  37  Audiobooks"
}
```

## A score, again

Qdrant's `score` for a cosine collection is the similarity, 0.4456 for the gift article, highest
first. That makes three conventions for the same comparison in two lessons: Chroma's distance, one
minus the similarity; LanceDB's default squared L2; and Qdrant's similarity. The articles came back
in the same order from all of them.

**A point is an id, a vector and a payload.** The payload is Qdrant's word for metadata, any JSON
object, and the filter reads it: `must` is a list of conditions that all have to hold, and
`MatchValue` asks for an exact value. Qdrant also has `should`, where at least one condition has to
hold, and `must_not`.

## Where local mode shows

Three more calls, and only the first behaves as a server would:

```schooling-example
{
  "language": "python",
  "file": "qd_local.py",
  "parts": [
    {
      "code": "import warnings\nfrom qdrant_client import QdrantClient\nfrom qdrant_client.models import PayloadSchemaType, PointStruct\n\nclient = QdrantClient(path=\"qdrant\")",
      "note": "Open the same directory."
    },
    {
      "code": "try:\n    client.upsert(\"help\", points=[PointStruct(id=\"h15\", vector=[0.0] * 384)])\nexcept Exception as e:\n    print(type(e).__name__ + \":\", e)",
      "note": "A point whose id is a string."
    },
    {
      "code": "try:\n    client.query_points(\"help\", query=[0.1] * 256, limit=3)\nexcept Exception as e:\n    print(type(e).__name__ + \":\", e)",
      "note": "A query with a 256-number vector in a collection of 384."
    },
    {
      "code": "with warnings.catch_warnings(record=True) as said:\n    warnings.simplefilter(\"always\")\n    client.create_payload_index(\"help\", field_name=\"category\",\n                                field_schema=PayloadSchemaType.KEYWORD)\nprint(\"warning:\", said[0].message)\nprint(\"indexed vectors:\", client.get_collection(\"help\").indexed_vectors_count)",
      "note": "Ask for an index on the payload field `category`, keeping the warning Python raises so that it prints in order, then ask how many vectors are indexed."
    }
  ],
  "output": "ana@lab:~/emb$ python qd_local.py\nValueError: Point id h15 is not a valid UUID\nValueError: shapes (40,384) and (256,) not aligned: 384 (dim 1) != 256 (dim 0)\nwarning: Payload indexes have no effect in the local Qdrant. Please use server Qdrant if you need payload indexes.\nindexed vectors: 0"
}
```

**An id is an unsigned integer or a UUID**, and Qdrant enforces it: h15 is refused, which is why
`qd.py` stored 15 and kept "h15" in the payload. That rule is Qdrant's, server and local alike.

The 256-number query failed with NumPy's own message about shapes that do not align. **That
message is the implementation showing through**: local mode keeps the vectors in a NumPy array and
multiplies the query against all of them, so its search is exact and its errors are NumPy's.
`indexed vectors: 0` says the same from the other side. A server builds an HNSW index once a
collection is large enough, and has its own error messages; neither was run here.

Local mode also accepts a payload index and ignores it, with a warning that says so. On a server,
that index lets Qdrant answer a filter from an index instead of checking every point. Lesson 17 shows why
that index matters once filters meet an HNSW graph. The directory holds a SQLite file and two small
files of bookkeeping:

```
ana@lab:~/emb$ find qdrant -type f | sort
qdrant/.lock
qdrant/collection/help/storage.sqlite
qdrant/meta.json
```

## Moving to the server

The same program runs against a server by changing one line, the documented one for a server
listening on its default port:

```python
client = QdrantClient(url="http://localhost:6333")
```

That line was not run, for the reason above. It also shows what local mode is for: writing and
testing on a laptop, knowing that only the server will show real speed, indexing and concurrency.
