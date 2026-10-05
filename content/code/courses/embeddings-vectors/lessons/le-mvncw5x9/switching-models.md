---
title: Switching models
version: 1
---

Sooner or later a better or cheaper model appears, and the stored vectors were made by the old one.
The tempting plan is to embed new documents with the new model and leave the old vectors where
they are, since both are lists of numbers and the dimensions may even match. **That plan returns
nonsense, and when the dimensions match it does so without an error.** Vectors from two models
cannot be compared, and changing models means computing every stored vector again.

Lesson 1 stated this. `switch.py` measures it, with a trick that makes the two models as alike as
two models can be. Model B is model A with every vector rotated by the same random rotation in 384
dimensions. Lesson 2 shows that a rotation changes no dot product between two rotated vectors, so B
is exactly as good a model as A. What it is not is the same coordinate system.

```schooling-example
{
  "language": "python",
  "file": "switch.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\nfrom wordllama import WordLlama\n\nhelp = [json.loads(l) for l in open(\"data/help.jsonl\")]\nqueries = [json.loads(l) for l in open(\"data/queries.jsonl\")]\nids = [h[\"id\"] for h in help]\nD = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])\nQ = embed([q[\"text\"] for q in queries])",
      "note": "Model A is all-MiniLM-L6-v2: the 40 articles and the 24 questions, embedded."
    },
    {
      "code": "rng = np.random.default_rng(0)\nR, _ = np.linalg.qr(rng.normal(size=(384, 384)))\nD2, Q2 = D @ R, Q @ R",
      "note": "Model B is A turned by a random rotation of the 384-dimension space, the same one for every vector. QR of a random matrix gives a rotation."
    },
    {
      "code": "def top1(Q, D):\n    best = (Q @ D.T).argmax(axis=1)\n    return sum(ids[b] in q[\"relevant\"] for b, q in zip(best, queries))\n\nprint(\"A queries, A articles:\", top1(Q, D), \"/ 24\")\nprint(\"B queries, B articles:\", top1(Q2, D2), \"/ 24\")\nprint(\"B queries, A articles:\", top1(Q2, D), \"/ 24\")",
      "note": "Count the questions whose best article is a right one, for each model on its own and for B's questions against A's articles."
    },
    {
      "code": "for name, X in ((\"A against A\", Q @ D.T), (\"B against A\", Q2 @ D.T)):\n    print(f\"{name}: scores from {X.min():.3f} to {X.max():.3f}\")",
      "note": "The lowest and highest score among all question and article pairs, matched and mixed."
    },
    {
      "code": "wl = WordLlama.load()\ntry:\n    wl.embed([\"how do I get my money back\"], norm=True) @ D.T\nexcept ValueError as e:\n    print(\"ValueError:\", e)",
      "note": "A real second model with a different dimension, multiplied against MiniLM's articles."
    }
  ]
}
```

```
ana@lab:~/emb$ python switch.py
A queries, A articles: 19 / 24
B queries, B articles: 19 / 24
B queries, A articles: 1 / 24
A against A: scores from -0.175 to 0.686
B against A: scores from -0.151 to 0.210
ValueError: matmul: Input operand 1 has a mismatch in its core dimension 0, with gufunc signature (n?,k),(k,m?)->(n?,m?) (size 384 is different from 256)
```

**Each model on its own finds the right article first for 19 of the 24 questions.** Mixed, B's
questions against A's articles, it finds 1, about what picking one of the 40 articles at random
would give. The scores say why. A against A runs up to 0.686, the right article standing well clear of
the rest; B against A stays between −0.151 and 0.210 for every pair, a band of noise with nothing
standing out.

Two real models are further apart than a rotation, not closer: they were trained on different data
and nothing ties one coordinate system to the other. The rotation is the most favourable case, and
it still fails.

**The last line is the lucky failure.** WordLlama's 256 numbers cannot be multiplied with MiniLM's
384, so NumPy refuses with a `ValueError`. Two models with the same dimension give no such refusal.
A switch from one 1536-dimension model to another, with old and new vectors in one collection,
returns results, a score for each, and a ranking that looks like every other ranking. Only a
measurement against relevance judgements, like lesson 3's, would show that it is wrong.

## Record the model beside the vector

The defence is a fact stored with the data: **which model, and which version of it, produced each
vector.** A collection holds the vectors of one model, its name is written down where the search
code reads it, and the query is embedded with that same model. Lesson 11 builds a small store that
keeps exactly that.

## A migration that never mixes them

Moving a live search to a new model takes four steps, and the order is what keeps every query
answered by one model at a time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 740 300\" role=\"img\" aria-label=\"A grid of four steps in time, left to right, for two collections. Step 1, dual-write: the old collection, model A, takes writes and serves reads; the new collection, model B, takes writes. Step 2, backfill: the same, and the new collection is also filled with every old document re-embedded. Step 3, switch reads: the new collection serves reads; both still take writes. Step 4, delete old: the old collection is gone and the new one takes writes and serves reads.\"><defs><marker id=\"migen-ah0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M170 22 L728 22\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#migen-ah0)\"></path><text x=\"728\" y=\"10\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time</text><text x=\"236\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">1  dual-write</text><text x=\"378\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">2  backfill</text><text x=\"520\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">3  switch reads</text><text x=\"662\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">4  delete old</text><text x=\"16\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">old collection</text><text x=\"16\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">model A</text><text x=\"16\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">new collection</text><text x=\"16\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">model B</text><rect x=\"170\" y=\"80\" width=\"132\" height=\"66\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"236\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">writes + reads</text><rect x=\"312\" y=\"80\" width=\"132\" height=\"66\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"378\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">writes + reads</text><rect x=\"454\" y=\"80\" width=\"132\" height=\"66\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">writes</text><rect x=\"596\" y=\"80\" width=\"132\" height=\"66\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"662\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">deleted</text><rect x=\"170\" y=\"170\" width=\"132\" height=\"66\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"236\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">writes</text><rect x=\"312\" y=\"170\" width=\"132\" height=\"66\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"378\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">writes</text><text x=\"378\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">+ backfill</text><rect x=\"454\" y=\"170\" width=\"132\" height=\"66\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"520\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">writes + reads</text><rect x=\"596\" y=\"170\" width=\"132\" height=\"66\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"662\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">writes + reads</text><text x=\"370\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">every read is answered by one collection, and so by one model</text></svg>", "caption": "The four steps of a model migration. The highlighted cell in each step is the collection that answers searches: the old one until step 3, the new one from then on, never both."}
```

1. **Dual-write.** Create a second collection for the new model. From now on every new or edited
   document is embedded with both models and written to both collections. Reads still go to the
   old one.
2. **Backfill.** Re-embed every existing document with the new model into the new collection, in
   batches, at whatever pace the provider's rate limit and the budget allow. Lesson 18 prices this
   step, and it is usually the expensive one.
3. **Switch reads.** First measure the new collection on the same relevance judgements as the old
   one, then point the search at it: questions embedded with the new model, searched in the new
   collection. Keep writing to both for a while, so that switching back is one change.
4. **Delete the old collection** once nobody needs to switch back.

The two collections exist side by side from step 1 to step 4, so storage doubles for that time,
which lesson 18 also counts. A query never meets a vector from the other model, because the read
path names one collection and that collection holds one model.
