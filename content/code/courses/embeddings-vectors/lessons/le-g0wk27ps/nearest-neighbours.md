---
title: Nearest neighbours
version: 1
---

The usual picture of a classifier is a model trained for the job: thousands of labelled examples,
hours of training, something new to deploy. With embeddings, the simplest classifier that works has
**no training step at all**. You keep messages somebody has already sorted, and a new message gets
the label of the ones it is closest to.

Marginalia's support team has sorted 150 messages into five desks. The file keeps them as one JSON
object per line, and each one says which part of this lesson may learn from it:

```
ana@lab:~/emb$ head -n 3 data/tickets.jsonl
{"id": "t001", "label": "shipping", "split": "train", "text": "My order was supposed to arrive on Tuesday and it's now Friday. Where is it?"}
{"id": "t002", "label": "shipping", "split": "train", "text": "The tracking page has said 'label created' for four days."}
{"id": "t003", "label": "shipping", "split": "train", "text": "Do you deliver to Portugal and how long does it take?"}
ana@lab:~/emb$ jq -r '.split + " " + .label' data/tickets.jsonl | sort | uniq -c
     10 test account
     10 test ebooks
     10 test payments
     10 test returns
     10 test shipping
     20 train account
     20 train ebooks
     20 train payments
     20 train returns
     20 train shipping
```

The 100 marked `train` are what a method is allowed to look at. The 50 marked `test` are held back
to measure it, ten per desk, and no method in this lesson sees their labels until the score is
counted. A test set that the method has learned from measures memory, not classification; the
section *Measuring a classifier* comes back to why that separation is the whole point.

## Embed once, keep the vectors

Every program in this lesson needs the same 150 vectors, so the first one to run computes them
and saves them beside the data:

```schooling-example
{
  "language": "python",
  "file": "tickets.py",
  "parts": [
    {
      "code": "import json\nimport os\nimport numpy as np\nfrom minilm import embed",
      "note": "A small module the other programs import, so that the 150 tickets are embedded once and not once per program."
    },
    {
      "code": "def load(split):\n    rows = [t for t in map(json.loads, open(\"data/tickets.jsonl\"))\n            if t[\"split\"] == split]",
      "note": "`load(\"train\")` or `load(\"test\")` reads the tickets of one split, in the order the file has them."
    },
    {
      "code": "    path = f\"{split}.npy\"\n    if not os.path.exists(path):\n        np.save(path, embed([t[\"text\"] for t in rows]))",
      "note": "The first call embeds them and saves the vectors as `train.npy` or `test.npy`. Every later call finds the file and skips the model."
    },
    {
      "code": "    labels = np.array([t[\"label\"] for t in rows])\n    return np.load(path), labels, rows",
      "note": "It returns three things in the same order: the vectors, the labels as a NumPy array, and the tickets themselves, for printing."
    }
  ]
}
```

The labels stay in a separate array, in the same order as the vectors. Row 7 of `train.npy` is the
vector of the ticket whose label is `ytr[7]`, and nothing else ties them together, so the order of
the file must not change between the two.

## Copy the label of the closest

A new message is compared with all 100 labelled ones, exactly as lesson 3 compared a question
with the help articles. Then the labels of the closest `k` are counted, and the most frequent one
wins:

```schooling-example
{
  "language": "python",
  "file": "knn.py",
  "parts": [
    {
      "code": "from collections import Counter\nimport numpy as np\nfrom tickets import load\n\nXtr, ytr, train = load(\"train\")\nXte, yte, test = load(\"test\")\nprint(Xtr.shape, Xte.shape)",
      "note": "Load both splits. The first run of this program is the one that embeds them."
    },
    {
      "code": "S = Xte @ Xtr.T\norder = np.argsort(-S, axis=1)",
      "note": "`Xte @ Xtr.T` is a 50 × 100 table: every test ticket scored against every training ticket. `argsort` on the negated scores lists, for each test ticket, the training tickets from nearest to furthest."
    },
    {
      "code": "def vote(row, k):\n    return Counter(ytr[row[:k]]).most_common(1)[0][0]\n\nfor k in (1, 3, 5, 10):\n    pred = np.array([vote(row, k) for row in order])\n    print(f\"k={k:<3} {(pred == yte).sum()} of {len(yte)} right\")",
      "note": "Take the labels of the nearest `k`, count them, and keep the most frequent. Then count how many of the 50 predictions match the real label."
    }
  ]
}
```

```
ana@lab:~/emb$ python knn.py
(100, 384) (50, 384)
k=1   46 of 50 right
k=3   42 of 50 right
k=5   45 of 50 right
k=10  46 of 50 right
```

This is **k-nearest neighbours**, k-NN for short. With `k=1` it copies the label of the single
closest ticket, and **46 of the 50 test tickets land on the right desk**. Nothing was fitted to
the data: the only work was embedding and one matrix product.

**A larger `k` is not automatically better.** Three neighbours scored 42, five scored 45 and ten
scored 46. A vote only changes the answer when the neighbours disagree, and then two tickets
further away can outvote the nearest one in either direction. A tie is settled by
`Counter.most_common`, which returns the label it met first, and the nearest neighbour is met
first. Reading two of the mistakes says more than the totals. `neighbours.py` prints the five
training tickets nearest to one test ticket:

```python
import sys
import numpy as np
from tickets import load

Xtr, ytr, train = load("train")
Xte, yte, test = load("test")
i = [t["id"] for t in test].index(sys.argv[1])
print(test[i]["id"], yte[i], test[i]["text"])
s = Xtr @ Xte[i]
for j in np.argsort(-s)[:5]:
    print(f"  {s[j]:.3f}  {train[j]['id']}  {ytr[j]:9} {train[j]['text']}")
```

```
ana@lab:~/emb$ python neighbours.py t021
t021 shipping Still waiting for my books, ordered almost two weeks ago.
  0.583  t031  returns   I'd like to send back a book I bought last week, it's not what I expected.
  0.572  t016  shipping  I'm moving next week. Will the books still reach me if they're late?
  0.535  t042  returns   I ordered one book and got a completely different title.
  0.523  t020  shipping  Box arrived open and one book is missing.
  0.516  t006  shipping  I only got two of the three books I ordered. Is the third one coming separately?
ana@lab:~/emb$ python neighbours.py t054
t054 returns I sent the book back two weeks ago, where is my refund?
  0.778  t135  ebooks    I downloaded the e-book but now I want a refund.
  0.777  t031  returns   I'd like to send back a book I bought last week, it's not what I expected.
  0.777  t124  ebooks    I bought the wrong e-book by mistake, can I get a refund? I haven't opened it.
  0.567  t036  returns   My aunt gave me a book I already have. Can I return it without her finding out?
  0.513  t020  shipping  Box arrived open and one book is missing.
```

**t021** is a delivery that has not arrived. Its nearest neighbour is a return, by 0.011, because
both talk about books bought a short time ago. The next four include three shipping tickets, so a
vote of five puts it right where one neighbour put it wrong.

**t054** is the more instructive one. Three tickets sit within 0.001 of each other at the top, and
two of the three are refunds for e-books. The model is right that they are close: all three ask
for money back for something already bought. What separates them is a rule of Marginalia's, that
e-book refunds go to the e-books desk, and nothing in the meaning of the words carries that rule.
A classifier built on similarity inherits every boundary that follows the meaning and none that
follows a policy.

## What it costs

k-NN keeps every labelled vector and compares each new message with all of them. For 100 tickets
that is nothing. For a million it is a search problem, the same one lesson 11 introduces and
lesson 15 makes fast, and any vector database from lessons 12 to 14 can serve as the store.

The return for that cost is that **learning is appending**. A ticket the support team sorts today
is one more row tomorrow, with no training run in between, and a ticket labelled wrongly can be
found and deleted, because every decision points back at the examples that made it.
