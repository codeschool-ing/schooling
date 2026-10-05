---
title: M, ef_construction and ef
version: 1
---

HNSW has three settings, and the most common mistake is to treat them as one dial labelled
*quality*. **Two of them are fixed when the index is built and one is chosen per query**, and they
cost different things:

- `M` is how many links each vector gets on the upper layers; layer 0 gets twice as many. It sets
  the size of the graph and how well connected it is.
- `ef_construction` is the length of the candidate list while inserting, when each new vector
  searches for the neighbours it will link to. It sets how good those links are.
- `ef` is the length of the candidate list at query time, the list of the last section. It can
  change between one query and the next.

## The two you pay for once

`params.py` builds four hnswlib indexes over the same 100,000 vectors and searches each with the
same `ef` of 40:

```schooling-example
{
  "language": "python",
  "file": "params.py",
  "parts": [
    {
      "code": "import os\nimport time\nimport hnswlib\nfrom bench import X, Q, recall\n\nprint(f\"{'M':>2} {'ef_construction':>15} {'build':>7} {'bytes/vector':>12} {'recall@10':>9} {'per query':>10}\")\nfor M, ef_construction in ((8, 200), (16, 200), (32, 200), (16, 40)):\n    index = hnswlib.Index(space=\"ip\", dim=384)\n    index.init_index(max_elements=len(X), M=M, ef_construction=ef_construction)\n    start = time.perf_counter()\n    index.add_items(X)\n    built = time.perf_counter() - start",
      "note": "Four hnswlib indexes over the same vectors: three values of `M` with the same `ef_construction`, and one built with a shorter list. `add_items` builds the graph on all four cores."
    },
    {
      "code": "    index.save_index(f\"m{M}-{ef_construction}.bin\")\n    size = os.path.getsize(f\"m{M}-{ef_construction}.bin\") / len(X)",
      "note": "The file on disk, divided by the number of vectors, is the size of the index per vector: the vector itself plus its links."
    },
    {
      "code": "    index.set_ef(40)\n    index.set_num_threads(1)\n    start = time.perf_counter()\n    I, _ = index.knn_query(Q, k=10)\n    ms = (time.perf_counter() - start) * 1000 / len(Q)\n    print(f\"{M:>2} {ef_construction:>15} {built:>5.1f} s {size:>12,.0f} {recall(I):>9.3f} {ms:>7.3f} ms\")",
      "note": "Every index is searched with the same `ef` of 40 on one core, so the rows differ only in how they were built."
    }
  ],
  "output": "ana@lab:~/emb$ python params.py\n M ef_construction   build bytes/vector recall@10  per query\n 8             200   8.3 s        1,621     0.887   0.125 ms\n16             200  12.1 s        1,684     0.938   0.138 ms\n32             200  15.1 s        1,812     0.963   0.134 ms\n16              40   2.5 s        1,684     0.842   0.092 ms"
}
```

**More links bought recall.** From `M` 8 to 16 to 32, recall@10 went from 0.887 to 0.938 to 0.963
at the same `ef`, because a better-connected graph has more routes into each neighbourhood. The
build took longer, 8.3 s to 15.1 s, and the file grew from 1,621 to 1,812 bytes a vector. The
growth is the links: hnswlib stores each one as a 4-byte number, and going from 16 to 32 adds 32
links on layer 0, which is the 128 bytes a vector between those two rows. The query times barely
moved in this run, and on a machine shared with other work their order means nothing.

**A careless build cannot be repaired by searching harder.** The last row has the same `M` of 16
and an `ef_construction` of 40 instead of 200. It built in 2.5 s instead of 12.1 s, and its file is
the same 1,684 bytes a vector, because the number of links did not change; what changed is which
vectors they point to. With links chosen from a shorter list of candidates, recall at `ef` 40 fell
from 0.938 to 0.842. The graph is what it is until it is rebuilt.

## The one you choose per query

`ef_sweep.py` loads the index with `M` 16 and `ef_construction` 200 and turns `ef`:

```schooling-example
{
  "language": "python",
  "file": "ef_sweep.py",
  "parts": [
    {
      "code": "import time\nimport hnswlib\nfrom bench import X, Q, recall\n\nindex = hnswlib.Index(space=\"ip\", dim=384)\nindex.load_index(\"m16-200.bin\")\nindex.set_num_threads(1)\nprint(f\"{'ef':>4} {'recall@10':>9} {'per query':>10}\")\nfor ef in (10, 20, 40, 80, 160, 320):\n    index.set_ef(ef)\n    start = time.perf_counter()\n    I, _ = index.knn_query(Q, k=10)\n    ms = (time.perf_counter() - start) * 1000 / len(Q)\n    print(f\"{ef:>4} {recall(I):>9.3f} {ms:>7.3f} ms\")",
      "note": "The index `params.py` saved with `M` 16 and `ef_construction` 200, loaded instead of built again, and searched on one core at six values of `ef`."
    }
  ],
  "output": "ana@lab:~/emb$ python ef_sweep.py\n  ef recall@10  per query\n  10     0.772   0.076 ms\n  20     0.880   0.093 ms\n  40     0.938   0.141 ms\n  80     0.968   0.167 ms\n 160     0.993   0.289 ms\n 320     1.000   0.560 ms"
}
```

**The dial runs from 0.772 at `ef` 10 to 1.000 at 320**, and the time per query from 0.076 ms to
0.560 ms. At 320 the index returned exactly what exact search did for all 1,000 queries, in under
a quarter of exact search's 2.492 ms. hnswlib's own default is 10, the cheapest row of this table.
`ef` below `k` is a case of its own, and lesson 16 shows how two libraries handle it differently.

The figure puts this curve beside IVF's from the last section, with recall up and time per query
along a scale where each step is a doubling.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" aria-label=\"A chart of recall@10 against milliseconds per query on a doubling scale, for the same 1,000 queries over 100,000 vectors. IVF with 1,024 cells rises from 0.749 at nprobe 1 (0.054 ms) to 0.99 at nprobe 4 (0.1 ms) and 1.0 from nprobe 32. HNSW with M 16 rises from 0.772 at ef 10 (0.076 ms) to 0.993 at ef 160 (0.289 ms) and 1.0 at ef 320 (0.56 ms). Exact search sits at recall 1 and 2.492 ms. Both curves climb quickly and then flatten.\"><path d=\"M80 330 L690 330\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70\" y=\"330\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.7</text><path d=\"M80 233.3 L690 233.3\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70\" y=\"233.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.8</text><path d=\"M80 136.7 L690 136.7\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70\" y=\"136.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.9</text><path d=\"M80 40 L690 40\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.0</text><path d=\"M80 330 L690 330\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 330 L80 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M139.1 330 L139.1 335\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"139.1\" y=\"347\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0625</text><path d=\"M230.9 330 L230.9 335\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"230.9\" y=\"347\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.125</text><path d=\"M322.7 330 L322.7 335\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"322.7\" y=\"347\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.25</text><path d=\"M414.6 330 L414.6 335\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"414.6\" y=\"347\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><path d=\"M506.4 330 L506.4 335\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"506.4\" y=\"347\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><path d=\"M598.2 330 L598.2 335\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"598.2\" y=\"347\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><path d=\"M690 330 L690 335\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"690\" y=\"347\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"385\" y=\"368\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">milliseconds per query, one core (each step doubles)</text><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">recall@10</text><path d=\"M119.8 282.6 L146.3 106.7 L201.4 49.7 L238.1 41.9 L305.2 41.0 L385.7 40.0 L470.2 40.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><rect x=\"115.3\" y=\"278.1\" width=\"9\" height=\"9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"113.8\" y=\"270.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1</text><rect x=\"141.8\" y=\"102.2\" width=\"9\" height=\"9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"140.3\" y=\"94.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2</text><rect x=\"196.9\" y=\"45.2\" width=\"9\" height=\"9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"195.4\" y=\"37.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">4</text><rect x=\"233.6\" y=\"37.4\" width=\"9\" height=\"9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"232.1\" y=\"29.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">8</text><rect x=\"300.7\" y=\"36.5\" width=\"9\" height=\"9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"299.2\" y=\"29\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">16</text><rect x=\"381.2\" y=\"35.5\" width=\"9\" height=\"9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"379.7\" y=\"28\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">32</text><rect x=\"465.7\" y=\"35.5\" width=\"9\" height=\"9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"464.2\" y=\"28\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">64</text><path d=\"M165.0 260.4 L191.8 156.0 L246.9 99.9 L269.3 70.9 L341.9 46.8 L429.6 40.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><circle cx=\"165\" cy=\"260.4\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></circle><text x=\"172\" y=\"274.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">10</text><circle cx=\"191.8\" cy=\"156\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></circle><text x=\"198.8\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">20</text><circle cx=\"246.9\" cy=\"99.9\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></circle><text x=\"253.9\" y=\"113.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">40</text><circle cx=\"269.3\" cy=\"70.9\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></circle><text x=\"276.3\" y=\"84.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">80</text><circle cx=\"341.9\" cy=\"46.8\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></circle><text x=\"348.9\" y=\"60.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">160</text><circle cx=\"429.6\" cy=\"40\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></circle><text x=\"436.6\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">320</text><circle cx=\"627.3\" cy=\"40\" r=\"5.5\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"627.3\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">exact 2.492</text><path d=\"M430 250 L460 250\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><rect x=\"440.5\" y=\"245.5\" width=\"9\" height=\"9\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"468\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">IVF, 1,024 cells: nprobe</text><path d=\"M430 276 L460 276\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><circle cx=\"445\" cy=\"276\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></circle><text x=\"468\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">HNSW, M 16: ef</text></svg>", "caption": "Recall against time for the same 1,000 queries, as ivf.py and ef_sweep.py measured them; the small numbers are nprobe and ef. Both indexes climb steeply and then flatten, and on these vectors IVF reached 0.99 sooner."}
```

**On this set, IVF won.** Four cells gave 0.990 in 0.100 ms; HNSW needed `ef` 160 for 0.993 in
0.289 ms. Do not carry that home as a rule. These vectors are blends of 334 real ones, a structure
that k-means cells capture unusually well, and on other data the order can reverse. What the curves
do show in general is the shape: recall climbs quickly and then flattens, so the last few
thousandths cost as much time as everything before them. HNSW is still the default most systems
choose, for reasons this chart cannot show: it needs no training, it takes vectors one at a time
for as long as the collection lives, and it has no cells to go stale when the data drifts.

## The same three in other places

Every library spells them its own way:

| | FAISS | hnswlib | pgvector |
|---|---|---|---|
| links per vector | `M`, in `IndexHNSWFlat(d, M)` | `M` | `m` |
| list while building | `efConstruction` | `ef_construction` | `ef_construction` |
| list while searching | `efSearch` | `ef`, via `set_ef` | `hnsw.ef_search` |
| cells | `nlist` | — | `lists` |
| cells searched | `nprobe` | — | `ivfflat.probes` |

pgvector reads the two search settings from the session, and an empty database shows their
defaults:

```
ana@lab:~/emb$ psql -c "CREATE EXTENSION vector" -c "SHOW hnsw.ef_search" -c "SHOW ivfflat.probes"
CREATE EXTENSION
 hnsw.ef_search 
----------------
 40
(1 row)

 ivfflat.probes 
----------------
 1
(1 row)
```

pgvector's documentation gives 16 for `m` and 64 for `ef_construction` when the `CREATE INDEX`
names neither. Both go in its `WITH (...)` clause, and both are decided for as long as the index
exists.
