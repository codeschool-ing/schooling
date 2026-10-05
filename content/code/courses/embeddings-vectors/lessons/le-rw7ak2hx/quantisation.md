---
title: Quantisation inside the index
version: 1
---

Every index so far kept each vector whole: 384 numbers of 4 bytes, 1,536 bytes a vector, read and
multiplied in full whenever the search reaches it. **Quantisation replaces the vector with a
shorter code** and computes the score from the code. It is easy to assume the loss is in proportion
to the bytes removed, so that a quarter of the size keeps about a quarter of the quality. The two
methods below show that the loss depends on how the code is built, far more than on how small it is.

## Two ways to make a code

**Scalar quantisation** treats every number on its own. Training records the range each of the 384
coordinates takes across the collection, and each number is stored as one byte saying where in its
coordinate's range it falls. FAISS calls it `SQ8`: 384 bytes a vector, a quarter of the original.

**Product quantisation** treats the vector in pieces. `PQ96` cuts the 384 numbers into 96 pieces of
4, and training runs k-means on each piece position separately, finding 256 typical values for
it. Each piece is then stored as one byte, the number of the typical value nearest to it, so the
vector becomes 96 bytes. `PQ48` uses 48 pieces of 8, and `PQ16` 16 pieces of 24. Inside an IVF
index, FAISS codes each vector's difference from its cell's centre rather than the vector itself,
which leaves less to code. To score a query against a code, the search first compares the query's pieces with all 256 typical values of each
position, once per query, and then each vector's score is a sum of 96 numbers looked up in that
table instead of 384 multiplications.

## What each one keeps

`quant.py` builds IVF indexes with 1,024 cells and each kind of code, trains them on 40,000 of the
vectors, and searches 16 cells:

```schooling-example
{
  "language": "python",
  "file": "quant.py",
  "parts": [
    {
      "code": "import time\nimport faiss\nimport numpy as np\nfrom bench import X, recall, timed\n\nsample = X[np.random.default_rng(2).choice(len(X), size=40_000, replace=False)]\nprint(f\"{'index':>13} {'bytes/vector':>12} {'train':>7} {'recall@10':>9} {'per query':>10}\")\nfor spec in (\"IVF1024,Flat\", \"IVF1024,SQ8\", \"IVF1024,PQ96\", \"IVF1024,PQ48\", \"IVF1024,PQ16\"):\n    index = faiss.index_factory(384, spec, faiss.METRIC_INNER_PRODUCT)\n    start = time.perf_counter()\n    index.train(sample)\n    trained = time.perf_counter() - start\n    index.add(X)\n    index.nprobe = 16\n    I, ms = timed(lambda Q: index.search(Q, 10)[1])\n    print(f\"{spec:>13} {index.code_size:>12} {trained:>5.1f} s {recall(I):>9.3f} {ms:>7.3f} ms\")",
      "note": "Five IVF indexes with 1,024 cells, built from factory strings: full vectors, one byte per number, and product codes of 96, 48 and 16 bytes. Each is trained on the same 40,000 vectors and searched with `nprobe` 16. `code_size` is the bytes stored per vector."
    }
  ],
  "output": "ana@lab:~/emb$ python quant.py\n        index bytes/vector   train recall@10  per query\n IVF1024,Flat         1536   7.0 s     0.999   0.309 ms\n  IVF1024,SQ8          384   7.5 s     0.987   0.223 ms\n IVF1024,PQ96           96  60.8 s     0.693   0.138 ms\n IVF1024,PQ48           48  38.2 s     0.450   0.085 ms\n IVF1024,PQ16           16  20.0 s     0.230   0.096 ms"
}
```

**`SQ8` kept 0.987 of the true neighbours at a quarter of the size.** One byte per number is fine
enough to keep almost every ranking that the full numbers make, and the training took 7.5 s, about
as long as the cells alone.

**Product quantisation lost far more than its share.** `PQ96` is a sixteenth of the size and kept
0.693; `PQ48` kept 0.450 and `PQ16` 0.230. Its training was the slow step of this whole lesson,
60.8 s for `PQ96`, because it is 96 separate k-means runs. Lesson 13 saw 16-byte codes lose most of
the neighbours on tightly packed copies of real vectors and expected looser ones to lose less; on
these blends they lost nearly as much. The reason is the narrow band the exact-search section measured. A
query's ten nearest vectors score within a few hundredths of each other, and a code that blurs
every score by more than that reorders them. The neighbourhood is still found; its order is not.

That is why product quantisation is rarely the last step. The usual design keeps the codes in
memory to choose a few hundred candidates fast, and keeps the full vectors somewhere cheaper, such
as on disk, to rescore just those. Lesson 16 measured that pattern with binary codes, the most
extreme form: one bit per number, 48 bytes for these vectors.

## Where the bytes go

The `bytes/vector` column is only the codes. The index also stores each vector's id and the cell
centres, and lesson 18 weighs whole index files and prices each form, along with `float16`, int8
and binary vectors stored outside an index. pgvector 0.6.0, the version in the lab, has no quantised
index at all: its `hnsw` and `ivfflat` keep the full vectors.

What to take from this table is the order of the questions. Ask first whether full vectors fit in
memory; at 1,536 bytes, 100,000 of them are 153.6 MB. If they do not, try `SQ8` before anything
cleverer, measured as this program measures it. Reach for product quantisation when the collection
is too big for anything else, and plan the rescoring step with it.
