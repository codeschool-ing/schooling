---
title: Centroids
version: 1
---

k-nearest neighbours keeps all 100 examples and asks which of them a new ticket resembles. A
**centroid** keeps one vector per desk, the average of that desk's examples, and asks which desk
the ticket resembles. Five comparisons instead of a hundred, and in this lesson's data it loses
nothing for it.

```schooling-example
{
  "language": "python",
  "file": "centroids.py",
  "parts": [
    {
      "code": "import numpy as np\nfrom tickets import load\n\nXtr, ytr, train = load(\"train\")\nXte, yte, test = load(\"test\")\nlabels = sorted(set(ytr))",
      "note": "Same data as before. `labels` is the five desks in alphabetical order, which fixes the order of the centroids."
    },
    {
      "code": "C = np.array([Xtr[ytr == label].mean(axis=0) for label in labels])\nprint(\"length before:\", np.linalg.norm(C, axis=1).round(3))\nC /= np.linalg.norm(C, axis=1, keepdims=True)",
      "note": "One average per desk, taken over its 20 training vectors. Print their lengths, then divide each by its own length."
    },
    {
      "code": "pred = np.array(labels)[(Xte @ C.T).argmax(axis=1)]\nprint((pred == yte).sum(), \"of\", len(yte), \"right\")",
      "note": "Score every test ticket against the five centroids and keep the desk with the highest score."
    },
    {
      "code": "for label, c in zip(labels, C):\n    s = Xtr @ c\n    s[ytr != label] = np.nan\n    near, far = np.nanargmax(s), np.nanargmin(s)\n    print(f\"{label:9} {s[near]:.3f} {train[near]['text']}\")\n    print(f\"{'':9} {s[far]:.3f} {train[far]['text']}\")",
      "note": "For each desk, score its own training tickets against its centroid. Tickets of other desks are set to `nan` so that `nanargmax` and `nanargmin` skip them."
    }
  ]
}
```

```
ana@lab:~/emb$ python centroids.py
length before: [0.542 0.554 0.526 0.592 0.542]
47 of 50 right
account   0.791 I no longer have access to the email I signed up with.
          0.251 Why do you need my date of birth?
ebooks    0.734 The e-book I bought won't open on my Kindle.
          0.322 Is there a dark mode for reading at night?
payments  0.607 My bank statement shows a charge from you I don't recognise.
          0.408 Can the school pay by bank transfer after the books arrive?
returns   0.745 I'd like to send back a book I bought last week, it's not what I expected.
          0.406 The book I received is a different translation from the one on the website.
shipping  0.693 My order was supposed to arrive on Tuesday and it's now Friday. Where is it?
          0.417 The tracking number you gave me doesn't work on the carrier's site.
```

**47 of the 50 test tickets land on the right desk**, one more than the single nearest neighbour,
with five vectors standing in for a hundred. One ticket is two points out of a hundred on a test
this size, so the honest reading is *as good as k-NN here*, not *better*; the section *Measuring
a classifier* says why.

## Why the average has to be renormalised

Every ticket vector has length 1. Their average does not: the five centroids came out between
0.526 and 0.592. Twenty arrows pointing in roughly the same direction add up to an arrow shorter
than twenty, and the more they disagree, the shorter it gets. So the length of a centroid is a
measure of how varied its desk is. Payments, at 0.526, is the most varied of the five; returns, at
0.592, the most uniform.

That is useful to know and harmful to keep. Left alone, a desk whose tickets agree with each other
would get a longer centroid, and a longer vector wins dot products by length rather than by
direction, the trap lesson 2 measures. Dividing each centroid by its own length puts all five back
on the sphere, and the dot product is a cosine again.

## A centroid is a prototype

The last part of the program asks which training ticket sits nearest each centroid and which
sits furthest from it. The nearest one is the desk's most typical message: *I'd like to send back
a book I bought last week* for returns, *My order was supposed to arrive on Tuesday* for shipping.
Read together, the five nearest are a fair description of what the five desks are for, written by
customers.

The furthest are where to look when something is wrong. **Why do you need my date of birth?**
scores 0.251 against the account centroid, below every other desk's least typical ticket. It is a
question about personal data, which the team files under accounts, so the label is defensible.
In a real queue of thousands, though, the tickets furthest from their own centroid are a short list of
candidates for a person to check.

## Where one point per desk is not enough

A centroid assumes that a desk is one cloud of points with a middle. Payments is the case where
that is weakest: declined cards, invoices for companies, gift cards and bank transfers are four
different conversations, and their average is close to none of them. Its most typical ticket
scores 0.607, the lowest of the five, and its least typical 0.408.

When a desk is really several groups, the fix is to give it several centroids, one per group, and
let the nearest of them speak for the desk. Finding those groups without labels is clustering,
which `machine-learning` teaches; this lesson stays with the five averages, which are already
enough here.
