---
title: What k means
version: 1
---

Every search in this course so far has ended the same way: sort the scores, keep the first few.
The number kept is **k**, and a search that works this way is a **top-k** search. It is easy to
read k as *the number of good answers*. It is the number of answers, good or not.

Here is the search from lesson 3 as a module, so that the rest of the lesson can import it:

```schooling-example
{
  "language": "python",
  "file": "search.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nids = [h[\"id\"] for h in help]\nD = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])",
      "note": "Embed the 40 articles once, title and body together, when the module is imported. `D` is a 40 × 384 matrix, one row per article."
    },
    {
      "code": "def search(text, k=3):\n    scores = D @ embed(text)[0]\n    top = np.argsort(-scores)[:k]\n    return [(float(scores[i]), ids[i], help[i][\"title\"]) for i in top]",
      "note": "`search` scores every article against the question, sorts the scores from the highest down and keeps the first `k`. Nothing in it looks at how high the scores are."
    }
  ]
}
```

And two questions put to it, one the help centre answers and one it does not:

```python
from search import search

for question in ["the box never showed up", "do you sell concert tickets?"]:
    print(question)
    for score, id, title in search(question, k=3):
        print(f"  {score:.3f}  {id}  {title}")
```

```
ana@lab:~/emb$ python topk.py
the box never showed up
  0.458  h09  A parcel marked as delivered that never arrived
  0.300  h26  Resetting your password
  0.290  h19  Wrong book in the parcel
do you sell concert tickets?
  0.293  h05  Orders for schools and libraries
  0.266  h04  Buying books as a gift
  0.252  h24  Using a gift card
```

**Marginalia does not sell concert tickets, and the search returned three articles anyway.** Nothing
went wrong. `search` was asked for the three nearest articles and there are always three nearest
articles, in the same way that there is always a nearest town to any point on a map, including the
middle of the sea. A top-k search has no way to say *nothing here*.

## What the scores say, and what they do not

The first question shows the other half of the same fact. Its answer, **A parcel marked as
delivered that never arrived**, is first at 0.458, and then come *Resetting your password* at
0.300 and *Wrong book in the parcel* at 0.290. Neither has anything to do with a box that never
came. They are there because k was 3 and something had to fill the second and third places.

Read the two lists side by side and one more thing appears: the password article, which is noise
for the first question, scores **0.300**, higher than anything the concert question got (0.293). A
score is only comparable with other scores for the same question, from the same model. It is not a
grade on a fixed scale, and lesson 2's crowded space is why: in 384 dimensions, texts that share
nothing still land in a band of small positive scores.

So k answers *how many*, and it never answers *whether*. The rest of the lesson takes the two
questions separately: how to choose k, and how to stop a search returning things it should not.

## Where k is set

Every tool in this course has the same dial under a different name:

| where | the dial |
|---|---|
| NumPy, as above | `[:k]` after the sort |
| Chroma | `n_results` |
| LanceDB, pgvector | `.limit(k)`, `LIMIT k` |
| Qdrant | `limit` |
| FAISS, hnswlib | `k` in `search` and `knn_query` |

In all of them it is a request for k results. **Whether you get k depends on the index**, and the
section *k and the index* shows a database that returns fewer without saying so.
