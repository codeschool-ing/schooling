---
title: What the directory holds
version: 1
---

`PersistentClient(path="chroma")` made a directory, and the directory is the whole database. There
is no other copy and no process holding it: stop the program, copy the directory, and you have
copied the database. Two kinds of file are inside.

```
ana@lab:~/emb$ ls -l chroma chroma/*/
chroma:
total 376
drwxr-xr-x 2 ana ana   4096 Oct  5 14:10 48e47011-219b-443d-9093-a530d9043481
-rw-r--r-- 1 ana ana 380928 Oct  5 14:10 chroma.sqlite3

chroma/48e47011-219b-443d-9093-a530d9043481/:
total 172
-rw-r--r-- 1 ana ana 167600 Oct  5 14:10 data_level0.bin
-rw-r--r-- 1 ana ana    100 Oct  5 14:10 header.bin
-rw-r--r-- 1 ana ana    400 Oct  5 14:10 length.bin
-rw-r--r-- 1 ana ana      0 Oct  5 14:10 link_lists.bin
ana@lab:~/emb$ du -sh chroma
552K	chroma
```

**`chroma.sqlite3` is the record of everything; the directory named by a long identifier is the
index.** The identifier is the id of the collection's vector segment, and its four `.bin` files are
an HNSW index, the graph that lets a search avoid reading every vector. Lesson 15 builds that graph.
This section is about what sits where.

## An ordinary SQLite file

Nothing about the first file is private to Chroma. Python's own `sqlite3` module opens it:

```schooling-example
{
  "language": "python",
  "file": "inside.py",
  "parts": [
    {
      "code": "import sqlite3\n\ndb = sqlite3.connect(\"chroma/chroma.sqlite3\")\nfor table in (\"embeddings\", \"embedding_metadata\", \"embedding_fulltext_search\",\n              \"embeddings_queue\"):\n    print(f\"{table:26}\", db.execute(f\"SELECT count(*) FROM {table}\").fetchone()[0])",
      "note": "`chroma.sqlite3` is an ordinary SQLite file, so Python's own `sqlite3` module can read it. Count the rows of four of its tables."
    },
    {
      "code": "rows = db.execute(\"SELECT key, string_value FROM embedding_metadata m \"\n                  \"JOIN embeddings e ON e.id = m.id WHERE e.embedding_id = 'h15'\")\nfor key, value in rows:\n    print(f\"  {key:16} {value[:50]}\")",
      "note": "Every metadata key of h15, with the document among them."
    },
    {
      "code": "vector = db.execute(\"SELECT vector FROM embeddings_queue WHERE id = 'h15'\").fetchone()[0]\nprint(\"queued vector:\", len(vector), \"bytes\")",
      "note": "The write log keeps each vector as it arrived, as raw bytes."
    },
    {
      "code": "ops = {0: \"add\", 1: \"update\", 2: \"upsert\", 3: \"delete\"}\nrows = db.execute(\"SELECT seq_id, operation, id FROM embeddings_queue \"\n                  \"ORDER BY seq_id DESC LIMIT 5\")\nprint(\"last five writes:\", [(seq, ops[op], i) for seq, op, i in rows][::-1])",
      "note": "The last five entries of that log, oldest first. The numbers in `operation` are the codes Chroma's Python package gives the four kinds of write."
    }
  ],
  "output": "ana@lab:~/emb$ python inside.py\nembeddings                 40\nembedding_metadata         160\nembedding_fulltext_search  40\nembeddings_queue           45\n  category         returns\n  chroma:document  When your refund arrives. We refund within three w\n  lang             en\n  updated          2026-02-02\nqueued vector: 1536 bytes\nlast five writes: [(41, 'add', 'h41'), (42, 'add', 'h41'), (43, 'upsert', 'h41'), (44, 'update', 'h99'), (45, 'delete', 'h41')]"
}
```

Forty rows in `embeddings`, one per record. 160 in `embedding_metadata`, which is forty records
times four: the three metadata keys you passed, and the document itself, stored under the key
`chroma:document`. The documents are also in a full-text table, `embedding_fulltext_search`, with
one row each.

**`embeddings_queue` is a log of writes**, and it has 45 rows: the forty of `load.py` and the five
writes of `change.py`. Each carries its vector, 1,536 bytes, which is lesson 1's 384 numbers of four
bytes. Read the last five and the two writes that changed nothing are there: the second `add` of
h41 and the `update` of h99 were recorded like any other write, although neither changed a record.

## The index file lags behind the log

The log is written on every call. The index files are not, and a listing of the directory can
mislead you about that. This program stores random vectors in a separate directory and checks the
size of the index's main file after each batch:

```python
import glob
import os
import chromadb
import numpy as np

col = chromadb.PersistentClient(path="grow").create_collection(
    "random", configuration={"hnsw": {"space": "cosine"}})
print("sync_threshold:", col.configuration["hnsw"]["sync_threshold"])
rng = np.random.default_rng(12)
for n in (40, 900, 100):
    start = col.count()
    col.add(ids=[f"r{start + i}" for i in range(n)],
            embeddings=rng.normal(size=(n, 384)).astype("float32"))
    size = os.path.getsize(glob.glob("grow/*/data_level0.bin")[0])
    print(f"{col.count():5} records   data_level0.bin {size:>9,} bytes")
```

```
ana@lab:~/emb$ python grow.py
sync_threshold: 1000
   40 records   data_level0.bin   167,600 bytes
  940 records   data_level0.bin   167,600 bytes
 1040 records   data_level0.bin 1,743,040 bytes
```

**Nine hundred records went in and the file did not move.** Chroma rewrites the index files only
after `sync_threshold` writes have piled up, 1,000 by default, and until then the writes the files
have not caught up with are in the log inside `chroma.sqlite3`. Between 940 and 1,040 records the
writes crossed the threshold and Chroma rewrote the file. So the size of the `.bin` files tells you
nothing about how many records there are; `col.count()` does.

The two sizes also show how the file is laid out. 1,743,040 bytes is 1,040 slots of 1,676 bytes, and
167,600 is 100 of the same slots: the first file had room for a hundred records while it held forty.
Each slot is one vector's 1,536 bytes plus the links to its neighbours in the graph. Lesson 18
counts that overhead for a real collection.

## The same directory, served

A directory that one Python process opens is fine for a notebook, a test or a single program. A web
application with several workers wants one owner of the files and many clients, and Chroma ships a
server for exactly that. `chroma run` serves a directory over HTTP, and `HttpClient` talks to it
with the same collection methods you have been calling:

```
ana@lab:~/emb$ chroma run --path chroma --port 8012 > chroma.log 2>&1 &
ana@lab:~/emb$ curl -s localhost:8012/api/v2/heartbeat; echo
{"nanosecond heartbeat":1791220211734992705}
ana@lab:~/emb$ python remote.py
40 ['h18', 'h15', 'h22'] [0.5544, 0.5624, 0.6006]
```

```python
import chromadb

client = chromadb.HttpClient(host="localhost", port=8012)
col = client.get_collection("help")
r = col.query(query_texts=["how do I get my money back"], n_results=3)
print(col.count(), r["ids"][0], [round(d, 4) for d in r["distances"][0]])
```

Same count, same three articles, same distances. Only the client's constructor changed. One detail
moves with it and is easy to miss: **the embedding still happens in your program**. The Python
client runs the collection's embedding function before it sends anything, so `query_texts` crossed
the network as a vector, and the server never loaded a model. Chroma Cloud, the hosted version,
is reached through a third constructor, `CloudClient`, with an API key; it was not used here.
