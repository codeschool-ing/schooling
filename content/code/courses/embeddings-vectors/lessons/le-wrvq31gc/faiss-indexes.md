---
title: Index names you will meet
version: 1
---

FAISS names its indexes with short strings that the documentation of other databases borrows, so
they are worth recognising before lesson 15 explains how each one works. `faiss.index_factory`
builds an index from such a string, and this program builds four of them and compares them with
the exact answer.

The vectors need explaining first. **These are not 20,000 embedded texts.** The course's own texts
give 310 real all-MiniLM-L6-v2 vectors, and each of the 20,000 is one of them with a little random
noise added, renormalised. That keeps the clusters real vectors have, which uniform random vectors
would not, and it is cheap to make. The 100 queries are more noisy copies.

```schooling-example
{
  "language": "python",
  "file": "factory.py",
  "parts": [
    {
      "code": "import json\nimport faiss\nimport numpy as np\nfrom minilm import embed\n\ntexts = [json.loads(line)[k] for f, k in [(\"help\", \"body\"), (\"tickets\", \"text\"),\n         (\"books\", \"blurb\"), (\"inbox\", \"text\"), (\"week2\", \"text\")]\n         for line in open(f\"data/{f}.jsonl\")]\nbase = embed(texts)\nrng = np.random.default_rng(15)\ndef copies(n):\n    v = base[rng.integers(len(base), size=n)] + rng.normal(scale=0.04, size=(n, 384))\n    return (v / np.linalg.norm(v, axis=1, keepdims=True)).astype(\"float32\")\nX, Q = copies(20000), copies(100)\nprint(len(base), \"real vectors,\", len(X), \"noisy copies,\", len(Q), \"queries\")",
      "note": "310 real vectors from the course's texts, each copied many times with a little random noise and renormalised: 20,000 vectors that cluster the way real ones do, and 100 more as queries."
    },
    {
      "code": "exact = faiss.IndexFlatIP(384)\nexact.add(X)\n_, truth = exact.search(Q, 10)\nfaiss.write_index(exact, \"random.faiss\")",
      "note": "The exact answer: a flat index searched for the 10 nearest of each query. It is also written to `random.faiss` for later."
    },
    {
      "code": "for spec in (\"Flat\", \"HNSW32\", \"IVF64,Flat\", \"IVF64,PQ16\"):\n    index = faiss.index_factory(384, spec, faiss.METRIC_INNER_PRODUCT)\n    needs = not index.is_trained\n    index.train(X)\n    index.add(X)\n    _, I = index.search(Q, 10)\n    recall = np.mean([len(set(a) & set(b)) / 10 for a, b in zip(I, truth)])\n    size = faiss.serialize_index(index).nbytes\n    print(f\"{spec:11} needs training: {str(needs):5}  {size:>11,} bytes  recall@10 {recall:.3f}\")",
      "note": "Four indexes from their factory strings, all comparing by inner product. Each is trained if it needs to be, filled, searched, and measured: its size once serialised, and how many of the exact 10 it found."
    }
  ],
  "output": "ana@lab:~/emb$ python factory.py\n310 real vectors, 20000 noisy copies, 100 queries\nFlat        needs training: False   30,720,045 bytes  recall@10 1.000\nHNSW32      needs training: False   36,162,530 bytes  recall@10 1.000\nIVF64,Flat  needs training: True    30,978,955 bytes  recall@10 0.993\nIVF64,PQ16  needs training: True       972,212 bytes  recall@10 0.210"
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two bar charts side by side for four FAISS indexes built over the same 20,000 vectors. Size in megabytes: Flat 30.72, HNSW32 36.16, IVF64,Flat 30.98, IVF64,PQ16 0.97. Recall at 10 against the exact answer: Flat 1.000, HNSW32 1.000, IVF64,Flat 0.993, IVF64,PQ16 0.210.\"><text x=\"250\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">size once written (MB)</text><text x=\"570\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">recall@10 against the exact answer</text><text x=\"110\" y=\"72\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">Flat</text><rect x=\"125\" y=\"60\" width=\"192\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"323\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">30.72</text><rect x=\"450\" y=\"60\" width=\"220\" height=\"24\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"450\" y=\"60\" width=\"220\" height=\"24\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"676\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1.000</text><text x=\"110\" y=\"114\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">HNSW32</text><rect x=\"125\" y=\"102\" width=\"226\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"357\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">36.16</text><rect x=\"450\" y=\"102\" width=\"220\" height=\"24\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"450\" y=\"102\" width=\"220\" height=\"24\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"676\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1.000</text><text x=\"110\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">IVF64,Flat</text><text x=\"110\" y=\"171\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">needs training</text><rect x=\"125\" y=\"144\" width=\"193.6\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"324.6\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">30.98</text><rect x=\"450\" y=\"144\" width=\"220\" height=\"24\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"450\" y=\"144\" width=\"218.5\" height=\"24\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"676\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0.993</text><text x=\"110\" y=\"198\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">IVF64,PQ16</text><text x=\"110\" y=\"213\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">needs training</text><rect x=\"125\" y=\"186\" width=\"6.1\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"137.1\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0.97</text><rect x=\"450\" y=\"186\" width=\"220\" height=\"24\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"450\" y=\"186\" width=\"46.2\" height=\"24\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"676\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0.210</text></svg>", "caption": "Four FAISS indexes over the same 20,000 noisy copies of real vectors, measured by factory.py. Compression bought a thirtieth of the size and cost most of the recall on this tightly clustered data."}
```

## Reading the names

**`Flat`** keeps every vector as it is and compares the query with all of them. It is the exact
answer, recall 1.000 by definition, and it needs no training. Its 30,720,045 bytes are 20,000
vectors of 1,536 bytes and a 45-byte header: nothing but the vectors.

**`HNSW32`** builds a graph in which every vector is linked to some of its neighbours, and a search
walks the graph instead of reading everything; the 32 sets how many links each vector gets. It found all ten of the exact
neighbours for every query on this data, and it is the largest of the four, at 36,162,530 bytes:
the vectors plus the links. Lesson 15 builds the graph.

**`IVF64,Flat`** splits the space into 64 cells and searches only the cell nearest the query.
Finding the cells needs a clustering of example vectors first, which is the **training** in the
second column: an index that needs training cannot take a vector until it has seen data like the
data it will hold. Recall 0.993, because a few true neighbours sat in a cell next door.

**`IVF64,PQ16`** uses the same cells and compresses every vector to 16 bytes instead of 1,536, by
product quantisation. The whole index is 972,212 bytes, about a thirtieth of `Flat`. Its recall here,
0.210, is the price: the noisy copies of one text sit so close together that 16 bytes cannot keep
them in the right order. On vectors less tightly packed the loss is smaller, and lesson 15 measures
it properly.

**These recalls belong to this data and to FAISS's default search settings**, which visit one cell
of an IVF index and keep 16 candidates in an HNSW search. Every one of the approximate indexes has a
dial that trades time for recall, which is the subject of lesson 15, and the bytes are lesson 18's.
Here the point is narrower: when a database's documentation says it uses HNSW, IVF or PQ, you now
know which of these four ideas it means.
