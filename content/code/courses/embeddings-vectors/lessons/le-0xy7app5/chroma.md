---
title: Chroma in a directory
version: 1
---

A vector database sounds like a server: a process somewhere, a port, a connection string. **Chroma
can be that, and it can also be a library that keeps a directory.** `pip install chromadb` gives you
a package that runs inside your own Python process and writes its files wherever you point it. The
lab pins version 1.5.9, and everything in this section and the next two ran on it.

Here are the 40 help-centre articles going in, with the same text lesson 3 embedded: the title and
the body joined.

```schooling-example
{
  "language": "python",
  "file": "load.py",
  "parts": [
    {
      "code": "import json\nimport chromadb\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]",
      "note": "Read the 40 help-centre articles, as every lesson since lesson 3 has."
    },
    {
      "code": "client = chromadb.PersistentClient(path=\"chroma\")\ncol = client.create_collection(\"help\", configuration={\"hnsw\": {\"space\": \"cosine\"}})",
      "note": "`PersistentClient` keeps the database in a directory, here `chroma` beside the program. The collection is created with the cosine space; leave the configuration out and Chroma uses L2, which the section on distances measures."
    },
    {
      "code": "col.add(\n    ids=[h[\"id\"] for h in help],\n    documents=[h[\"title\"] + \". \" + h[\"body\"] for h in help],\n    metadatas=[{\"category\": h[\"category\"], \"lang\": h[\"lang\"], \"updated\": h[\"updated\"]}\n               for h in help],\n)\nprint(col.count(), \"records in\", col.name)",
      "note": "Hand over ids, texts and metadata, and no vectors. With no `embeddings` argument, Chroma runs the collection's embedding function over the documents itself."
    }
  ],
  "output": "ana@lab:~/emb$ python load.py\n40 records in help"
}
```

**The program never computes a vector.** It hands Chroma ids, texts and metadata, and Chroma runs
its **embedding function** over the texts. The default one is all-MiniLM-L6-v2 as an ONNX file,
and that is not a coincidence: the copy `minilm.py` has run since lesson 1 is Chroma's own export,
fetched from Chroma's bucket. So the vectors Chroma stored should be the ones you would have made:

```python
import chromadb
from minilm import embed

col = chromadb.PersistentClient(path="chroma").get_collection("help")
got = col.get(ids=["h15"], include=["documents", "embeddings"])
stored = got["embeddings"][0]
mine = embed(got["documents"][0])[0]
print(stored.shape, abs(stored - mine).max())
```

```
ana@lab:~/emb$ python same.py
(384,) 3.725290298461914e-08
```

The largest difference across the 384 numbers is in the eighth decimal place, which is two
programs doing the same arithmetic in a slightly different order. Same model, same vectors.

That convenience is also a decision somebody made for you. The collection now depends on a model
chosen by Chroma's default, and lesson 1 said what that commits you to: every query has to be
embedded by the same model, and changing it means embedding every record again. Pass
`embedding_function=` when you create the collection, or pass `embeddings=` yourself, and the
choice is yours and visible in the code.

## Asking

A query can be text, because the collection knows its embedding function:

```schooling-example
{
  "language": "python",
  "file": "ask.py",
  "parts": [
    {
      "code": "import chromadb\n\ncol = chromadb.PersistentClient(path=\"chroma\").get_collection(\"help\")\nquestion = \"how do I get my money back\"",
      "note": "Open the collection again from the directory. Its embedding function was recorded with it, so the question can be given as text."
    },
    {
      "code": "r = col.query(query_texts=[question], n_results=3)\nfor i, d, doc in zip(r[\"ids\"][0], r[\"distances\"][0], r[\"documents\"][0]):\n    print(f\"{d:.4f}  {i}  {doc[:44]}\")",
      "note": "The three nearest articles, each with its distance and the start of its text."
    },
    {
      "code": "r = col.query(query_texts=[question], n_results=3,\n              where={\"category\": {\"$in\": [\"payments\", \"ebooks\"]}})\nprint(\"payments or e-books:\", r[\"ids\"][0])",
      "note": "`where` filters on metadata. `$in` keeps the records whose category is one of the list."
    },
    {
      "code": "r = col.query(query_texts=[question], n_results=3,\n              where_document={\"$contains\": \"card\"})\nprint(\"text says card:     \", r[\"ids\"][0])",
      "note": "`where_document` filters on the text itself: `$contains` keeps the records whose document contains the string."
    }
  ],
  "output": "ana@lab:~/emb$ python ask.py\n0.5544  h18  Returning a gift. The person who received th\n0.5624  h15  When your refund arrives. We refund within t\n0.6006  h22  Charged twice for one order. When a payment \npayments or e-books: ['h22', 'h33', 'h21']\ntext says card:      ['h18', 'h15', 'h02']"
}
```

The first block is lesson 1's question with lesson 1's answer: the gift article first, the refund
article second, close behind. **But the numbers are not lesson 1's scores.** Lesson 1 gave
*Returning a gift* 0.446, and here it has 0.5544, and the smaller number is the better one. Chroma
returns **distances**, and the section after next takes them apart.

The other two queries filter. `where` reads the metadata, and with the categories narrowed to
payments and e-books the refund articles are gone: *Refunds for e-books* (h33) rises to second.
`where_document` reads the text itself, and `$contains` is a plain substring test: every article
without the string is dropped before ranking, so all three that came back mention a card. Lesson 17
is about how a filter and the index work together, and where that goes wrong.

## One model per collection, checked by size

Ask the same collection with a WordLlama vector and Chroma refuses:

```python
import chromadb
from wordllama import WordLlama

col = chromadb.PersistentClient(path="chroma").get_collection("help")
v = WordLlama.load().embed(["how do I get my money back"], norm=True)
try:
    col.query(query_embeddings=v, n_results=3)
except Exception as e:
    print(type(e).__name__ + ":", e)
```

```
ana@lab:~/emb$ python dims.py
InvalidArgumentError: Collection expecting embedding with dimension of 384, got 256
```

The first `add` fixed the dimension at 384, and every later vector is checked against it. **That
check is about size, not about the model.** A different model that also gives 384 numbers would be
accepted without a word and would return nonsense, which is lesson 1's warning about vectors from
two models. The database cannot know where a vector came from. Store the model's name beside the
collection, in its metadata or in its name.

## Changing what is stored

`add`, `upsert`, `update` and `delete` are the four writes. They do not always behave the way their
names suggest. This program tries each one on a record for an article that does not exist, h41, so
the forty real ones are left alone:

```schooling-example
{
  "language": "python",
  "file": "change.py",
  "parts": [
    {
      "code": "import chromadb\n\ncol = chromadb.PersistentClient(path=\"chroma\").get_collection(\"help\")\nmeta = {\"category\": \"payments\", \"lang\": \"en\", \"updated\": \"2026-10-05\"}\nshow = lambda: print(col.count(), col.get(ids=[\"h41\"])[\"documents\"])",
      "note": "A record for an article that does not exist yet, h41, so the forty real ones stay as they were. `show` prints the count and h41's text."
    },
    {
      "code": "col.add(ids=[\"h41\"], documents=[\"Gift cards by email.\"], metadatas=[meta])\nshow()",
      "note": "`add` with a new id stores it."
    },
    {
      "code": "col.add(ids=[\"h41\"], documents=[\"Gift cards by post.\"], metadatas=[meta])\nshow()",
      "note": "`add` again with the same id and different text."
    },
    {
      "code": "col.upsert(ids=[\"h41\"], documents=[\"Gift cards by email or by post.\"], metadatas=[meta])\nshow()",
      "note": "`upsert` with the same id."
    },
    {
      "code": "col.update(ids=[\"h99\"], documents=[\"An article nobody wrote.\"])\ncol.delete(ids=[\"h41\"])\nshow()",
      "note": "`update` on an id nobody stored, then `delete` the new record."
    }
  ],
  "output": "ana@lab:~/emb$ python change.py\n41 ['Gift cards by email.']\n41 ['Gift cards by email.']\n41 ['Gift cards by email or by post.']\n40 []"
}
```

**The second `add` changed nothing and said nothing.** The id was already there, so Chroma kept the
first text and moved on. `upsert` is the write that replaces: insert if new, overwrite if not. And
`update` on h99, an id nobody ever stored, raised no error either. A program that re-imports the
help centre every night with `add` would keep the first version of every article forever, and
nothing in its output would show it. Use `upsert` for anything that can be written twice.

A changed document gets a new vector: Chroma runs the embedding function again on `upsert` and on
an `update` that carries text. The text and its vector cannot drift apart, which is the consistency
lesson 11 asked of any store.
