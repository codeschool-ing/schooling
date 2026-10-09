---
title: Hybrid search
version: 2
---

A **hybrid search** runs the vector search and the lexical search and merges their results. The merge
is the difficult part, because the two produce scores on different scales: a cosine similarity of
0.367 and a BM25 score of 5.787 cannot be added, and normalising them to a common range makes the
result depend on what else was in each list.

**Reciprocal rank fusion** sidesteps the problem by ignoring the scores. Each list votes for its
chunks by rank, `1 / (60 + rank)`, and a chunk's fused score is the sum of its votes:

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "def hybrid(question, k=3, depth=20, where=\"TRUE\", params=()):\n    \"\"\"Reciprocal rank fusion of the two lists, each DEPTH long.\"\"\"\n    fused = {}\n    for ranking in (vector(question, depth, where, params), lexical(question, depth, where, params)):\n        for rank, row in enumerate(ranking, 1):\n            fused.setdefault(row[0], [row[:3], 0.0])[1] += 1 / (60 + rank)\n    best = sorted(fused.values(), key=lambda item: -item[1])[:k]\n    return [(*row, score) for row, score in best]",
      "note": "Each list contributes 1/(60 + rank) for every chunk it holds, and a chunk in both lists gets both. The scores of the two methods are never compared, only their ranks, which is what lets a cosine and a BM25 score be combined at all."
    }
  ]
}
```

The 60 is a constant from the paper that introduced the method, Cormack and others, 2009, and it
controls how much a first place outweighs a tenth: with 60 the difference is small, so a chunk both
lists rank fairly high beats one that a single list ranks first.

```
ana@vm:~/rag$ python show.py hybrid "What does error E-4104 mean?"
1    0.033  Affiliate API reference > Errors  | | code | HTTP | meaning | | --- | --- | --- | | 
2    0.032  Affiliate API reference > Errors  | Errors are returned as JSON with a code and a me
3    0.031  Affiliate API reference > Changes in 2.3  | Version 2.3, released on 10 February 2026, added
4    0.030  Affiliate API reference > Rate limits  | A key may make 120 requests per minute. A reques
5    0.029  Warehouse on-call runbook > After an incident  | Every SEV-1 and SEV-2 gets a short review within
```

The error table is first, as it was in both lists. The fused scores are tiny and close together,
0.033 against 0.032, because they are sums of reciprocals; like every score in this lesson, they are
only good for ordering.

## Measuring all of it

`measure.py` runs every method of `search.py` against both test sets and counts the questions whose
answer is in the first chunk and in the first three:

```schooling-example
{
  "language": "python",
  "file": "measure.py",
  "parts": [
    {
      "code": "import json\n\nfrom search import hybrid, lexical, rerank, vector\n\nnorm = lambda t: \" \".join(t.split())\nfound = lambda rows, q: any(f in norm(r[2]) for r in rows for f in q[\"facts\"])\nmethods = {\n    \"vector\": lambda q: vector(q, 3),\n    \"lexical\": lambda q: lexical(q, 3),\n    \"hybrid\": lambda q: hybrid(q, 3),\n    \"hybrid, reranked\": lambda q: rerank(q, hybrid(q, 20), 3),\n}\nsets = {name: [q for q in map(json.loads, open(f\"data/{name}.jsonl\")) if q[\"facts\"]]\n        for name in (\"eval\", \"identifiers\")}",
      "note": "Four ways of searching, each asked for its top three. The reranked one reorders the hybrid's top twenty, so it costs twenty calls to the model per question."
    },
    {
      "code": "print(f\"{'':18}{'eval @1':>9}{'eval @3':>9}{'ids @1':>8}{'ids @3':>8}\")\nfor name, run in methods.items():\n    cells = []\n    for s in (\"eval\", \"identifiers\"):\n        results = [(q, run(q[\"question\"])) for q in sets[s]]\n        for k in (1, 3):\n            hits = sum(found(rows[:k], q) for q, rows in results)\n            cells.append(f\"{hits:>{6 if s == 'eval' else 5}}/{len(sets[s]):<2}\")\n    print(f\"{name:18}\" + \"\".join(cells))",
      "note": "For each method and each question set, how many questions had a right fact in the first result, and in the top three. Each question is searched once and the first result is read off the top three."
    }
  ]
}
```

```
ana@vm:~/rag$ python measure.py
                    eval @1  eval @3  ids @1  ids @3
vector                19/26    26/26    3/6     4/6 
lexical               16/26    20/26    4/6     6/6 
hybrid                20/26    24/26    4/6     5/6 
hybrid, reranked      19/26    26/26    0/6     4/6 
```

**No line wins every column.** Vector search is best on the customer questions at three, 26 of 26.
Lexical search is best on the identifiers at three, 6 of 6. Hybrid is the compromise it was designed
to be: the best first result on the customer questions, 20 of 26, and close to lexical on the
identifiers, but it lost two customer questions at three, 24 against 26, because the lexical list
pushed weaker chunks into the merge. The last line is the subject of the next section.

## What to take from a table like this

**The right method depends on the mix of questions, and only a test set of real questions tells you
the mix.** A support assistant whose users never type an error code loses a little by going hybrid; a
developer assistant without lexical search fails the questions its users care most about. Measure on
your own questions, both kinds, and keep the table.

Two practical notes. The fusion constant and the depth of each list, 20 here, are knobs worth
measuring too. And most vector databases now offer hybrid search natively, with the lexical half
running inside the same engine; `embeddings-vectors` lesson 3 built a hybrid by hand over the help
centre, and the principle is the same at any scale.
