---
title: More sources is not more answers
version: 2
---

The obvious way to make sure the answer is in the prompt is to send more: raise `k`, and whatever the
search ranked fourth or eighth comes along too. `sweep.py` measures what that buys, for the 26
answerable questions of `eval.jsonl`, at six values of `k`:

```schooling-example
{
  "language": "python",
  "file": "sweep.py",
  "parts": [
    {
      "code": "import itertools\nimport json\n\nfrom context import FLOOR, tokens\nfrom vectors import embed\nfrom search import vector\n\nquestions = [q for q in map(json.loads, open(\"data/eval.jsonl\")) if q[\"facts\"]]\nnorm = lambda t: \" \".join(t.replace(\"|\", \" \").split())\nprint(f\"{'k':>3} {'found':>6} {'tokens':>7} {'alike':>6} {'above floor':>12}\")\nfor k in (1, 2, 3, 5, 8, 12):\n    found, used, alike, kept = 0, 0, 0, 0\n    for q in questions:\n        top = vector(q[\"question\"], k, \"status = %s\", (\"current\",))\n        found += any(f in norm(r[2]) for r in top for f in q[\"facts\"])\n        used += tokens(\"\\n\".join(r[2] for r in top))\n        v = embed([r[2] for r in top])\n        alike += sum(1 for i, j in itertools.combinations(range(len(top)), 2) if v[i] @ v[j] >= 0.8)\n        kept += sum(1 for r in top if r[3] >= FLOOR)\n    n = len(questions)\n    print(f\"{k:3} {found:3}/{n} {used / n:7.0f} {alike:6} {kept / n:12.1f}\")",
      "note": "The same search with k from 1 to 12, and for each k how many answers it found, how many tokens it cost, how many pairs of sources were near-duplicates of each other, and how many sources on average cleared the floor."
    }
  ]
}
```

```
ana@vm:~/rag$ python sweep.py
  k  found  tokens  alike  above floor
  1  20/26      60      0          1.0
  2  26/26     116      3          1.8
  3  26/26     171      3          2.6
  5  26/26     279      7          3.4
  8  26/26     441     12          4.1
 12  26/26     660     16          4.7
```

The columns are: how many questions had a fact of the answer somewhere in what was retrieved, the
tokens of source text per question, how many pairs of retrieved chunks were 0.8 similar or more, and
how many retrieved chunks on average would pass lesson 6's floor of 0.5.

**Retrieval stops improving at two.** With one source, 20 of 26 answers were in the prompt; with two,
all 26; after that, nothing more to find. **The tokens keep growing in a straight line**, 116 at two
and 660 at twelve, and so do the pairs of chunks that say nearly the same thing. Everything after
the second source is cost: the same answers, more text around them.

## What the extra text does to a model

Thirty questions and one small model are too few to see what the extra text does to a language
model's replies; the last section of this lesson compares two prompts over all thirty, and that is
as far as this corpus can go. Two published measurements go further:

- **Irrelevant text lowers accuracy.** Shi and others, in *Large Language Models Can Be Easily
  Distracted by Irrelevant Context* (ICML 2023), added a sentence that had nothing to do with the
  question to arithmetic word problems, and the models they tested got noticeably more of them
  wrong.
- **Where the answer sits matters.** Liu and others, in *Lost in the Middle: How Language Models Use
  Long Contexts* (TACL 2024), put the passage with the answer at different positions among many
  others and found that models used it best at the beginning or the end of the input, and worst in
  the middle, including models built for long inputs.

Neither paper measured your model on your documents, and models have changed since. They are the
reason to treat every extra source as a cost until a measurement says otherwise, and the reason the
placement section exists. The test that decides it for a real deployment is lesson 8's, run against
the real model at two values of `k`.
