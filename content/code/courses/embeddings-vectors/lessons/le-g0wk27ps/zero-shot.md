---
title: Zero-shot classification
version: 1
---

Every method so far needed tickets somebody had already sorted. On the day a new queue opens there
are none. **Zero-shot** classification replaces the examples with a few words per desk: embed a
short text that describes each desk, and give a ticket the label of the description it is nearest
to. It is the centroid method with the centroids written by hand instead of averaged from data.

How those few words are chosen turns out to matter a great deal, so the program tries three
wordings of the same five desks:

```schooling-example
{
  "language": "python",
  "file": "zeroshot.py",
  "parts": [
    {
      "code": "import numpy as np\nfrom minilm import embed\nfrom tickets import load\n\nXte, yte, test = load(\"test\")\nlabels = [\"account\", \"ebooks\", \"payments\", \"returns\", \"shipping\"]",
      "note": "Only the test tickets are loaded. No training ticket and no training label is read anywhere in this program."
    },
    {
      "code": "wordings = {\n    \"names\": [\"account\", \"ebooks\", \"payments\", \"returns\", \"shipping\"],\n    \"descriptions\": [\n        \"a question about signing in, passwords and personal data\",\n        \"a question about e-books, audiobooks and the reading app\",\n        \"a question about paying, cards, charges and invoices\",\n        \"a question about sending a book back for a refund or exchange\",\n        \"a question about delivery and parcels\",\n    ],\n    \"examples\": [\n        \"I can't log in to my account.\",\n        \"My e-book won't open in the app.\",\n        \"My card was charged twice at checkout.\",\n        \"I want to return this book and get a refund.\",\n        \"Where is my parcel? It has not been delivered yet.\",\n    ],\n}",
      "note": "Three ways to describe the same five desks, each list in the order of `labels`: the bare name, a sentence saying what the desk covers, and one example of a message."
    },
    {
      "code": "for name, texts in wordings.items():\n    D = embed(texts)\n    pred = np.array(labels)[(Xte @ D.T).argmax(axis=1)]\n    print(f\"{name:13} {(pred == yte).sum()} of {len(yte)} right\")",
      "note": "For each wording, embed its five texts and give every ticket the label of the nearest one."
    }
  ]
}
```

```
ana@lab:~/emb$ python zeroshot.py
names         39 of 50 right
descriptions  43 of 50 right
examples      35 of 50 right
```

**With no labelled ticket at all, the best wording sorts 43 of the 50.** That is four tickets
behind the centroids and nothing else was needed: five sentences and the model that was already
there.

## The wording is the model

The same embedding model, the same tickets, and the score moves from 35 to 43 depending only on
the sentences. Each wording fails in its own way.

**The bare names** score 39. A word like `returns` or `account` is a very short text, and its
vector carries whatever that one word means to the model, which is not quite what Marginalia means
by it.

**One example sentence per desk** scores 35, the worst of the three. *My card was charged twice at
checkout* is a payments ticket, but it is one particular payments ticket, and a question about an
invoice is far from it. This is the single nearest neighbour with one example per desk, and the
previous section measured that at 37 on real tickets.

**A description that lists what the desk covers** scores 43. *A question about paying, cards,
charges and invoices* is not any one payments ticket: it names several of the things they are
about, and that wording sorted eight tickets more than the example sentences did.

## Tuning a wording on the test set is training on it

There is a trap in the paragraph above. The three wordings were compared on the 50 test tickets.
If the next step is to keep adjusting the descriptions until the score stops rising, the test
set has stopped being a test: the descriptions have learned from it, through you. With 50 tickets,
a wording that wins by two or three may only be a good fit for these 50.

The way out is the same as for any other method. Adjust the wording against tickets set aside for
the purpose, and keep the test set for a last look at the end.

## Where zero-shot fits

Zero-shot classification is how a new queue starts, not where it stays. It sorts the first messages
well enough to be useful; a person corrects the ones it gets wrong; and after a few weeks there are
enough labelled tickets for centroids or a trained classifier, which beat it here by four tickets.

Its other use is for labels that change. Adding a sixth desk to a zero-shot classifier is one more
sentence. Adding it to a trained one means collecting examples and training again. Lesson 6 meets
exactly that moment, when a new subscription brings a kind of message none of the five desks
expects.
