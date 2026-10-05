---
title: Building the index
version: 1
---

A search by meaning has two halves that run at different times, and keeping them apart is most of
the design:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Two rows. Ahead of time, once per article: the 40 help articles are embedded with all-MiniLM-L6-v2 and stored as index.npy, a matrix with one row per article, beside ids.json, which says which article each row is. For every question: the question is embedded with the same model, multiplied by the stored matrix to give one score per article, sorted, and the top k row numbers are turned back into articles through ids.json.\"><defs><marker id=\"pipeen-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"pipeen-ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">ahead of time, once per article</text><text x=\"20\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">for every question</text><rect x=\"20\" y=\"42\" width=\"130\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">help.jsonl</text><text x=\"85\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">40 articles</text><path d=\"M150 67 L196 67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"198\" y=\"42\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"273\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">embed()</text><text x=\"273\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">all-MiniLM-L6-v2</text><path d=\"M348 67 L394 67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"396\" y=\"34\" width=\"150\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"471\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">index.npy</text><text x=\"471\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one row per article</text><rect x=\"396\" y=\"80\" width=\"150\" height=\"40\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"471\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ids.json</text><text x=\"471\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">which row is which</text><rect x=\"20\" y=\"220\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a question</text><path d=\"M130 242 L156 242\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"158\" y=\"220\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"213\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">embed()</text><text x=\"213\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">same model</text><path d=\"M268 242 L294 242\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"296\" y=\"220\" width=\"110\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"351\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">D @ q</text><text x=\"351\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">40 scores</text><path d=\"M406 242 L432 242\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"434\" y=\"220\" width=\"120\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"494\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">argsort</text><text x=\"494\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sort, keep top k</text><path d=\"M554 242 L580 242\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah0)\"></path><rect x=\"582\" y=\"220\" width=\"120\" height=\"44\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"642\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ids[i]</text><text x=\"642\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">row → article</text><path d=\"M546 46 C620 46 380 150 351 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah1)\" stroke-dasharray=\"5 4\"></path><path d=\"M546 100 C690 100 680 150 642 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pipeen-ah1)\" stroke-dasharray=\"5 4\"></path></svg>", "caption": "The slow half runs once per article and is stored; the fast half runs for every question and reads what was stored. The matrix and the ids are two files that only work together."}
```

**The documents are embedded once, ahead of time.** Embedding is the slow, expensive step, and an
article that has not changed has the same vector tomorrow (lesson 1). So the vectors are computed
when an article is written or edited, and stored. Only the question is embedded at search time.

```schooling-example
{
  "language": "python",
  "file": "index.py",
  "parts": [
    {
      "code": "import json\nimport time\nimport numpy as np\nfrom minilm import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\ntexts = [h[\"title\"] + \". \" + h[\"body\"] for h in help]",
      "note": "Each article is embedded as its title and body joined, as in lesson 1."
    },
    {
      "code": "start = time.perf_counter()\nD = embed(texts)\nprint(f\"embedded {len(texts)} articles in {time.perf_counter() - start:.2f} s\")",
      "note": "Embed all 40 in one call, and time it."
    },
    {
      "code": "np.save(\"index.npy\", D)\njson.dump([h[\"id\"] for h in help], open(\"ids.json\", \"w\"))\nprint(D.shape, D.dtype)",
      "note": "Save the matrix as a NumPy file and, beside it, the ids in the same order."
    }
  ]
}
```

```
ana@lab:~/emb$ python index.py
embedded 40 articles in 0.77 s
(40, 384) float32
ana@lab:~/emb$ ls -l index.npy ids.json
-rw-r--r-- 1 ana ana   280 Oct  5 14:20 ids.json
-rw-r--r-- 1 ana ana 61568 Oct  5 14:20 index.npy
```

The whole help centre took 0.77 seconds on this machine. That is nothing for 40 articles and it is
not nothing for four million, which is why the expensive half belongs offline, where it can be
batched and retried without a customer waiting (lesson 7 sends it to a provider in batches).

## Two files that must stay together

`index.npy` is the 40 × 384 matrix of float32 numbers: 40 × 384 × 4 = 61,440 bytes, plus the 128
bytes of NumPy's header, which makes the 61,568 that `ls` printed. Row 0 is the first article's
vector, row 1 the second's, and so on, but **the matrix does not know which article any row
belongs to**. That is what `ids.json` is for. A search returns row numbers, and the ids turn them
back into articles.

So the two files are written together, in the same order, and replaced together. A rebuild that
writes a new matrix and forgets the ids leaves every search returning the wrong article with a
perfectly good score. Two more facts belong beside them, even in a project this small:

- **which model made the vectors**, because a question embedded by any other model cannot be
  compared with them (lesson 1, *What an embedding is not*);
- **whether they are normalised**. all-MiniLM-L6-v2's are already, so the plain dot product is
  the cosine. With a model whose vectors are not, this is where you divide by the length, once
  (lesson 2).

A vector database keeps the vector, the id and anything else about the document in one record, so
they cannot drift apart. Lesson 11 shows what else it adds; two files are enough to see the idea.
