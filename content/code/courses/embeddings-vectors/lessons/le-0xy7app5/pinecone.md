---
title: Pinecone, run for you
version: 1
---

Pinecone is a vector database you use as a service. You create an account and an API key, and
Pinecone runs the indexes; there is no directory of yours that holds them and no process of yours to
start. **That is the whole difference from Chroma, and most of what follows comes from it.**

It also means nothing in this section ran. The lab has no route to Pinecone's API, and an account
would be needed anyway. The program below is written for the `pinecone` Python package and was
checked against the signatures of version 10.0.0, in an environment of its own. Its requests were
never answered, so no output is shown and none is invented.

```python
import json
import os
from pinecone import Pinecone, ServerlessSpec
from minilm import embed

pc = Pinecone(api_key=os.environ["PINECONE_API_KEY"])
pc.create_index(name="help", dimension=384, metric="cosine",
                spec=ServerlessSpec(cloud="aws", region="us-east-1"))
index = pc.Index("help")

help = [json.loads(line) for line in open("data/help.jsonl")]
vectors = embed([h["title"] + ". " + h["body"] for h in help])
for lang in ("en", "pt"):
    index.upsert(namespace=lang, vectors=[
        {"id": h["id"], "values": v.tolist(),
         "metadata": {"category": h["category"], "title": h["title"]}}
        for h, v in zip(help, vectors) if h["lang"] == lang])

q = embed("how do I get my money back")[0]
res = index.query(vector=q.tolist(), top_k=3, namespace="en",
                  filter={"category": {"$in": ["returns", "payments"]}},
                  include_metadata=True)
for m in res.matches:
    print(f"{m.score:.4f}  {m.id}  {m.metadata['title']}")
```

## What the program asks for

**An index is created with its dimension and its metric**, and both are fixed from then on, as
Chroma's space was. 384 and `cosine` match all-MiniLM-L6-v2. `ServerlessSpec` says where the index
lives, a cloud and a region; you choose the region because the data sits there and every query
travels to it. Version 10.0.0 of the client still accepts this call and marks `dimension`, `metric`
and `spec` as deprecated in favour of a `schema=` and a `deployment=` argument. Check the current
form before you copy it.

**Pinecone stores vectors, not texts.** The program embeds the articles itself and sends the
numbers, which is the usual arrangement: there is no `documents=` and no default embedding function.
Pinecone also offers indexes with an embedding model attached (`create_index_for_model` in the
client), which embed text on Pinecone's side, but then the model is one of theirs.

**A record is an id, its values and a metadata dictionary**, and the metadata is what a filter can
read. The title travels in the metadata so that a result can be printed without a second lookup.
The body does not, and the usual pattern keeps it where it already lives, in Marginalia's own
database, joined by the id.

**A namespace is a partition inside one index.** The English articles go into `en` and the three
Portuguese ones into `pt`, and a query names exactly one namespace, so it never sees the other.
That is a cheap and strict way to separate languages, or customers, which lesson 17 comes back to.

**A query sends a vector, `top_k` and a filter.** The filter language is MongoDB's style, with
operators such as `$eq`, `$in` and `$gte`. Chroma's `where` uses the same style, so the filter
in `pine.py` and the one in `ask.py` look alike.

## Scores point the other way

`m.score` is not a distance. For a `cosine` index Pinecone returns the similarity, so the best
match has the **highest** score, the opposite of Chroma. The client's own documentation says it
plainly: `cosine` and `dotproduct` rank higher scores first, `euclidean` ranks lower scores first.
Moving a threshold from one database to the other means converting it, and the previous section
showed how a cut-off goes wrong when nobody does.

## What you give up, and what you get

You do not run anything. There is no directory to back up, no process to restart, no index to
rebuild by hand; Pinecone scales the index and keeps it available. In exchange the data leaves your
machines, every query is a network round trip to the region you chose, and the bill depends on how
much you store and how much you read and write. The comparison at the end of this lesson puts that
next to the other two.
