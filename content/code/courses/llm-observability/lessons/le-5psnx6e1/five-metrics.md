---
title: Five metrics, each with its definition
version: 1
---

Evaluation frameworks for retrieval-augmented generation report a family of metrics with similar names.
Four of them are the ones teams quote, and a fifth is the one lesson 8 built:

| Metric | Question it answers | Needs a reference? |
| --- | --- | --- |
| context precision | are the chunks the model was given the right ones, and near the top? | yes: which chunks hold the answer |
| context recall | did the model get every chunk the answer needs? | yes: the same |
| faithfulness | is every statement in the reply supported by those chunks? | no |
| relevance | does the reply address the question? | no |
| correctness | is the reply the right answer? | yes: the expected answer |

The column on the right is the one that decides where a metric can run. **The three that need a
reference work on an evaluation set only**, where somebody wrote down the answer and where it lives.
The two that need none, faithfulness and relevance, can run on production traffic, which is why lesson
9's judge graded those two.

`metrics.py` computes all five for a run, each in a function a few lines long whose docstring is its
definition. The reference for context precision and recall is the evaluation set's `gold`: for each
question, the sections of the documents that hold its answer, written by `rag` when the set was made.
A chunk belongs to a gold section when it comes from the same document and its path ends with that
section's heading:

```python
"""metrics.py: five numbers for each run of the evaluation set, each defined in its function.

    python metrics.py old new
"""
import json
import sys

import checks
import judge
import telemetry
from facts import normalised

cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}


def context_precision(chunks, gold):
    """How high the gold chunks sit among those the model was given: the precision at each gold
    chunk's rank, averaged. None when nothing was given."""
    if not chunks:
        return None
    hits = [c in gold for c in chunks]
    at = [sum(hits[:i + 1]) / (i + 1) for i, h in enumerate(hits) if h]
    return sum(at) / len(at) if at else 0.0


def context_recall(chunks, gold):
    """The share of the gold chunks that the model was given. None when there is no gold."""
    if not gold:
        return None
    return sum(g in chunks for g in gold) / len(gold)


def faithfulness(r):
    """The judge's score for whether the reply's statements are supported by its sources."""
    return judge.grade("faithfulness", r["question"], r["reply"], r["sources"])["score"]


def relevance(r, case):
    """The judge's relevance verdict, with the refusal decided by the answer key as lesson 10 did."""
    if checks.is_refusal(r["reply"]):
        return 0.0 if case["facts"] else 1.0
    return float(judge.grade("relevance", r["question"], r["reply"], r["sources"])["verdict"] == "pass")


def correctness(r, case):
    """Lesson 8's normalised fact check: the fact is in the reply, or an unanswerable question was refused."""
    return float(normalised(r["reply"], case["facts"]))


telemetry.setup("judge-spans.jsonl", service="judge")
mean = lambda xs: sum(x for x in xs if x is not None) / len([x for x in xs if x is not None])
count = lambda xs: len([x for x in xs if x is not None])
print("run  release  " + "".join(f"{h:>16}" for h in ("ctx precision", "ctx recall", "faithfulness", "relevance", "correctness")))
for name in sys.argv[1:]:
    run = [json.loads(line) for line in open(f"runs/{name}.jsonl")]
    cols = {"p": [], "r": [], "f": [], "v": [], "c": []}
    for r in run:
        case = cases[r["id"]]
        chunks = [s["id"] for s in r["sources"]]
        cols["p"].append(context_precision(chunks, set(case["gold"])))
        cols["r"].append(context_recall(chunks, case["gold"]))
        cols["f"].append(faithfulness(r))
        cols["v"].append(relevance(r, case))
        cols["c"].append(correctness(r, case))
    print(f"{name:4} {run[0]['release']}" + "".join(f"{mean(v):>9.2f} (n={count(v):2})" for v in cols.values()))
```

Three of the definitions are choices worth noticing:

- **Context precision weighs rank.** It averages the precision at the position of each gold chunk, so a
  right chunk first scores higher than the same chunk third. That is the definition RAGAS uses; a plain
  share of right chunks is another, and would give different numbers for the same retrieval.
- **A refusal with no chunks has no context precision**, rather than a precision of zero or one. Nothing
  was given, so nothing can be right or wrong about it. It still has a context recall of zero when the
  question had an answer, because the answer was not given to the model.
- **Relevance passes the refusal by rule.** That is lesson 10's rubric. A framework that scores a refusal
  as irrelevant measures something else under the same name, and the last section of this lesson finds
  one that does.
