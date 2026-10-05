---
title: FAISS, an index and nothing else
version: 1
---

FAISS turns up in most lists of vector databases, and it is not one. **It is a library that keeps
vectors in memory and finds the nearest ones**, written in C++ by Meta's research lab, with Python
bindings; the lab pins `faiss-cpu` 1.15.1, and a GPU build exists beside it. It stores no text, no
metadata and none of your ids, it has no server and no query language, and it saves nothing to
disk unless you ask. What it does, it does fast and in many ways, and that is why databases are
built on it.

The smallest FAISS program puts the 40 help-centre vectors in a flat index and asks lesson 1's
question:

```schooling-example
{
  "language": "python",
  "file": "flat.py",
  "parts": [
    {
      "code": "import json\nimport faiss\nfrom minilm import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nids = [h[\"id\"] for h in help]\nX = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])",
      "note": "The 40 articles, embedded as in every lesson since lesson 3. `ids` keeps their ids in the same order as the rows of `X`."
    },
    {
      "code": "index = faiss.IndexFlatIP(384)\nindex.add(X)\nprint(index.ntotal, \"vectors of\", index.d, \"dimensions\")",
      "note": "`IndexFlatIP` compares by inner product, which for unit vectors is cosine similarity. It is told the dimension and nothing else."
    },
    {
      "code": "D, I = index.search(embed(\"how do I get my money back\"), 3)\nprint(\"positions:\", I[0], \" scores:\", D[0].round(4))\nprint(\"articles: \", [ids[i] for i in I[0]])",
      "note": "`search` takes a matrix of queries and returns two: the scores and the positions of the nearest rows. The positions are turned back into article ids by hand."
    }
  ],
  "output": "ana@lab:~/emb$ python flat.py\n40 vectors of 384 dimensions\npositions: [17 14 21]  scores: [0.4456 0.4376 0.3994]\narticles:  ['h18', 'h15', 'h22']"
}
```

The scores are the dot products lesson 1 printed, 0.4456 for the gift article, because
`IndexFlatIP` compares by inner product and the vectors have length 1. A **flat** index is exact
search: it compares the query with every stored vector, which is lesson 3's `D @ q` written in C++.

**What comes back are positions.** `[17 14 21]` means the 18th, 15th and 22nd vectors that were
added, and only the `ids` list the program kept beside the index turns them into h18, h15 and h22.
Delete an article, rebuild the list in a different order, and the positions point at different
articles while the index answers as confidently as before.

## Your own ids, and a file

`IndexIDMap` wraps another index and stores a 64-bit integer beside each vector, so the search
returns your numbers instead of positions. Integers only: h15 has to become 15.

```schooling-example
{
  "language": "python",
  "file": "ids.py",
  "parts": [
    {
      "code": "import json\nimport os\nimport faiss\nimport numpy as np\nfrom minilm import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nX = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])\nq = embed(\"how do I get my money back\")",
      "note": "The same vectors, and the question embedded once."
    },
    {
      "code": "index = faiss.IndexIDMap(faiss.IndexFlatIP(384))\nindex.add_with_ids(X, np.array([int(h[\"id\"][1:]) for h in help]))\nprint(\"ids:\", index.search(q, 3)[1][0])",
      "note": "`IndexIDMap` wraps the flat index and stores a 64-bit integer for each vector. h15 becomes 15, because FAISS takes no strings."
    },
    {
      "code": "index.remove_ids(np.array([18]))\nprint(\"ids:\", index.search(q, 3)[1][0], \"of\", index.ntotal)",
      "note": "Remove id 18, the gift article, and search again."
    },
    {
      "code": "faiss.write_index(index, \"help.faiss\")\nagain = faiss.read_index(\"help.faiss\")\nprint(again.ntotal, \"vectors read back,\", os.path.getsize(\"help.faiss\"), \"bytes on disk\")",
      "note": "Write the index to a file and read it into a new object, as another program would."
    }
  ],
  "output": "ana@lab:~/emb$ python ids.py\nids: [18 15 22]\nids: [15 22 14] of 39\n39 vectors read back, 60306 bytes on disk"
}
```

With h18 removed, the search moved down a place and found h14. The file is 60,306 bytes: 39
vectors of 1,536 bytes are 59,904, their ids add 39 × 8 = 312, and the remaining 90 bytes describe
the index. **The titles, bodies and categories are not in it**, and they never will be. Something
else has to hold them, keyed by the same integers: a dictionary, a JSON file, a table in a
database. Keeping that store and the index in step on every change is your program's job, which is
the consistency lesson 11 asked of any store, with nobody to enforce it.

## A library checks little

In lesson 12, Chroma refused a WordLlama vector with a sentence naming both dimensions. FAISS
refuses it too,
and says this:

```python
import faiss
import numpy as np

index = faiss.IndexFlatIP(384)
try:
    index.add(np.zeros((1, 256), dtype="float32"))
except Exception as e:
    print(type(e).__name__, repr(str(e)))
```

```
ana@lab:~/emb$ python wrong.py
AssertionError ''
```

An assertion with an empty message. FAISS caught the mistake, and the program that made it learns
nothing about what it was. That is the trade a library makes throughout: it assumes the caller
knows the dimension, the metric and the meaning of every id, and it spends nothing on checking.
