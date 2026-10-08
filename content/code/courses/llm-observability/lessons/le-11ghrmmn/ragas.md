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
"""ragas_run.py: RAGAS on the forty-eight replies of lesson 10. Its context precision and recall that
need no model, beside lesson 11's own, and its response relevancy with the local model as judge.

The reference contexts are the text of each question's gold chunks."""
import json
import math
from statistics import mean

from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from ragas import EvaluationDataset, RunConfig, SingleTurnSample, evaluate
from ragas.embeddings import LangchainEmbeddingsWrapper
from ragas.llms import LangchainLLMWrapper
from ragas.metrics import NonLLMContextPrecisionWithReference, NonLLMContextRecall, ResponseRelevancy

import checks

cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}
text = {c["id"]: c["text"] for c in json.load(open("data/index.json"))["chunks"]}
# One call at a time, ten minutes each, and JSON mode: without these a small model on a processor
# times out at RAGAS's default of three minutes, or answers in prose RAGAS cannot parse.
llm = LangchainLLMWrapper(ChatOpenAI(model="llama3.2:3b", temperature=0,
                                     model_kwargs={"response_format": {"type": "json_object"}}))
embeddings = LangchainEmbeddingsWrapper(OpenAIEmbeddings(model="all-minilm", check_embedding_ctx_length=False))
slow = RunConfig(max_workers=1, timeout=600)


def ours(chunks, gold):
    """Lesson 11's two definitions: precision weighted by rank, recall as the share of gold chunks given."""
    hits = [c in gold for c in chunks]
    at = [sum(hits[:i + 1]) / (i + 1) for i, h in enumerate(hits) if h]
    return (sum(at) / len(at) if at else 0.0), sum(g in chunks for g in gold) / len(gold)


for run in ("old", "new"):
    rows = [json.loads(line) for line in open(f"runs/{run}.jsonl")]
    with_context = [r for r in rows if cases[r["id"]]["gold"] and r["sources"]]   # RAGAS needs both
    context = evaluate(EvaluationDataset(samples=[SingleTurnSample(
        user_input=r["question"], response=r["reply"], retrieved_contexts=[s["text"] for s in r["sources"]],
        reference_contexts=[text[g] for g in cases[r["id"]]["gold"]]) for r in with_context]),
        metrics=[NonLLMContextPrecisionWithReference(), NonLLMContextRecall()], show_progress=False).to_pandas()
    own = [ours([s["id"] for s in r["sources"]], cases[r["id"]]["gold"]) for r in with_context]
    relevancy = evaluate(EvaluationDataset(samples=[SingleTurnSample(user_input=r["question"], response=r["reply"])
                                                    for r in rows]),
                         metrics=[ResponseRelevancy(llm=llm, embeddings=embeddings)], show_progress=False,
                         run_config=slow).to_pandas()["answer_relevancy"].tolist()
    print(f"{run} {rows[0]['release']}, {len(with_context)} questions with gold and chunks")
    print(f"  RAGAS      precision {context['non_llm_context_precision_with_reference'].mean():.2f}"
          f"   recall {context['non_llm_context_recall'].mean():.2f}")
    print(f"  lesson 11  precision {mean(p for p, _ in own):.2f}   recall {mean(r for _, r in own):.2f}")
    for kind in ("answers", "refusals"):
        scores = [s for r, s in zip(rows, relevancy) if checks.is_refusal(r["reply"]) == (kind == "refusals")]
        got = [s for s in scores if not math.isnan(s)]
        print(f"  response relevancy, {kind}: {len(scores)} replies, {len(scores) - len(got)} with no score"
              + (f", the rest a mean of {mean(got):.2f}" if got else ""))
```

CAPTURE:ragas

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
