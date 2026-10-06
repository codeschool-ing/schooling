---
title: RAGAS without a model
version: 1
---

RAGAS has a family of metrics that need **no model**: they compare strings. Two of them are context
precision and context recall, the ones lesson 11 computed by its own definition. RAGAS's versions take
**reference contexts**, the text that should have been retrieved, and judge a retrieved chunk relevant
when its string similarity to some reference text is at least 0.5.

`ragas_run.py` gives RAGAS the text of every chunk in each question's gold sections as reference
contexts, runs both metrics through `evaluate`, and prints lesson 11's numbers for the same questions
beside them:

```python
"""ragas_run.py: RAGAS's context precision and recall that need no model, beside lesson 11's own, per release.

The reference contexts are the text of every chunk in the question's gold sections."""
import json
from statistics import mean

import psycopg
from ragas import EvaluationDataset, SingleTurnSample, evaluate
from ragas.metrics import NonLLMContextPrecisionWithReference, NonLLMContextRecall

cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}
by_section, section = {}, {}
for cid, doc, path, text in psycopg.connect().execute("SELECT id, doc_id, path, text FROM chunks ORDER BY doc_id, position"):
    section[cid] = (doc, path.split(" > ")[-1])
    by_section.setdefault(section[cid], []).append(text)


def ours(chunks, gold):
    """Lesson 11's two definitions: precision weighted by rank over chunks in a gold section,
    recall as the share of gold sections at least one chunk came from."""
    hits = [section[c] in gold for c in chunks]
    at = [sum(hits[:i + 1]) / (i + 1) for i, h in enumerate(hits) if h]
    return (sum(at) / len(at) if at else 0.0), sum(g in {section[c] for c in chunks} for g in gold) / len(gold)


for run in ("old", "new"):
    rows = [json.loads(line) for line in open(f"runs/{run}.jsonl")]
    samples, own = [], []
    for r in rows:
        gold = [tuple(g) for g in cases[r["id"]]["gold"]]
        if not gold or not r["sources"]:
            continue   # RAGAS needs both lists non-empty; lesson 11 left these out too
        samples.append(SingleTurnSample(user_input=r["question"], response=r["reply"],
                                        retrieved_contexts=[s["text"] for s in r["sources"]],
                                        reference_contexts=[t for g in gold for t in by_section[g]]))
        own.append(ours([s["id"] for s in r["sources"]], gold))
    scores = evaluate(EvaluationDataset(samples=samples), show_progress=False,
                      metrics=[NonLLMContextPrecisionWithReference(), NonLLMContextRecall()]).to_pandas()
    print(f"{run} {rows[0]['release']}, {len(samples)} questions with gold and chunks")
    print(f"  RAGAS      precision {scores['non_llm_context_precision_with_reference'].mean():.2f}"
          f"   recall {scores['non_llm_context_recall'].mean():.2f}")
    print(f"  lesson 11  precision {mean(p for p, _ in own):.2f}   recall {mean(r for _, r in own):.2f}")
```

```
ana@lab:~/obs$ python ragas_run.py
old 2026.09.4, 20 questions with gold and chunks
  RAGAS      precision 0.91   recall 0.72
  lesson 11  precision 0.91   recall 0.95
new 2026.10.1, 16 questions with gold and chunks
  RAGAS      precision 0.94   recall 0.48
  lesson 11  precision 0.94   recall 0.91
```

**Precision agrees exactly, and recall does not, by a lot.** Under the new release RAGAS says the
search found less than half of what it should; lesson 11 says it found nine tenths.

Both are right about different things. Lesson 11 asks, for each gold **section**, whether any chunk from
it was given to the model. RAGAS asks, for each reference **text**, whether some retrieved chunk is
similar to it, and the references here are every chunk of every gold section. A section split into
three chunks of which the search returned one counts as found in lesson 11 and as one in three in
RAGAS. The new release returns one chunk for most questions, so the difference is largest there.

Which one is the right recall depends on what the answer needs. If one chunk of a section is enough to
answer, lesson 11's is the honest measure; if the answer is spread across the section, RAGAS's is. That
is a property of the questions, and it is decided when the references are written, not when the
metric is chosen.

**And the reference decides the score as much as the metric does.** Change the reference contexts and
the same metric reports a different recall for the same retrieval. A recall published without saying
what the reference contexts were cannot be compared with anything.
