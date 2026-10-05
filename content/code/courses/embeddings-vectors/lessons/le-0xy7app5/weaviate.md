---
title: Weaviate, a server with modules
version: 1
---

Weaviate sits between the other two. It is open source, so you can run it yourself, in a container
for instance. It is also sold as a hosted service, Weaviate Cloud. And the Python client has an
**embedded** mode that downloads a Weaviate server and starts it as a child of your program. In
every one of those shapes **your program is a client of a Weaviate server**, never the database
itself, which is the difference from Chroma's `PersistentClient`.

None of the three ran here. The embedded mode fetches the server from GitHub, which this lab cannot
reach, and there was no server to connect to otherwise. The program below is written for the
`weaviate-client` package and checked against the signatures of version 4.23.1 in an environment of
its own; it was never answered, and no output is shown.

```python
import json
import weaviate
from weaviate.classes.config import Configure, DataType, Property, VectorDistances
from weaviate.classes.data import DataObject
from weaviate.classes.query import Filter, MetadataQuery
from weaviate.util import generate_uuid5
from minilm import embed

client = weaviate.connect_to_local()
articles = client.collections.create(
    "Article",
    properties=[Property(name="article_id", data_type=DataType.TEXT),
                Property(name="category", data_type=DataType.TEXT),
                Property(name="title", data_type=DataType.TEXT),
                Property(name="body", data_type=DataType.TEXT)],
    vector_config=Configure.Vectors.self_provided(
        vector_index_config=Configure.VectorIndex.hnsw(
            distance_metric=VectorDistances.COSINE)),
)

help = [json.loads(line) for line in open("data/help.jsonl")]
vectors = embed([h["title"] + ". " + h["body"] for h in help])
articles.data.insert_many([
    DataObject(uuid=generate_uuid5(h["id"]), vector=v.tolist(),
               properties={"article_id": h["id"], "category": h["category"],
                           "title": h["title"], "body": h["body"]})
    for h, v in zip(help, vectors)])

q = embed("how do I get my money back")[0].tolist()
res = articles.query.near_vector(
    near_vector=q, limit=3,
    filters=Filter.by_property("category").equal("returns"),
    return_metadata=MetadataQuery(distance=True))
for o in res.objects:
    print(f"{o.metadata.distance:.4f}  {o.properties['article_id']}  {o.properties['title']}")

res = articles.query.hybrid(query="refund", vector=q, alpha=0.5, limit=3)
client.close()
```

## A collection has a schema

**Weaviate's collection declares its properties with types**, where Chroma's metadata was whatever
dictionary you passed. `article_id` holds Marginalia's id because Weaviate's own identifier is a
UUID: `generate_uuid5("h15")` derives one from the article id, so h15 gets the same UUID on every
import instead of a new random one.

The vector side of the collection is configured in `vector_config`, and this is where Weaviate's
design shows. **`self_provided` means you bring the vectors**, as `weav.py` does with
all-MiniLM-L6-v2 and the HNSW index measuring cosine distance. The alternative is a **vectorizer
module**: `Configure.Vectors.text2vec_openai(model="text-embedding-3-small")` makes Weaviate call
OpenAI itself when objects are inserted and when a query arrives as text, through
`query.near_text(...)`. That is Chroma's embedding function moved to the server, with the provider's
key held by the server and the provider's bill arriving for every insert.

## Distance, again

`MetadataQuery(distance=True)` asks for the distance of each result, and for a cosine index Weaviate
uses the same convention as Chroma: one minus the similarity, smaller is closer. So h15, which Chroma
put at 0.5624 from the question, would come back at that distance here too, if the vectors are the
same; that follows from the definition and was not measured.

Filters are built with a small builder, `Filter.by_property("category").equal("returns")`, rather
than a dictionary, and several combine with `&` and `|`.

## Hybrid search in one call

**`query.hybrid` runs a keyword search and a vector search and fuses the two lists**, which is
lesson 3's hybrid search done by the database. Weaviate keeps a keyword index of the text
properties, so `query="refund"` is scored with BM25 while `vector=q` is scored by distance.

`alpha` sets the balance: 1 is a pure vector search, 0 a pure keyword search, and 0.5 weighs them
equally. `fusion_type` chooses how the two lists are merged, either by rank, as lesson 3's reciprocal
rank fusion did, or by normalised score. The right `alpha` for Marginalia is a measurement, made the
way lesson 3 made it, with the 24 questions in `queries.jsonl`, not a value to copy.
