---
title: Shrinking the vectors
version: 1
---

If size is dimensions times four bytes, there are two ways to make it smaller: **fewer numbers**,
or **fewer bytes per number**. The common assumption is that search gets worse in proportion to
what you take away, so that half the bytes costs half the quality. It does not, and the two ways
are not equal: measured on the same texts, one is nearly free over a long way and the other costs
at every step.

## Four forms of the same vectors

Lesson 8 met int8 and binary vectors as something a provider can return, and lesson 15 measured
FAISS's quantisers inside an index. Here they are side by side with plain truncation, on the
course's own texts:

```schooling-example
{
  "language": "python",
  "file": "shrink.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\nfrom wordllama import WordLlama\n\nrows = lambda f: [json.loads(l) for l in open(f\"data/{f}.jsonl\")]\nhelp, queries = rows(\"help\"), rows(\"queries\")\nids = [h[\"id\"] for h in help]\narticles = [h[\"title\"] + \". \" + h[\"body\"] for h in help]\nasked = [q[\"text\"] for q in queries]\nothers = [b[\"title\"] + \". \" + b[\"blurb\"] for b in rows(\"books\")] + [t[\"text\"] for t in rows(\"tickets\")]",
      "note": "The texts: the 40 articles, the 24 judged questions, and every book blurb and ticket, so that the neighbour comparison has many more rows than the questions alone."
    },
    {
      "code": "def forms(X):\n    yield \"float32\", X, X.nbytes\n    h = X.astype(np.float16)\n    yield \"float16\", h.astype(np.float32), h.nbytes\n    s = (np.abs(X).max(axis=1, keepdims=True) / 127).astype(np.float32)\n    q = np.round(X / s).astype(np.int8)\n    yield \"int8\", q * s, q.nbytes + s.nbytes\n    b = np.packbits(X > 0, axis=1)\n    yield \"binary\", np.where(X > 0, 1.0, -1.0), b.nbytes",
      "note": "Four ways to store the same vectors. Each yields what search would compare, and how many bytes it costs. int8 keeps one float32 scale per vector, and its bytes include it."
    },
    {
      "code": "def recall(D, Q):\n    tops = [[ids[i] for i in np.argsort(-(D @ q), kind=\"stable\")[:3]] for q in Q]\n    r1 = sum(t[0] in q[\"relevant\"] for t, q in zip(tops, queries))\n    r3 = sum(any(i in q[\"relevant\"] for i in t) for t, q in zip(tops, queries))\n    return r1, r3\n\ndef top10(E):\n    S = E @ E.T\n    np.fill_diagonal(S, -np.inf)\n    return np.argsort(-S, axis=1, kind=\"stable\")[:, :10]",
      "note": "Two measurements. `recall` is lesson 3's: of the 24 questions, how many find a right article first, and in the top three. `top10` lists every text's ten nearest neighbours among the others."
    },
    {
      "code": "def report(model, X, full):\n    exact = top10(full)\n    n = len(articles) + len(asked)\n    for form, E, size in forms(X):\n        r1, r3 = recall(E[:len(articles)], E[len(articles):n])\n        mine = top10(E)\n        kept = np.mean([len(set(a) & set(b)) / 10 for a, b in zip(mine, exact)])\n        print(f\"{model:14} {form:8} {size // len(X):5} B  r@1 {r1:2}/24  r@3 {r3:2}/24  \"\n              f\"top-10 kept {kept:.3f}\")",
      "note": "For each form, the recall and the share of each text's ten nearest neighbours that are still the neighbours the full-size float32 vectors gave."
    },
    {
      "code": "texts = articles + asked + others\nM = embed(texts)\nreport(\"minilm 384\", M, M)\nwl = WordLlama.load()\nW = wl.embed(texts, norm=True)\nreport(\"wordllama 256\", W, W)\nfor k in (128, 64):\n    Wk = W[:, :k] / np.linalg.norm(W[:, :k], axis=1, keepdims=True)\n    report(f\"wordllama {k}\", Wk, W)",
      "note": "MiniLM at full size, then WordLlama at 256 dimensions and cut to 128 and 64, renormalised. The truncated ones are compared against the full 256."
    }
  ]
}
```

```
ana@lab:~/emb$ python shrink.py
minilm 384     float32   1536 B  r@1 19/24  r@3 22/24  top-10 kept 1.000
minilm 384     float16    768 B  r@1 19/24  r@3 22/24  top-10 kept 1.000
minilm 384     int8       388 B  r@1 19/24  r@3 22/24  top-10 kept 0.995
minilm 384     binary      48 B  r@1 16/24  r@3 23/24  top-10 kept 0.705
wordllama 256  float32   1024 B  r@1 20/24  r@3 24/24  top-10 kept 1.000
wordllama 256  float16    512 B  r@1 20/24  r@3 24/24  top-10 kept 0.999
wordllama 256  int8       260 B  r@1 20/24  r@3 24/24  top-10 kept 0.995
wordllama 256  binary      32 B  r@1 15/24  r@3 21/24  top-10 kept 0.600
wordllama 128  float32    512 B  r@1 17/24  r@3 23/24  top-10 kept 0.772
wordllama 128  float16    256 B  r@1 17/24  r@3 23/24  top-10 kept 0.772
wordllama 128  int8       132 B  r@1 17/24  r@3 23/24  top-10 kept 0.773
wordllama 128  binary      16 B  r@1 13/24  r@3 19/24  top-10 kept 0.492
wordllama 64   float32    256 B  r@1 20/24  r@3 21/24  top-10 kept 0.642
wordllama 64   float16    128 B  r@1 20/24  r@3 21/24  top-10 kept 0.642
wordllama 64   int8        68 B  r@1 20/24  r@3 21/24  top-10 kept 0.643
wordllama 64   binary       8 B  r@1 11/24  r@3 20/24  top-10 kept 0.391
```

The program measures two things, and you need both. `r@1` and `r@3` are lesson 3's recall on the
24 judged questions: the number that matters, measured on a sample too small to show a small
change. `top-10 kept` is a finer instrument: for every text in the set (the articles, the questions, the 60 book
blurbs and the 150 tickets), how many of its ten nearest
neighbours under the full-size `float32` vectors are still among its ten nearest after the change.

## Fewer bytes per number

**float16 halves the size and changes nothing.** MiniLM at 768 bytes keeps 1.000 of its
neighbours, WordLlama at 512 keeps 0.999, and both answer the 24 questions exactly as before.

**int8 quarters it for half a percent.** 388 and 260 bytes, with the one `float32` scale each
vector keeps counted in, and 0.995 of the neighbours kept by both models. Neither model's answers
to the 24 questions moved.

**Binary is a thirty-second of the size and a different neighbourhood.** One bit per number, 48
bytes for MiniLM and 32 for WordLlama, keeps 0.705 and 0.600 of the neighbours. Yet MiniLM's `r@3`
went from 22/24 to 23/24 as binary. That is not binary being better: it is 24 questions being too
few to see a change in which nearly a third of the neighbours moved, and it is the reason the
program carries the second measure at all.

## Fewer numbers

WordLlama is trained so that its leading dimensions carry the most, which is what makes cutting it
short reasonable at all: take the first k, divide by the new length. Even so, **cutting to 128
dimensions keeps 0.772 of the neighbours, and 64 keeps 0.642**, against the full 256.

Now compare at equal size. WordLlama cut to 64 dimensions in `float32` is 256 bytes and keeps
0.642. WordLlama at its full 256 dimensions in `int8` is 260 bytes and keeps 0.995. **At the same
number of bytes, fewer bits per number beat fewer numbers** by a wide margin, on this model and
these texts. Truncation still has its use, because it is the only shrinking that works on a
system that stores nothing but `float32`, and that is the lab's pgvector: 0.6.0 has no smaller
type, so in Postgres here the only lever is the dimension.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" aria-label=\"A chart of bytes per vector, on a doubling scale from 8 to 2048, against the share of each text's ten nearest neighbours that stay the same. all-MiniLM-L6-v2 and WordLlama at 256 dimensions keep almost all their neighbours at float16 and int8 and drop to 0.705 and 0.600 as binary. WordLlama cut to 128 and 64 dimensions keeps only 0.772 and 0.642 even at float32, so at about 256 bytes an int8 vector of 256 dimensions keeps far more than a float32 vector of 64.\"><path d=\"M80 350 L690 350\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 350 L80 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 350 L80 355\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"80\" y=\"368\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><path d=\"M230 350 L230 355\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"230\" y=\"368\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">32</text><path d=\"M380 350 L380 355\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"380\" y=\"368\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">128</text><path d=\"M530 350 L530 355\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"530\" y=\"368\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">512</text><path d=\"M680 350 L680 355\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680\" y=\"368\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2048</text><path d=\"M75 328.6 L80 328.6\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70\" y=\"328.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.4</text><path d=\"M75 242.9 L80 242.9\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70\" y=\"242.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.6</text><path d=\"M75 157.1 L80 157.1\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70\" y=\"157.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.8</text><path d=\"M75 71.4 L80 71.4\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70\" y=\"71.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.0</text><text x=\"385\" y=\"392\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">bytes per vector</text><text x=\"84\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">top-10 neighbours kept</text><path d=\"M648.9 71.4 L573.9 71.4 L500.0 73.6 L273.9 197.9\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"648.9\" cy=\"71.4\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"648.9\" y=\"87.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">f32</text><circle cx=\"573.9\" cy=\"71.4\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"573.9\" y=\"87.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">f16</text><circle cx=\"500\" cy=\"73.6\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"500\" y=\"89.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">int8</text><circle cx=\"273.9\" cy=\"197.9\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"283.9\" y=\"197.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bin</text><path d=\"M605.0 71.4 L530.0 71.9 L456.7 73.6 L230.0 242.9\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"600\" y=\"66.4\" width=\"10\" height=\"10\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"57.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">f32</text><rect x=\"525\" y=\"66.9\" width=\"10\" height=\"10\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"57.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">f16</text><rect x=\"451.7\" y=\"68.6\" width=\"10\" height=\"10\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"456.7\" y=\"59.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">int8</text><rect x=\"225\" y=\"237.9\" width=\"10\" height=\"10\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"230\" y=\"228.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bin</text><path d=\"M530.0 169.1 L455.0 169.1 L383.3 168.7 L155.0 289.1\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"530\" cy=\"169.1\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.8\"></circle><circle cx=\"455\" cy=\"169.1\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.8\"></circle><circle cx=\"383.3\" cy=\"168.7\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.8\"></circle><circle cx=\"155\" cy=\"289.1\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.8\"></circle><path d=\"M455.0 224.9 L380.0 224.9 L311.6 224.4 L80.0 332.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"455\" cy=\"224.9\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\"></circle><circle cx=\"380\" cy=\"224.9\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\"></circle><circle cx=\"311.6\" cy=\"224.4\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\"></circle><circle cx=\"80\" cy=\"332.4\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\"></circle><circle cx=\"470\" cy=\"252\" r=\"5\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"484\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">all-MiniLM-L6-v2, 384</text><rect x=\"465\" y=\"269\" width=\"10\" height=\"10\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"484\" y=\"274\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">WordLlama, 256</text><circle cx=\"470\" cy=\"296\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.8\"></circle><text x=\"484\" y=\"296\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">WordLlama cut to 128</text><circle cx=\"470\" cy=\"318\" r=\"5\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.8\"></circle><text x=\"484\" y=\"318\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">WordLlama cut to 64</text></svg>", "caption": "What each form of the same vectors costs and how much of the full-size neighbourhood it keeps, over every text in the set. Fewer bits per number is nearly free down to int8; fewer numbers costs neighbours at every size."}
```

## What to take from the table

Your own numbers will differ, because they depend on the model and the corpus, so measure them the
way this program does: against your full-size vectors, with your own texts. The shape is what
carries over. `float16` cost nothing measurable for either model. int8 is the first thing to try once
storage costs money. Binary is a first pass rather than an answer: keep the full vectors somewhere
cheaper and use the bits to pick candidates, which is the rescoring pattern of lesson 16.
