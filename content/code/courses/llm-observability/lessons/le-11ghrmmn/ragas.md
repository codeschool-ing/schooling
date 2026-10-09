---
title: RAGAS, with and without a model
version: 2
---

RAGAS has a family of metrics that need **no model**: they compare strings. Two of them are context
precision and context recall, the ones lesson 11 computed by its own definition. RAGAS's versions
take **reference contexts**, the text that should have been retrieved, and judge a retrieved chunk
relevant when its string similarity to some reference text is at least 0.5. And it has metrics that
do need one. **Response relevancy** is the one lesson 11 described: a model writes the questions a
reply would answer, and the score is how close those are to the real question, times zero if the
reply is noncommittal.

`ragas_run.py` runs both kinds. The reference contexts are the text of each question's gold chunks, and
lesson 11's numbers for the same questions are printed beside RAGAS's. Response relevancy runs on every
reply, with the local model as its judge; read the comment above `llm` before running it, because it
took three tries to get any score at all out of RAGAS on this machine:

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

```
ana@dev:~/obs$ python ragas_run.py 2>/dev/null
old 2026.09.4, 19 questions with gold and chunks
  RAGAS      precision 0.99   recall 1.00
  lesson 11  precision 1.00   recall 1.00
  response relevancy, answers: 17 replies, 10 with no score, the rest a mean of 0.70
  response relevancy, refusals: 7 replies, 7 with no score
new 2026.10.1, 17 questions with gold and chunks
  RAGAS      precision 1.00   recall 1.00
  lesson 11  precision 1.00   recall 1.00
  response relevancy, answers: 15 replies, 8 with no score, the rest a mean of 0.79
  response relevancy, refusals: 9 replies, 9 with no score
```

**The string metrics agree with lesson 11, nearly exactly.** Precision 0.99 and 1.00, recall 1.00 in
both releases, over the questions where the model was given anything. That is because the references
are the gold chunks themselves, so a retrieved gold chunk matches its reference word for word. Make the
references longer than what one chunk holds, a whole section split across three chunks, and RAGAS's
recall would fall where lesson 11's would not: RAGAS asks whether every reference text was found, and
lesson 11 whether every gold chunk was. **The reference decides the score as much as the metric does**,
and a recall published without saying what the references were cannot be compared with anything.

**Response relevancy scored 14 of the 48 replies.** None of the sixteen refusals has a score, and
eighteen of the answers have none either. For every one of them the local model's reply to one of
RAGAS's prompts could not be parsed, and RAGAS recorded the score as missing and went on, without
stopping the run and without saying so in the table. The program above counts the missing ones
because RAGAS's own mean would quietly skip them. On a first try with RAGAS's defaults, two test
replies got no score at all: one call timed out at three minutes, and for the refusal the model
wrote its question inside a paragraph of explanation. With JSON mode, the same refusal came back
with a question about where Albert Einstein was born, which is the example in RAGAS's own prompt.

So lesson 11's claim, that RAGAS scores the agreed refusal 0 because it is noncommittal, could not be
checked here: with this judge RAGAS gives a refusal no score at all. The fourteen answers it did score
average 0.70 and 0.79, which says little when two thirds of the replies are missing from it. **A mean
over the replies a metric managed to score is a number about the metric**, not about the replies.

None of this is RAGAS being broken. Its metrics are written for models that follow a JSON instruction
every time, and a three-billion-parameter model on a processor does not. With a larger judge most of
the missing scores would appear; the lesson to keep is to count them, every run, beside the mean.
