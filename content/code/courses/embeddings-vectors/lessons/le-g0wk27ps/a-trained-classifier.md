---
title: A trained classifier
version: 1
---

Nearest neighbours and centroids both compare whole vectors, and in a dot product every one of
the 384 coordinates counts the same. A **trained classifier** learns which directions in the space
separate the desks and weights them accordingly. The embedding becomes a list of 384 **features**,
the input a classical model expects, and the model on top of it can be very small.

## Logistic regression on the vectors

scikit-learn's `LogisticRegression` learns, for each desk, one weight per coordinate and one
constant. A new ticket's score for a desk is the weighted sum of its coordinates plus the constant,
and the five scores are turned into probabilities that add up to 1.

```schooling-example
{
  "language": "python",
  "file": "trained.py",
  "parts": [
    {
      "code": "import time\nimport numpy as np\nfrom sklearn.linear_model import LogisticRegression\nfrom tickets import load\n\nXtr, ytr, train = load(\"train\")\nXte, yte, test = load(\"test\")",
      "note": "The vectors are the input and the labels are the answers. Nothing else is needed."
    },
    {
      "code": "t0 = time.perf_counter()\nmodel = LogisticRegression(max_iter=1000).fit(Xtr, ytr)\nprint(f\"trained in {(time.perf_counter() - t0) * 1000:.0f} ms\")\nprint(\"weights:\", model.coef_.shape, \"+\", model.intercept_.shape)",
      "note": "`fit` learns the weights. `max_iter` raises the number of steps the solver may take, so that it finishes instead of stopping with a warning. Print how long it took and the shape of what was learned."
    },
    {
      "code": "pred = model.predict(Xte)\nprint((pred == yte).sum(), \"of\", len(yte), \"right\")",
      "note": "`predict` gives one label per test ticket."
    },
    {
      "code": "i = [t[\"id\"] for t in test].index(\"t027\")\nprint(test[i][\"text\"])\nfor label, p in zip(model.classes_, model.predict_proba(Xte[i:i + 1])[0]):\n    print(f\"  {label:9} {p:.3f}\")",
      "note": "`predict_proba` gives, for one ticket, a probability per desk, in the order of `model.classes_`."
    }
  ]
}
```

```
ana@lab:~/emb$ python trained.py
trained in 11 ms
weights: (5, 384) + (5,)
47 of 50 right
I was charged for delivery twice on one order that came in two boxes.
  account   0.069
  ebooks    0.042
  payments  0.388
  returns   0.132
  shipping  0.368
```

**The whole model is a 5 × 384 table of weights and five constants**, 1,925 numbers, and it trained
in the time the first line printed. The heavy part, reading the language, was done by the embedding
model before training started; the classifier only learns where to draw lines between points that
are already arranged by meaning.

And it scored **47 of 50, exactly what the centroids scored**. That contradicts a picture worth
naming: that a trained model must beat the methods that learn nothing. It does not have to, and
here it does not, for two reasons that are both visible in the data. MiniLM's vectors already put
these five desks in different places, so there is little left for a weighting to fix; and 20
examples per desk are not many from which to learn 384 weights each.

## When training pays

The way to find out is to change the conditions and measure. `fewer.py` keeps the first 1, 2, 3, 5,
10 or 20 training tickets of each desk and runs all three methods on each. Then it repeats
everything with WordLlama, the static model from lesson 1, whose vectors are less sharp:

```schooling-example
{
  "language": "python",
  "file": "fewer.py",
  "parts": [
    {
      "code": "import numpy as np\nfrom sklearn.linear_model import LogisticRegression\nfrom wordllama import WordLlama\nfrom tickets import load\n\nXtr, ytr, train = load(\"train\")\nXte, yte, test = load(\"test\")\nlabels = sorted(set(ytr))\nwl = WordLlama.load()\ntexts = lambda rows: [t[\"text\"] for t in rows]\nmodels = {\"minilm\": (Xtr, Xte),\n          \"wordllama\": (wl.embed(texts(train), norm=True), wl.embed(texts(test), norm=True))}\n\ndef scores(A, y, B):\n    C = np.array([A[y == label].mean(axis=0) for label in labels])\n    C /= np.linalg.norm(C, axis=1, keepdims=True)\n    knn = y[(B @ A.T).argmax(axis=1)]\n    cen = np.array(labels)[(B @ C.T).argmax(axis=1)]\n    lr = LogisticRegression(max_iter=1000).fit(A, y).predict(B)\n    return [(p == yte).sum() for p in (knn, cen, lr)]\n\nprint(\"model      per label   1-nn  centroid  logistic\")\nfor name, (A, B) in models.items():\n    for n in (1, 2, 3, 5, 10, 20):\n        keep = np.concatenate([np.flatnonzero(ytr == label)[:n] for label in labels])\n        k1, cen, lr = scores(A[keep], ytr[keep], B)\n        print(f\"{name:10} {n:>9} {k1:>6} {cen:>9} {lr:>9}\")",
      "note": "Both models embed the same tickets; WordLlama's vectors are computed here and MiniLM's come from the saved files. `scores` runs the three methods on a training set and counts right answers on the full test set. The loop keeps the first `n` tickets of each desk, so every run is the same subset and nothing is random."
    }
  ]
}
```

```
ana@lab:~/emb$ python fewer.py
model      per label   1-nn  centroid  logistic
minilm             1     37        37        37
minilm             2     36        36        36
minilm             3     35        39        39
minilm             5     36        40        40
minilm            10     40        45        44
minilm            20     46        47        47
wordllama          1     32        32        35
wordllama          2     37        39        36
wordllama          3     35        37        37
wordllama          5     40        40        41
wordllama         10     42        40        43
wordllama         20     40        42        44
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Two line charts side by side, right answers out of 50 test tickets against the number of training tickets kept per desk: 1, 2, 3, 5, 10 and 20. Left, with all-MiniLM-L6-v2 vectors: the three methods start together at 37, the single nearest neighbour is never above the other two, and centroids and logistic regression end at 47. Right, with WordLlama vectors: everything is lower, the lines cross several times, and at 20 per desk logistic regression leads with 44, centroids 42 and the nearest neighbour 40.\"><text x=\"205\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">all-MiniLM-L6-v2</text><path d=\"M70 280 L340 280\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 280 L70 60\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 280 L340 280\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"280\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><path d=\"M70 225 L340 225\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"225\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">35</text><path d=\"M70 170 L340 170\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><path d=\"M70 115 L340 115\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"115\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">45</text><path d=\"M70 60 L340 60\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><text x=\"85\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"133\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"181\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"229\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><text x=\"277\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"325\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><path d=\"M85.0 203.0 L133.0 214.0 L181.0 225.0 L229.0 214.0 L277.0 170.0 L325.0 104.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"85\" cy=\"203\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"133\" cy=\"214\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"181\" cy=\"225\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"229\" cy=\"214\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"277\" cy=\"170\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"325\" cy=\"104\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><path d=\"M85.0 203.0 L133.0 214.0 L181.0 181.0 L229.0 170.0 L277.0 115.0 L325.0 93.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><rect x=\"81\" y=\"199\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"129\" y=\"210\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"177\" y=\"177\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"225\" y=\"166\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"273\" y=\"111\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"321\" y=\"89\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M85.0 203.0 L133.0 214.0 L181.0 181.0 L229.0 170.0 L277.0 126.0 L325.0 93.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"85\" cy=\"203\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"133\" cy=\"214\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"181\" cy=\"181\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"229\" cy=\"170\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"277\" cy=\"126\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"325\" cy=\"93\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><text x=\"205\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">training tickets per desk</text><text x=\"545\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">WordLlama</text><path d=\"M410 280 L680 280\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M410 280 L410 60\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M410 280 L680 280\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"402\" y=\"280\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><path d=\"M410 225 L680 225\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"402\" y=\"225\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">35</text><path d=\"M410 170 L680 170\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"402\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><path d=\"M410 115 L680 115\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"402\" y=\"115\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">45</text><path d=\"M410 60 L680 60\" stroke=\"var(--scan)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"402\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><text x=\"425\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"473\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"521\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"569\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><text x=\"617\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"665\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><path d=\"M425.0 258.0 L473.0 203.0 L521.0 225.0 L569.0 170.0 L617.0 148.0 L665.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"425\" cy=\"258\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"473\" cy=\"203\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"521\" cy=\"225\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"569\" cy=\"170\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"617\" cy=\"148\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><circle cx=\"665\" cy=\"170\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><path d=\"M425.0 258.0 L473.0 181.0 L521.0 203.0 L569.0 170.0 L617.0 170.0 L665.0 148.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><rect x=\"421\" y=\"254\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"469\" y=\"177\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"517\" y=\"199\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"565\" y=\"166\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"613\" y=\"166\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"661\" y=\"144\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M425.0 225.0 L473.0 214.0 L521.0 203.0 L569.0 159.0 L617.0 137.0 L665.0 126.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"425\" cy=\"225\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"473\" cy=\"214\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"521\" cy=\"203\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"569\" cy=\"159\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"617\" cy=\"137\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><circle cx=\"665\" cy=\"126\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><text x=\"545\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">training tickets per desk</text><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">right of 50</text><path d=\"M70 338 L77 338\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M87 338 L94 338\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"82\" cy=\"338\" r=\"3.5\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"102\" y=\"338\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1 nearest neighbour</text><path d=\"M290 338 L297 338\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M307 338 L314 338\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><rect x=\"298\" y=\"334\" width=\"8\" height=\"8\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"322\" y=\"338\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">centroids</text><path d=\"M450 338 L457 338\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M467 338 L474 338\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"462\" cy=\"338\" r=\"4.5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"2\"></circle><text x=\"482\" y=\"338\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">logistic regression</text></svg>", "caption": "Right answers out of 50 as the training set shrinks, for the three methods that learn from labels. On MiniLM's vectors the lines stay close and end together; on WordLlama's, logistic regression ends ahead. Every step is a few tickets, which is why none of the lines is smooth."}
```

Three readings, each from a row of that table.

**With weaker vectors, training is worth more.** On WordLlama's vectors with 20 per desk, the single
nearest neighbour gets 40, the centroids 42 and logistic regression 44. Where the space is less
tidy, learning which directions matter recovers some of what the embedding lost.

**With very few examples, the average beats the single neighbour.** On MiniLM with 3 per desk, the
nearest neighbour gets 35 and the centroids 39. One example can be unusual; the mean of three
already smooths that out.

**None of the curves is smooth.** MiniLM's nearest neighbour scores 37 with one example per desk
and 36 with two, because the second example happened to pull some tickets the wrong way. With 50
test tickets, every step in the table is a handful of tickets, and the next section is about how
much a handful means.

## A probability is a reason to ask

The last lines of `trained.py` show what the model thinks of **t027**, *I was charged for delivery
twice on one order that came in two boxes*. Payments gets 0.388 and shipping 0.368: the model is
almost evenly split, and it says so. k-NN and centroids answer with a label and nothing else.

That split is useful. A queue can send any ticket whose top probability is low to a person instead
of a desk. How low is low has to be measured on your own data, the same way
lesson 6 sets the threshold for an anomaly. A probability of 0.388 from this model is a ranking of
its confidence, not a promise that it is right 38.8% of the time.

Logistic regression is one choice among many. Any classifier that takes a table of numbers can
take embeddings, and choosing, tuning and validating one is what `machine-learning` teaches. What
belongs to this course is the observation underneath: **the embedding did the expensive part once,
and every classifier on top of it is cheap.**
