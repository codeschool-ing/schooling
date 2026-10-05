---
title: IVF, searching a few cells
version: 1
---

The first way to skip vectors is the one a librarian would invent. Sort the collection into
groups of similar vectors once, in advance. When a query arrives, find the groups nearest to it
and search only those. FAISS calls this an **inverted file**, IVF, after the lists of documents per
word that keyword search keeps; here each list holds the vectors of one group, and the groups are
called **cells**.

The groups come from **k-means**: choose `nlist` centre points so that every vector is close to
one of them, and file each vector under its nearest centre. A query is compared with the `nlist`
centres, which is cheap, and then searched exactly against the vectors of its `nprobe` nearest
cells.

## Training comes first

`ivf.py` builds an IVF index with 1,024 cells over the 100,000 vectors and turns `nprobe` from 1
to 64:

```schooling-example
{
  "language": "python",
  "file": "ivf.py",
  "parts": [
    {
      "code": "import time\nimport faiss\nimport numpy as np\nfrom bench import X, recall, timed\n\ncells = faiss.IndexFlatIP(384)\nivf = faiss.IndexIVFFlat(cells, 384, 1024, faiss.METRIC_INNER_PRODUCT)\ntry:\n    ivf.add(X)\nexcept RuntimeError as e:\n    print(\"add before train:\", str(e).splitlines()[-1])",
      "note": "An IVF index needs a small exact index of its own to hold the cell centres. Adding vectors before training raises, and the program prints the last line of the error."
    },
    {
      "code": "start = time.perf_counter()\nivf.train(X)\nivf.add(X)\nprint(f\"k-means into 1024 cells, then add: {time.perf_counter() - start:.1f} s\")\nsizes = np.array([ivf.invlists.list_size(i) for i in range(1024)])\nprint(f\"vectors per cell: smallest {sizes.min()}, median {np.median(sizes):.0f}, largest {sizes.max()}\")",
      "note": "`train` runs k-means and `add` files every vector in its cell. `invlists` holds the cells, and the sizes show how uneven they are."
    },
    {
      "code": "print(f\"{'nprobe':>6} {'recall@10':>9} {'per query':>10} {'compared':>9}\")\nfor nprobe in (1, 2, 4, 8, 16, 32, 64):\n    ivf.nprobe = nprobe\n    faiss.cvar.indexIVF_stats.reset()\n    I, ms = timed(lambda Q: ivf.search(Q, 10)[1])\n    compared = faiss.cvar.indexIVF_stats.ndis / 1000\n    print(f\"{nprobe:>6} {recall(I):>9.3f} {ms:>7.3f} ms {compared:>9,.0f}\")",
      "note": "The same 1,000 queries at seven settings of `nprobe`. FAISS counts in `indexIVF_stats` how many stored vectors it compared, and the last column divides that by the number of queries."
    }
  ],
  "output": "ana@lab:~/emb$ python ivf.py\nadd before train: Error in virtual void faiss::IndexIVFFlat::add_core(faiss::idx_t, const float*, const faiss::idx_t*, const faiss::idx_t*, void*) at /project/faiss/IndexIVFFlat.cpp:66: Error: 'is_trained' failed\nk-means into 1024 cells, then add: 10.1 s\nvectors per cell: smallest 1, median 60, largest 558\nnprobe recall@10  per query  compared\n     1     0.749   0.054 ms       206\n     2     0.931   0.066 ms       302\n     4     0.990   0.100 ms       515\n     8     0.998   0.132 ms       982\n    16     0.999   0.219 ms     1,930\n    32     1.000   0.402 ms     3,742\n    64     1.000   0.761 ms     7,203"
}
```

**The index refused the vectors before it was trained.** It has nowhere to file them until the
centres exist, and `train` is what finds them: k-means over example vectors, here the collection
itself, 10.1 s on four cores including the add. An index that needs training needs data before it
can start, which is the first practical difference from the graph in the next section.

The cells are not equal. k-means puts the centres where the vectors are, but the smallest cell
holds 1 vector, the median 60 and the largest 558. A query that lands in a dense region searches
big cells, which is why the average number compared at `nprobe` 1 is 206 rather than 60.

## The dial is nprobe

**With one cell, recall was 0.749.** Searching 206 vectors instead of 100,000 found three
quarters of the true neighbours in 0.054 ms. Four cells reached 0.990 while comparing 515 vectors
in 0.100 ms, against 2.492 ms for exact search. Past that, each doubling of `nprobe` roughly
doubles the vectors compared and the time, for less and less recall: 64 cells, 7,203 vectors,
1.000.

The misses at small `nprobe` have one cause, and the figure draws it. **A cell has borders, and a
query near a border has neighbours on the other side.** The nearest centre decides which cell is
searched, not where the nearest vectors are.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" aria-label=\"A plane divided into seven cells, each around a centre point, with vectors scattered as small dots. A query sits near the border between two cells. Its nearest centre is on the left, so with nprobe 1 only the left cell is searched; two of its three true nearest neighbours lie just across the border in the right-hand cell, and are found only when nprobe 2 adds that cell.\"><defs><marker id=\"cellsen-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M20.0 20.0 L171.4 20.0 L186.1 122.5 L127.7 178.3 L20.0 165.6 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M171.4 20.0 L340.0 20.0 L301.8 153.7 L186.1 122.5 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M340.0 20.0 L470.0 20.0 L470.0 194.7 L414.7 203.5 L302.7 155.5 L301.8 153.7 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M210.1 350.0 L20.0 350.0 L20.0 165.6 L127.7 178.3 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M218.2 350.0 L210.1 350.0 L127.7 178.3 L186.1 122.5 L301.8 153.7 L302.7 155.5 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><path d=\"M333.3 350.0 L218.2 350.0 L302.7 155.5 L414.7 203.5 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"var(--scan)\" stroke-dasharray=\"6 4\"></path><path d=\"M470.0 194.7 L470.0 350.0 L333.3 350.0 L414.7 203.5 Z\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"445.1\" cy=\"33.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"346.5\" cy=\"79\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"454.1\" cy=\"35.2\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"408.2\" cy=\"241.2\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"398.7\" cy=\"339.9\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"133.1\" cy=\"134.8\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"334.5\" cy=\"117\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"143.2\" cy=\"100.9\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"398.9\" cy=\"301.1\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"373\" cy=\"99.3\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"427.7\" cy=\"188.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"129.5\" cy=\"171.2\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"210.5\" cy=\"54.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"272.8\" cy=\"141.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"274.9\" cy=\"318.4\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"307.6\" cy=\"155.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"401.3\" cy=\"338.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"240.8\" cy=\"323\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"38.1\" cy=\"73.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"104\" cy=\"320.8\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"153.2\" cy=\"183.4\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"411.4\" cy=\"61\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"80\" cy=\"44.7\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"231.5\" cy=\"290.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"268.6\" cy=\"154.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"245.9\" cy=\"85.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"437.7\" cy=\"139.7\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"131.2\" cy=\"126.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"384.7\" cy=\"128.7\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"419.1\" cy=\"134.2\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"219.9\" cy=\"53\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"420.2\" cy=\"276.8\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"234\" cy=\"65.8\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"241.8\" cy=\"146.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"391.2\" cy=\"317.7\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"348.7\" cy=\"119\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"47.8\" cy=\"307.1\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"436.1\" cy=\"79.1\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"245\" cy=\"179.1\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"449.9\" cy=\"43.3\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"56.5\" cy=\"291.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"274.9\" cy=\"173.3\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"364.4\" cy=\"213.9\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"327.7\" cy=\"109.2\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"66.5\" cy=\"32.8\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"173.2\" cy=\"231\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"193.3\" cy=\"137.7\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"296\" cy=\"248.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"286\" cy=\"126.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"383.3\" cy=\"278.2\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"36.5\" cy=\"237.4\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"179.7\" cy=\"150.4\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"137.3\" cy=\"335.7\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"172.3\" cy=\"313\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"324.3\" cy=\"127.6\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"167\" cy=\"217.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"331.9\" cy=\"135.4\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"55.4\" cy=\"83.4\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"400.1\" cy=\"255.9\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"76.6\" cy=\"288.9\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"277.6\" cy=\"133.8\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"414.4\" cy=\"69.9\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"72.2\" cy=\"136.5\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"347.2\" cy=\"199.8\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"238.2\" cy=\"311.1\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"199.4\" cy=\"274.3\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"32\" cy=\"272.7\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"268\" cy=\"203\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"268\" cy=\"203\" r=\"7\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><circle cx=\"290\" cy=\"226\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"290\" cy=\"226\" r=\"7\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><circle cx=\"297\" cy=\"205\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"297\" cy=\"205\" r=\"7\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><path d=\"M104 84 L116 96 M104 96 L116 84\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M244 64 L256 76 M244 76 L256 64\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M384 104 L396 116 M384 116 L396 104\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M84 254 L96 266 M84 266 L96 254\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M209 194 L221 206 M209 206 L221 194\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M324 244 L336 256 M324 256 L336 244\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M414 294 L426 306 M414 306 L426 294\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M277 206 L285 214 L277 222 L269 214 Z\" stroke=\"none\" stroke-width=\"0\" fill=\"var(--amber)\"></path><path d=\"M277 214 L215 200\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"120\" y=\"330\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nprobe 1 searches this cell</text><path d=\"M178 318 L198 232\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#cellsen-ah0)\"></path><text x=\"460\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nprobe 2 adds this one</text><path d=\"M400 206 L360 236\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#cellsen-ah0)\"></path><path d=\"M489 44 L501 56 M489 56 L501 44\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"513\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cell centre</text><circle cx=\"495\" cy=\"80\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"513\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a stored vector</text><path d=\"M495 102 L503 110 L495 118 L487 110 Z\" stroke=\"none\" stroke-width=\"0\" fill=\"var(--amber)\"></path><text x=\"513\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the query</text><circle cx=\"495\" cy=\"140\" r=\"2.6\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"495\" cy=\"140\" r=\"7\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"513\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">its 3 true nearest</text></svg>", "caption": "IVF searches the cells whose centres are nearest the query, not the cells that hold its nearest vectors. Near a border the two differ, which is where the misses at nprobe 1 come from."}
```

## Without structure it fails

The section on exact search promised a measurement of random vectors. `uniform.py` builds the same
index over 100,000 uniformly random unit vectors:

```python
import faiss
import numpy as np

rng = np.random.default_rng(15)
def uniform(n):
    v = rng.normal(size=(n, 384))
    return (v / np.linalg.norm(v, axis=1, keepdims=True)).astype("float32")
X, Q = uniform(100_000), uniform(1_000)

exact = faiss.IndexFlatIP(384)
exact.add(X)
scores, truth = exact.search(Q, 10)
print(f"best score per query, median: {np.median(scores[:, 0]):.3f}")

ivf = faiss.IndexIVFFlat(faiss.IndexFlatIP(384), 384, 1024, faiss.METRIC_INNER_PRODUCT)
ivf.train(X)
ivf.add(X)
for nprobe in (1, 8, 64):
    ivf.nprobe = nprobe
    _, I = ivf.search(Q, 10)
    r = np.mean([len(set(a) & set(b)) / 10 for a, b in zip(I, truth)])
    print(f"nprobe {nprobe:>2}: recall@10 {r:.3f}")
```

```
ana@lab:~/emb$ python uniform.py
best score per query, median: 0.219
nprobe  1: recall@10 0.012
nprobe  8: recall@10 0.055
nprobe 64: recall@10 0.241
```

**With 64 of 1,024 cells searched, recall was 0.241.** Exact search's best match scored a median
of 0.219: every vector is nearly as far from the query as every other, so the cells cannot gather
neighbours together, because there are no neighbourhoods. Measured on vectors like these, every
approximate index looks broken. Measured on embeddings, the same index reached 0.990 at four cells.

## What training commits you to

The centres are fixed when the index is trained. Every vector added later is filed under one of
the old centres, whether or not it resembles what the index was trained on. If the collection
drifts, as lesson 6's week of subscription messages did, the new vectors pile into a few cells
that were drawn for something else, those cells grow, and searching them gets slower. The repair
is to train again, which means rebuilding the index.

pgvector's `ivfflat` is the same index. Its `lists` is `nlist` and its `ivfflat.probes` is
`nprobe`, with a default of 1; its documentation suggests starting from `lists` as the row count
divided by 1,000, for up to a million rows, and `probes` as the square root of `lists`, and
building the index after the table holds its data, so that the training sees it.
