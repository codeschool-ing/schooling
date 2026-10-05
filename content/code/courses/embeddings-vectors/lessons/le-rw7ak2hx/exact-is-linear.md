---
title: Exact search reads everything
version: 1
---

Lesson 11 timed exact search and found that the time follows the count: ten times the vectors,
about ten times as long. That is the cost every index in this lesson exists to avoid, and before
measuring how they avoid it you need a collection big enough to feel it and a set of queries whose
true answers you know.

## A hundred thousand vectors, and what they are

The obvious shortcut is to fill an index with random numbers. **Random vectors are the wrong test
for an approximate index**, because they have no neighbourhoods: in 384 dimensions, uniformly random
points sit at almost the same distance from one another, and an index that bets on structure has
nothing to bet on. The IVF section measures what that does. Real embeddings are the opposite; the
whole of lessons 3 to 6 relied on texts about the same thing landing close together.

Embedding 100,000 real texts would need 100,000 texts, and the course has 334. So `make_set.py`
builds the set from those 334 instead:

```schooling-example
{
  "language": "python",
  "file": "make_set.py",
  "parts": [
    {
      "code": "import json\nimport faiss\nimport numpy as np\nfrom minilm import embed\n\nsources = [(\"help\", \"body\"), (\"queries\", \"text\"), (\"tickets\", \"text\"),\n           (\"books\", \"blurb\"), (\"inbox\", \"text\"), (\"week2\", \"text\")]\ntexts = [json.loads(line)[key] for name, key in sources\n         for line in open(f\"data/{name}.jsonl\")]\nreal = embed(texts)",
      "note": "The course's own texts: the help articles, the questions, the tickets, the book blurbs and the two sets of messages. Embedded with all-MiniLM-L6-v2, they give 334 real vectors."
    },
    {
      "code": "rng = np.random.default_rng(15)\n\ndef blends(n):\n    a = real[rng.integers(len(real), size=n)]\n    b = real[rng.integers(len(real), size=n)]\n    w = rng.random((n, 1))\n    v = w * a + (1 - w) * b + rng.normal(scale=0.05, size=(n, 384))\n    return (v / np.linalg.norm(v, axis=1, keepdims=True)).astype(\"float32\")\n\nX, Q = blends(100_000), blends(1_000)",
      "note": "A blend takes two real vectors at random, mixes them in a random proportion, adds noise of 0.05 per coordinate and divides by the length. The generator is seeded, so every run makes the same set."
    },
    {
      "code": "exact = faiss.IndexFlatIP(384)\nexact.add(X)\nscores, truth = exact.search(Q, 10)\nnp.save(\"vectors.npy\", X)\nnp.save(\"queries.npy\", Q)\nnp.save(\"truth.npy\", truth)",
      "note": "Exact search with FAISS finds the true top 10 of every query. The three files are what every later program loads."
    },
    {
      "code": "print(f\"{len(real)} real vectors, {len(X):,} blends, {len(Q):,} queries\")\nprint(f\"best score per query, median: {np.median(scores[:, 0]):.3f}\")\nprint(f\"10th score per query, median: {np.median(scores[:, 9]):.3f}\")",
      "note": "Two medians: the score of each query's best match and of its tenth."
    }
  ],
  "output": "ana@lab:~/emb$ python make_set.py\n334 real vectors, 100,000 blends, 1,000 queries\nbest score per query, median: 0.508\n10th score per query, median: 0.470"
}
```

**Every one of the 100,000 vectors is a blend of two real all-MiniLM-L6-v2 vectors**, in a random
proportion, with a little noise, divided by its length. The blends inherit the shape of the real
space: they crowd where the texts crowd and thin out where they do not. The 1,000 queries are made
the same way and are not in the collection.

The last step is the one every measurement below depends on. **`IndexFlatIP` is exact search**,
the same multiply-and-sort as lesson 3's NumPy line, and `truth.npy` keeps its top 10 for each
query. That is the ground truth: whatever an approximate index returns is compared with it.

Notice the two medians. The best match scores 0.508 and the tenth 0.470, so a query's ten nearest
neighbours are packed into a narrow band of scores. Remember it; it decides several results in this
lesson.

## The time follows the count

`bench.py`, which the next section shows, loads the three files and times a search on one core.
`exact.py` runs exact search over the first 12,500, 25,000, 50,000 and 100,000 vectors:

```schooling-example
{
  "language": "python",
  "file": "exact.py",
  "parts": [
    {
      "code": "import faiss\nfrom bench import X, timed\n\nprint(f\"{'vectors':>9} {'per query':>10} {'per vector':>11}\")\nfor n in (12_500, 25_000, 50_000, 100_000):\n    index = faiss.IndexFlatIP(384)\n    index.add(X[:n])\n    _, ms = timed(lambda Q: index.search(Q, 10)[1])\n    print(f\"{n:>9,} {ms:>7.3f} ms {ms * 1e6 / n:>8.1f} ns\")",
      "note": "An exact index over the first `n` vectors at four sizes, timed with `bench.timed`. The last column divides the time by the number of vectors."
    }
  ],
  "output": "ana@lab:~/emb$ python exact.py\n  vectors  per query  per vector\n   12,500   0.303 ms     24.2 ns\n   25,000   0.712 ms     28.5 ns\n   50,000   1.033 ms     20.7 ns\n  100,000   2.492 ms     24.9 ns"
}
```

**Eight times the vectors took 8.2 times as long**, from 0.303 ms to 2.492 ms, and the cost per
vector stays between 20.7 and 28.5 ns, which is the noise of a machine shared with other work. These
times are a batch of 1,000 queries divided by 1,000, which lets the processor use each vector it
loads for many queries at once; lesson 11 timed one query at a time with NumPy, so its times are
larger and are not comparable with these.

What does not change is the shape. Exact search over 100,000 vectors makes 100,000 comparisons per
query, each of them 384 multiply-adds, and no cleverness in the arithmetic makes that number
smaller. **To go faster, a search has to skip vectors.** And to skip one, it has to decide without
looking that the vector cannot be among the nearest. When that decision is wrong, the search misses
a true neighbour, and that is what *approximate* means.
