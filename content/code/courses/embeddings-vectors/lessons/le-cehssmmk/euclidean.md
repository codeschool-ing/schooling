---
title: Euclidean distance
version: 1
---

The other natural way to compare two points is to measure the straight line between them. That is
the **Euclidean distance**, also called the **L2 distance**: subtract one vector from the other,
and take the length of what is left. For the two vectors of the last sections, `a − b` is
`(1, −1, 0)` and its length is √(1 + 1 + 0) = 1.414.

The direction of the scale is the first thing to keep straight. **A similarity is higher when two
texts are closer; a distance is lower.** Sorting a distance from the top returns the worst matches
first, and it is a mistake that looks perfectly reasonable on screen.

## For unit vectors, the same ranking as cosine

Expand the squared distance and the dot product appears inside it:
`|a − b|² = |a|² + |b|² − 2 a · b`. When both vectors have length 1, the first two terms are 1 each
and the dot product is the cosine, so

`|a − b|² = 2 − 2 cos θ`

The distance is a fixed, decreasing function of the cosine. Ranking by the smallest distance is
therefore exactly ranking by the largest cosine, and `euclid.py` checks it on the help centre with
the 24 questions in `data/queries.jsonl`:

```schooling-example
{
  "language": "python",
  "file": "euclid.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\n\na = np.array([2, 1, 2])\nb = np.array([1, 2, 2])\nprint(a - b, round(np.linalg.norm(a - b), 3))",
      "note": "The paper example: subtract, then take the length."
    },
    {
      "code": "help = [json.loads(line) for line in open(\"data/help.jsonl\")]\nD = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]\nQv = embed([q[\"text\"] for q in queries])",
      "note": "The 40 articles and the 24 questions, all embedded with all-MiniLM-L6-v2."
    },
    {
      "code": "q = Qv[0]\ncos = D @ q\ndist = np.linalg.norm(D - q, axis=1)\nprint(\"      cos    dist   2-2cos  dist^2\")\nfor i in np.argsort(-cos)[:4]:\n    print(f\"{help[i]['id']}  {cos[i]:.3f}  {dist[i]:.3f}  {2 - 2 * cos[i]:.3f}  {dist[i] ** 2:.3f}\")",
      "note": "For the first question, *how do I get my money back*, the cosine and the distance of the four best articles, with both sides of the formula."
    },
    {
      "code": "same_l2 = same_l1 = top_l1 = 0\nfor q in Qv:\n    by_cos = np.argsort(-(D @ q))\n    by_l2 = np.argsort(np.linalg.norm(D - q, axis=1))\n    by_l1 = np.argsort(np.abs(D - q).sum(axis=1))\n    same_l2 += (by_cos == by_l2).all()\n    same_l1 += (by_cos == by_l1).all()\n    top_l1 += by_cos[0] == by_l1[0]\nprint(f\"same order as cosine, all 40 articles: L2 {same_l2}/24, L1 {same_l1}/24\")\nprint(f\"same first article as cosine:          L1 {top_l1}/24\")",
      "note": "For every question, sort all 40 articles three ways and compare the orders: by the largest cosine, by the smallest L2 distance and by the smallest L1 distance."
    }
  ]
}
```

```
ana@lab:~/emb$ python euclid.py
[ 1 -1  0] 1.414
      cos    dist   2-2cos  dist^2
h18  0.446  1.053  1.109  1.109
h15  0.438  1.061  1.125  1.125
h22  0.399  1.096  1.201  1.201
h14  0.392  1.103  1.216  1.216
same order as cosine, all 40 articles: L2 24/24, L1 0/24
same first article as cosine:          L1 23/24
```

The table is the formula in numbers. For the gift article, the column `2-2cos` and the square of
its distance of 1.053 both read 1.109, and the same holds on every row. **The two rankings of all 40 articles agree for 24 of the 24
questions.** For a model whose vectors have length 1, choosing between cosine and L2 changes the
numbers you see and never the order of the results.

## Manhattan distance

The **L1** or **Manhattan** distance adds up the absolute differences coordinate by coordinate, the
way a taxi crosses a city of square blocks. It is a perfectly good distance, and it is not the one
these models were trained with. The last two lines measure what that costs: L1 put the same article
first as cosine for 23 of the 24 questions, and the full order of 40 articles matched for none of
them. Some libraries offer it; for text embeddings you will rarely have a reason to pick it.
