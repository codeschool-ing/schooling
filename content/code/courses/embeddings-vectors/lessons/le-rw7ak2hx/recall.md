---
title: Recall, the measure of approximate
version: 1
---

Lesson 3 used the word **recall** for something else, and the two are easy to confuse. There it
meant whether the article the course had judged right came back for a customer's question: a
measure of the model and the search together, against a person's judgement. Here it compares an
index with exact search and nothing more. **Recall@10 is the share of exact search's top 10 that the
index also returned.** It says nothing about whether those ten were good answers. That is the
model's business, and the best an index can do is return exactly what exact search would have.

## Measuring it

`bench.py` is the small module every program in this lesson imports:

```schooling-example
{
  "language": "python",
  "file": "bench.py",
  "parts": [
    {
      "code": "import time\nimport faiss\nimport numpy as np\n\nX = np.load(\"vectors.npy\")\nQ = np.load(\"queries.npy\")\ntruth = np.load(\"truth.npy\")",
      "note": "The collection, the queries and the ground truth that `make_set.py` saved."
    },
    {
      "code": "def recall(I):\n    return np.mean([len(set(found) & set(true)) / 10\n                    for found, true in zip(I, truth)])",
      "note": "Recall@10 for a whole result: for each query, how many of the ten returned ids are among exact search's ten, divided by ten, averaged over the 1,000 queries."
    },
    {
      "code": "def timed(search):\n    faiss.omp_set_num_threads(1)\n    start = time.perf_counter()\n    I = search(Q)\n    ms = (time.perf_counter() - start) * 1000 / len(Q)\n    faiss.omp_set_num_threads(4)\n    return I, ms",
      "note": "Times a search of all 1,000 queries on one core and returns the milliseconds per query. FAISS goes back to four threads afterwards, so that building an index still uses the whole machine."
    }
  ]
}
```

`recall.py` uses it on two searches that skip vectors. The first is a deliberately naive one: pick
a random tenth of the collection and search it exactly. The second is `HNSW32`, one of the factory
strings lesson 13 named, with FAISS's default settings:

```schooling-example
{
  "language": "python",
  "file": "recall.py",
  "parts": [
    {
      "code": "import faiss\nimport numpy as np\nfrom bench import X, Q, truth, recall\n\nrng = np.random.default_rng(1)\npart = rng.choice(len(X), size=10_000, replace=False)\nsample = faiss.IndexIDMap(faiss.IndexFlatIP(384))\nsample.add_with_ids(X[part], part)\n_, I = sample.search(Q, 10)\nprint(f\"exact search over a random tenth: recall@10 {recall(I):.3f}\")",
      "note": "A random tenth of the collection, kept under its original ids by `IndexIDMap` so the result can be compared with the ground truth, and searched exactly."
    },
    {
      "code": "hnsw = faiss.index_factory(384, \"HNSW32\", faiss.METRIC_INNER_PRODUCT)\nhnsw.add(X)\nS, I = hnsw.search(Q, 10)\nper = np.array([len(set(a) & set(b)) / 10 for a, b in zip(I, truth)])\nprint(f\"HNSW32 over everything:          recall@10 {per.mean():.3f}\")\nprint(f\"queries with all 10: {np.sum(per == 1)}, with 5 or fewer: {np.sum(per <= 0.5)}\")",
      "note": "Lesson 13's `HNSW32` over all 100,000 vectors, with FAISS's defaults. `per` keeps each query's recall so the spread can be counted, not only the mean."
    },
    {
      "code": "true_scores = (X[truth] * Q[:, None, :]).sum(axis=2)\nprint(f\"mean score of the 10 returned: exact {true_scores.mean():.4f}, HNSW32 {S.mean():.4f}\")",
      "note": "The scores of the ten vectors exact search returned, recomputed from the vectors, beside the scores `HNSW32` returned."
    }
  ],
  "output": "ana@lab:~/emb$ python recall.py\nexact search over a random tenth: recall@10 0.104\nHNSW32 over everything:          recall@10 0.841\nqueries with all 10: 683, with 5 or fewer: 149\nmean score of the 10 returned: exact 0.4750, HNSW32 0.4593"
}
```

**The random tenth found 0.104 of the true neighbours**, which is what reading a random tenth has
to find: each of the ten is in the sample with a chance of one in ten. That is the baseline. Any
index reads only part of the collection, and **its whole job is to beat the fraction it reads** by
guessing which part holds the neighbours. `HNSW32` reads far less than a tenth, as the HNSW
sections count, and found 0.841.

## An average hides the spread

The 0.841 is a mean over 1,000 queries, and the queries did not share it. 683 of them got all ten
neighbours, and 149 got five or fewer. A search that is good on average can still be poor for the
customer whose question lands in a part of the space the index served badly, and a test with a
handful of queries will not find that customer.

Lesson 13 ran the same `HNSW32` on its own set of noisy copies and found all ten neighbours
for every query. **Recall belongs to the index and the data together**, which is why it has to be
measured on vectors like yours.

## What a miss costs

The last line puts a number on what the misses were. The ten vectors exact search returned scored
0.4750 on average, and the ten `HNSW32` returned scored 0.4593. **A missed neighbour is replaced by
one slightly further away**, not by a random vector: the search found the right neighbourhood and
missed some of its members. When the median query's best and tenth neighbours score 0.508 and 0.470,
as the last section measured, a small step in score is enough to swap one for another.

Whether that matters is a question about the application. Ten passages handed to a language model
lose little when one is swapped for a nearly identical neighbour. A check for duplicate uploads
that looks for the one copy of a file loses everything when that copy is the one missed.

## Approximate is a dial

Every approximate index has a setting that reads more of the collection for more recall, and the
rest of this lesson turns those settings and measures both sides. The method does not change:
**choose the recall you need, then find the cheapest setting that reaches it on your data**, with
ground truth from exact search over a sample of your own queries. Exact search over 1,000 queries
took seconds here, even though serving every customer that way is what the index is for.
