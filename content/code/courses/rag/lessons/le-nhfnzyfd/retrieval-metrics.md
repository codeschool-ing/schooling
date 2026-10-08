---
title: Measuring retrieval
version: 2
---

Lesson 7 separated three properties: did the search find the passage, does each sentence come from its
source, and does the reply answer the question. `evaluate.py` measures all three for every question
in a split:

```schooling-example
{
  "language": "python",
  "file": "evaluate.py",
  "parts": [
    {
      "code": "import argparse\nimport json\nimport sys\n\nimport answer as pipeline\nfrom search import vector\nfrom verify import check, norm\n\np = argparse.ArgumentParser(description=\"Measure retrieval and answers against data/eval.jsonl.\")\np.add_argument(\"--split\", choices=[\"dev\", \"held-out\", \"all\"], default=\"dev\")\np.add_argument(\"--floor\", type=float, default=pipeline.FLOOR)\np.add_argument(\"--k\", type=int, default=3)\np.add_argument(\"--list\", action=\"store_true\", help=\"one line per question\")\np.add_argument(\"--min-correct\", type=float, default=0.0, help=\"fail below this share of correct replies\")\na = p.parse_args()\npipeline.FLOOR = a.floor",
      "note": "Options for the comparisons later in the lesson: which part of the test set, the floor, k, a per-question listing, and the share of correct replies below which the run fails. `--floor` overrides the pipeline's own value for this run only."
    },
    {
      "code": "def split_of(q):\n    \"\"\"Every third question is held out, decided by its id and nothing else.\"\"\"\n    return \"held-out\" if int(q[\"id\"][1:]) % 3 == 0 else \"dev\"",
      "note": "The held-out third is chosen by the question's id, so it is the same third on every run and on every machine, and nobody chooses which questions are easy to hold out."
    },
    {
      "code": "questions = [q for q in map(json.loads, open(\"data/eval.jsonl\")) if a.split in (\"all\", split_of(q))]\nwhere, params = \"status = %s\", (\"current\",)\nranks, correct, faithful, refused_right, rows = [], 0, 0, 0, []\nfor q in questions:\n    found = vector(q[\"question\"], 5, where, params)\n    rank = next((i for i, r in enumerate(found, 1) if any(f in norm(r[2]) for f in q[\"facts\"])), None)\n    reply, sources = pipeline.answer(q[\"question\"], k=a.k, where=where, params=params)\n    refused = reply == pipeline.REFUSAL\n    right = refused if not q[\"facts\"] else not refused and any(f in norm(reply) for f in q[\"facts\"])\n    true = refused or all(v.startswith((\"quoted\", \"close\")) for _, _, v in check(reply, sources))\n    correct += right\n    faithful += true\n    if q[\"facts\"]:\n        ranks.append(rank)\n    else:\n        refused_right += refused\n    rows.append(f\"{q['id']}  rank {rank or '-'}  {'refused ' if refused else 'answered'}  \"\n                f\"{'correct' if right else 'WRONG  '}  {'faithful' if true else 'UNFAITHFUL'}  {q['question']}\")",
      "note": "For each question, three measurements. Retrieval: the rank of the first chunk holding the answer's words, among the five nearest. Correctness: an answerable question must get a reply containing those words, an unanswerable one must be refused. Faithfulness: every sentence of a reply that is not a refusal must pass lesson 7's check."
    },
    {
      "code": "n, answerable = len(questions), len(ranks)\nhits = lambda k: sum(1 for r in ranks if r and r <= k)\nprint(f\"{a.split}: {n} questions, {answerable} answerable, floor {a.floor}, k {a.k}\")\nprint(f\"retrieval  recall@1 {hits(1)}/{answerable}  recall@3 {hits(3)}/{answerable}  recall@5 {hits(5)}/{answerable}\"\n      f\"  MRR {sum(1 / r for r in ranks if r) / answerable:.2f}\")\nprint(f\"answers    correct {correct}/{n}  refused rightly {refused_right}/{n - answerable}  faithful {faithful}/{n}\")\nif a.list:\n    print(\"\\n\".join(rows))\nif correct / n < a.min_correct:\n    print(f\"FAIL: {correct}/{n} correct is below {a.min_correct:.0%}\")\n    sys.exit(1)",
      "note": "Recall at 1, 3 and 5, mean reciprocal rank, and the three answer counts; then the per-question lines if asked for, and a non-zero exit if correctness is under the bar."
    }
  ]
}
```

This section is about the first property.

```
ana@vm:~/rag$ python evaluate.py --split dev
dev: 20 questions, 18 answerable, floor 0.5, k 3
retrieval  recall@1 13/18  recall@3 18/18  recall@5 18/18  MRR 0.86
answers    correct 15/20  refused rightly 2/2  faithful 9/20
```

## Recall at k

**Recall@k** is the share of answerable questions whose answer is in the first k chunks the search
returns. On the dev split it is 13 of 18 at one, and 18 of 18 at three and at five. Lesson 4's
"found" was recall@3 under another name.

Two values matter more than the rest. **Recall at the k the pipeline actually uses**, here three,
says whether the generator was ever given the answer: if it was not, nothing downstream can fix it.
**Recall at one** says how often the answer comes first, which matters because a model is more likely to use
what it reads first and because lesson 12 is going to want fewer
sources, not more.

## Mean reciprocal rank

Recall counts hits and ignores where they landed inside the k. **Mean reciprocal rank** gives a
question 1 when its answer is first, 1/2 when second, 1/3 when third, and 0 when it is not found,
then averages. 0.86 here: 13 questions at 1 and 5 at 1/2, divided by 18. MRR is a single number that
moves when an answer climbs from third to first, which recall@3 does not see, and that makes it the
better number to watch when tuning a reranker or a rewrite.

## What these numbers do not say

**They do not say whether the found chunk was used.** Five of the 18 questions with their answer in
the top three still got a wrong reply, as the next section shows. Good retrieval is necessary and far
from sufficient.

**They depend on the facts being findable.** A chunk counts as holding the answer when it contains the
fact's words. A question whose answer is spread across two chunks, or phrased differently in the
document than in the fact, scores a miss when the search did fine. Writing facts carefully, as the
exact words of the source, is what keeps this honest.

**They are about the dev split.** The held-out run comes at the end of the lesson, once the
comparisons are done.
