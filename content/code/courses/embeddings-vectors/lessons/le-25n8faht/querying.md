---
title: Answering a question
version: 1
---

At search time the work is small: embed the question with the same model, score it against every
stored vector, and return the best few.

```schooling-example
{
  "language": "python",
  "file": "search.py",
  "parts": [
    {
      "code": "import json\nimport sys\nimport numpy as np\nfrom minilm import embed\n\nD = np.load(\"index.npy\")\nids = json.load(open(\"ids.json\"))\nhelp = {h[\"id\"]: h for h in map(json.loads, open(\"data/help.jsonl\"))}",
      "note": "Load what `index.py` stored, and the articles to show their titles. The model is loaded once, when `minilm` is imported, not per question."
    },
    {
      "code": "def search(query, k=3):\n    q = embed(query)[0]\n    scores = D @ q\n    best = np.argsort(-scores)[:k]\n    return [(ids[i], float(scores[i])) for i in best]",
      "note": "Embed the question, score it against every row, sort from the highest score down and keep `k`. Each row number goes back through `ids` to an article."
    },
    {
      "code": "if __name__ == \"__main__\":\n    for doc, score in search(sys.argv[1]):\n        print(f\"{score:6.3f}  {doc}  {help[doc]['title']}\")",
      "note": "From the command line, print the three best with their scores."
    }
  ]
}
```

```
ana@lab:~/emb$ python search.py "how do I get my money back"
 0.446  h18  Returning a gift
 0.438  h15  When your refund arrives
 0.399  h22  Charged twice for one order
ana@lab:~/emb$ python search.py "the box never showed up"
 0.458  h09  A parcel marked as delivered that never arrived
 0.300  h26  Resetting your password
 0.290  h19  Wrong book in the parcel
```

**The money-back question returns the two articles that answer it among its top three**, the gift
article and the refund article, as in lesson 1, but this time against all 40 articles rather than
six that were picked for it. *the box never showed up* finds **A parcel marked as delivered that
never arrived** at 0.458, without one meaningful word in common.

Look at what comes second and third for the box. **Resetting your password** at 0.300 and **Wrong
book in the parcel** at 0.290 have nothing to do with a missing parcel. A search always returns `k`
results, whether or not `k` good ones exist, and their scores are far below the first. Lesson 16
deals with that: when to cut a list short, and how to choose `k`.

## Every article, every time

`D @ q` computes the score of **every** stored vector against the question, 40 dot products of 384
numbers each. Then `np.argsort(-scores)` sorts all of them, from the highest score down, because
`argsort` sorts upwards and the minus sign turns it round. Nothing is skipped and nothing is
guessed, so the top three are exactly the three closest.

That is called **exact** or **brute-force** search, and for 40 articles it is the right tool. Its
cost grows with every document added: a million articles would be a million dot products per
question. Lesson 11 measures where that starts to hurt, and lesson 15 builds the indexes that avoid
reading every vector, at the price of sometimes missing one.
