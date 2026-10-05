---
title: What a database adds
version: 1
---

A common first picture of a vector database is "the thing that makes search fast". Speed is one of
the things it adds, and for Marginalia's 40 articles it is the one that matters least: the previous
section searched ten thousand vectors in under a millisecond. **Most of what a vector database adds
is what a database adds to anything**: the data survives the program, records have names, and they
can be changed one at a time while other people are reading them.

Lay that against the arrays of lessons 3 to 10. A NumPy matrix of vectors has:

- No persistence. It lives in the memory of one program and is gone when the program stops,
  unless somebody writes it to a file and remembers which file.
- No ids. A row is an article only because a separate list says so, in the same order. Insert
  a row in one and not the other, and every search answers with the wrong article from then on.
- No metadata. The category, the language and the date of each article are somewhere else, so
  "only Portuguese articles" is a second lookup written by hand.
- No updates or deletes. Changing one article means rebuilding the matrix, or getting row
  numbers right by hand.
- No concurrency. Two programs writing the same file at once is a corrupted file.
- No index. Every query reads every vector, at the cost the previous section measured.
- No backups, no access control, and no record of which model made the numbers.

**A vector database is a store that answers all of those.** Before the real ones, it helps to see
that the core is small. The program below is a whole store in about fifty lines: persistence, ids,
metadata, updates, deletes and a filter, with exact search inside. It has no index and no
concurrency, and it is not for production. It is there so that every word of the next three sections
is something you have run.

```schooling-example
{
  "language": "python",
  "file": "tinystore.py",
  "parts": [
    {
      "code": "import json\nimport os\nimport numpy as np\n\n\nclass Store:\n    \"\"\"A collection: one model, one dimension, records of id + vector + metadata + text.\"\"\"",
      "note": "One `Store` is one collection, and its docstring says what a record is."
    },
    {
      "code": "    def __init__(self, path, model, dim):\n        self.path, self.model, self.dim = path, model, dim\n        self.ids, self.meta, self.docs = [], [], []\n        self.vecs = np.zeros((0, dim), dtype=np.float32)\n        self.alive = np.zeros(0, dtype=bool)\n        self.where = {}                                  # id -> row",
      "note": "The model and the dimension are fixed when the collection is created. Rows live in parallel lists and one NumPy array; `alive` marks which rows count, and `where` finds an id's row."
    },
    {
      "code": "    def upsert(self, id, vec, meta, doc):\n        vec = np.asarray(vec, dtype=np.float32)\n        if vec.shape != (self.dim,):\n            raise ValueError(f\"{self.model} vectors have {self.dim} numbers, got {vec.shape}\")\n        vec = vec / np.linalg.norm(vec)\n        if id in self.where:                             # same id: replace in place\n            self.alive[self.where[id]] = False\n        self.where[id] = len(self.ids)\n        self.ids.append(id); self.meta.append(meta); self.docs.append(doc)\n        self.vecs = np.vstack([self.vecs, vec])\n        self.alive = np.append(self.alive, True)",
      "note": "An upsert refuses a vector of the wrong size and normalises the rest. An id that exists already has its old row marked dead, and the new record is appended."
    },
    {
      "code": "    def delete(self, id):\n        self.alive[self.where.pop(id)] = False           # a tombstone, not a removal",
      "note": "A delete only marks the row dead. The vector stays in the array until the store is saved."
    },
    {
      "code": "    def search(self, q, k=3, model=None, **filters):\n        if model != self.model:\n            raise ValueError(f\"this collection holds {self.model} vectors, not {model}\")\n        ok = self.alive.copy()\n        for key, value in filters.items():\n            ok &= np.array([m.get(key) == value for m in self.meta], dtype=bool)\n        scores = np.where(ok, self.vecs @ q, -np.inf)\n        best = np.argsort(-scores)[:k]\n        return [(self.ids[i], float(scores[i])) for i in best if ok[i]]",
      "note": "A search must name the model its question was embedded with. Rows that are dead or fail a filter get a score of minus infinity, the rest are ranked by dot product, and the k best come back as ids with scores."
    },
    {
      "code": "    def save(self):\n        keep = np.flatnonzero(self.alive)                # compaction drops the tombstones\n        os.makedirs(self.path, exist_ok=True)\n        np.save(os.path.join(self.path, \"vectors.npy\"), self.vecs[keep])\n        with open(os.path.join(self.path, \"records.json\"), \"w\") as f:\n            json.dump({\"model\": self.model, \"dim\": self.dim,\n                       \"records\": [{\"id\": self.ids[i], \"meta\": self.meta[i], \"doc\": self.docs[i]}\n                                   for i in keep]}, f)\n\n    @classmethod\n    def load(cls, path):\n        info = json.load(open(os.path.join(path, \"records.json\")))\n        s = cls(path, info[\"model\"], info[\"dim\"])\n        for r, v in zip(info[\"records\"], np.load(os.path.join(path, \"vectors.npy\"))):\n            s.upsert(r[\"id\"], v, r[\"meta\"], r[\"doc\"])\n        return s",
      "note": "Saving writes only the live rows: the vectors to a `.npy` file and everything else to JSON beside it. Loading reads both and upserts every record again."
    }
  ]
}
```

`index.py` fills it with the help centre. Each article becomes a record with its id, its vector,
three fields of metadata and its text, and the store writes itself to a directory:

```schooling-example
{
  "language": "python",
  "file": "index.py",
  "parts": [
    {
      "code": "import json\nfrom minilm import embed\nfrom tinystore import Store\n\nhelp = [json.loads(l) for l in open(\"data/help.jsonl\")]\ntexts = [h[\"title\"] + \". \" + h[\"body\"] for h in help]",
      "note": "The 40 articles, each as title and body joined, which is the text that gets embedded and the text a search hands back."
    },
    {
      "code": "store = Store(\"store\", \"all-MiniLM-L6-v2\", 384)\nfor h, text, vec in zip(help, texts, embed(texts)):\n    meta = {\"category\": h[\"category\"], \"lang\": h[\"lang\"], \"updated\": h[\"updated\"]}\n    store.upsert(h[\"id\"], vec, meta, text)\nstore.save()\nprint(len(store.ids), \"records saved\")",
      "note": "One collection for all-MiniLM-L6-v2's 384 numbers. Each article becomes a record: its id, its vector, three fields of metadata and its text. Then save it to the directory `store`."
    }
  ]
}
```

```
ana@lab:~/emb$ python index.py
40 records saved
ana@lab:~/emb$ ls -l store
total 80
-rw-r--r-- 1 ana ana 14140 Oct  5 14:21 records.json
-rw-r--r-- 1 ana ana 61568 Oct  5 14:21 vectors.npy
```

**Two files, and each one is easy to account for.** `vectors.npy` is 61568 bytes: 40 vectors of
384 `float32` numbers is 40 × 1,536 = 61,440 bytes, and the other 128 are the header NumPy writes
in front of every array. `records.json` holds the ids, the metadata, the texts, and the model's
name and dimension. Chroma's persistent directory in lesson 12 keeps the same ingredients in an
SQLite file and a set of index files, and LanceDB in lesson 13 keeps them in columnar files. Neither
is as easy to read as this, and the main thing each adds is the index.

Searching it is the line of lesson 3 again, behind a function that knows which rows are records:

```schooling-example
{
  "language": "python",
  "file": "ask.py",
  "parts": [
    {
      "code": "import sys\nfrom minilm import embed\nfrom tinystore import Store\n\nstore = Store.load(\"store\")\nq = embed(sys.argv[1])[0]\nfor id, score in store.search(q, k=3, model=\"all-MiniLM-L6-v2\"):\n    print(f\"{score:.3f}  {id}  {store.docs[store.where[id]][:58]}\")",
      "note": "Load the store from disk, embed the question from the command line with the collection's model, and print the three best records with their scores and the start of their text."
    }
  ]
}
```

```
ana@lab:~/emb$ python ask.py "how do I get my money back"
0.446  h18  Returning a gift. The person who received the gift can ret
0.438  h15  When your refund arrives. We refund within three working d
0.399  h22  Charged twice for one order. When a payment fails and you 
```

The scores are the ones lesson 1 printed for the same question and the same articles: 0.446 for the
gift article and 0.438 for the refund one. The store changed where the vectors live and how they are
named, not what they are.
