---
title: Normal as a region
version: 1
---

Every morning Marginalia's support inbox holds a day of customer messages, and most of them are
about the five things lesson 4 sorted tickets into: shipping, returns, payments, accounts and
e-books. A few are about nothing the shop does. A prize draw, a job application, a question about
lasagne, a line of keyboard noise. Ana wants those found before anybody spends time routing them.

The course's copy of one such day is `data/inbox.jsonl`, and the course has marked which messages
do not belong, the way lesson 3 marked which article answers which question:

```
ana@lab:~/emb$ wc -l data/tickets.jsonl data/inbox.jsonl
  150 data/tickets.jsonl
   40 data/inbox.jsonl
  190 total
ana@lab:~/emb$ grep -c "\"odd\": true" data/inbox.jsonl
8
```

## A classifier always answers

The first idea is to reuse lesson 4's classifier and let the odd messages fall out of it. They do
not, because **a classifier has no answer for "none of these"**. It was built to choose among five
labels, and it chooses, whatever it is given:

```schooling-example
{
  "language": "python",
  "file": "forced.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\n\ntickets = [json.loads(l) for l in open(\"data/tickets.jsonl\")]\ninbox = [json.loads(l) for l in open(\"data/inbox.jsonl\")]",
      "note": "Read the 150 labelled tickets and the day's 40 inbox messages."
    },
    {
      "code": "labels = sorted({t[\"label\"] for t in tickets})\nV = embed([t[\"text\"] for t in tickets])\nC = np.array([V[[t[\"label\"] == l for t in tickets]].mean(axis=0) for l in labels])\nC /= np.linalg.norm(C, axis=1, keepdims=True)",
      "note": "Lesson 4's nearest-centroid classifier: one mean vector per label, renormalised to length 1."
    },
    {
      "code": "odd = [m for m in inbox if m[\"odd\"]]\nfor m, row in zip(odd, embed([m[\"text\"] for m in odd]) @ C.T):\n    j = row.argmax()\n    print(f\"{m['id']}  {labels[j]:9} {row[j]:.3f}  {m['text'][:44]}\")",
      "note": "Give each of the eight odd messages to the nearest of the five centroids, and print the label it won with its score."
    }
  ]
}
```

```
ana@lab:~/emb$ python forced.py
m33  returns   0.321  Congratulations!!! You have been selected to
m34  ebooks    0.097  Meu pedido ainda não chegou e já faz duas se
m35  account   0.034  What is the boiling point of water at the to
m36  account   0.207  asdf qwer zxcv 12345 lkjh
m37  shipping  0.273  Dear hiring manager, please find attached my
m38  returns   0.100  Can you recommend a good recipe for vegetabl
m39  payments  0.112  Increase your website traffic by 500% with o
m40  shipping  0.091  Je n'arrive pas à me connecter à mon compte 
```

The question about boiling water at the top of Everest went to `account`, with a score of 0.034,
which is next to nothing. The job application went to `shipping`. The scores are low and a careful
reader could put a cut-off on them, but that cut-off is already a different method in disguise:
it asks how far a message is from what the classifier knows, which is the question this lesson
asks directly.

## Describe normal, and measure the distance from it

The odd messages have nothing in common with each other. Spam, French, noise and a CV are not a
category, and next week's odd messages will be different ones, so there is nothing to train a
sixth label on. What the shop does have is a lot of **normal**: 150 tickets that are exactly the
kind of message the inbox is for.

So anomaly detection with embeddings turns the question around. Embed the normal messages, and
they occupy a **region** of the space, the part where shipping, returns, payments, accounts and
e-books live. Embed a new message and ask how far it is from that region. A message about a late
parcel lands inside it; a recipe question lands somewhere the tickets never went.

That needs two decisions, and the rest of the lesson takes them in turn:

1. **How to measure the distance from a region.** The next section tries the obvious answer, the
   distance to the region's centre, and the one after it tries the distance to the nearest normal
   messages.
2. **Where to cut.** A distance ranks the messages; it does not say which ones to flag. The section
   on thresholds reads the cut-off from normal data.

The `odd` field plays no part in any of it. A detector that needed it would need somebody to label
every message first, which is the work it exists to save. It is there to **measure** the detector
afterwards, in the same way that lesson 4 kept its 50 test tickets out of training.
