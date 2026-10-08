---
title: A metric of your own
version: 2
---

What a framework gives without a model is its **structure**: test cases, a runner, a report, a
cache, a pytest integration. A metric is any class that can say a score, a reason and whether it
passed, so the checks this course already has can run inside DeepEval as they are.

`deepeval_run.py` writes two. `JudgeRelevance` is lesson 10's judge with its refusal rule.
`FactCheck` is lesson 8's normalised fact check, reading the facts from the test case's metadata. And
beside them it runs one of DeepEval's own, faithfulness, with the local model as its judge, on all
forty-eight replies. A refusal retrieved nothing, and faithfulness refuses an empty context, so those
cases carry a placeholder saying so:

```python
"""deepeval_run.py: the forty-eight replies of lesson 10 as DeepEval test cases, under two metrics
written here and one of DeepEval's own."""
import json
from collections import defaultdict

from deepeval import evaluate
from deepeval.evaluate.configs import AsyncConfig, DisplayConfig, ErrorConfig
from deepeval.metrics import BaseMetric, FaithfulnessMetric
from deepeval.models import LocalModel
from deepeval.test_case import LLMTestCase

import checks
import judge
from facts import normalised

cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}


class JudgeRelevance(BaseMetric):
    """The judge's relevance verdict, with the refusal decided by the answer key as lesson 10 did."""
    threshold = 0.5

    def measure(self, case, *args, **kwargs):
        if checks.is_refusal(case.actual_output):
            self.score = 0.0 if case.metadata["facts"] else 1.0
            self.reason = "the agreed refusal, decided by the answer key"
        else:
            v = judge.grade("relevance", case.input, case.actual_output,
                            [{"id": "", "text": t} for t in case.retrieval_context])
            self.score, self.reason = float(v["verdict"] == "pass"), v["reason"]
        self.success = self.score >= self.threshold
        return self.score

    async def a_measure(self, case, *args, **kwargs):
        return self.measure(case)

    def is_successful(self):
        return self.success

    @property
    def __name__(self):
        return "judge relevance"


class FactCheck(BaseMetric):
    """Lesson 8's normalised fact check: the expected fact is in the reply, or an unanswerable question was refused."""
    threshold = 0.5

    def measure(self, case, *args, **kwargs):
        self.score = float(normalised(case.actual_output, case.metadata["facts"]))
        self.reason = "fact found" if self.score else "fact missing"
        self.success = self.score >= self.threshold
        return self.score

    async def a_measure(self, case, *args, **kwargs):
        return self.measure(case)

    def is_successful(self):
        return self.success

    @property
    def __name__(self):
        return "fact check"


model = LocalModel(model="llama3.2:3b", base_url="http://127.0.0.1:11434/v1", api_key="ollama", temperature=0)
tests = []
for run in ("old", "new"):
    for r in map(json.loads, open(f"runs/{run}.jsonl")):
        tests.append(LLMTestCase(name=f"{r['id']} {r['release']}", input=r["question"], actual_output=r["reply"],
                                 retrieval_context=[s["text"] for s in r["sources"]] or ["(nothing was retrieved)"],
                                 metadata={"facts": cases[r["id"]]["facts"], "release": r["release"]}))
metrics = [JudgeRelevance(), FactCheck(), FaithfulnessMetric(model=model, async_mode=False)]
# ignore_errors: a metric that fails on one case is recorded as an error, and the run goes on
result = evaluate(tests, metrics, async_config=AsyncConfig(run_async=False),
                  display_config=DisplayConfig(print_results=False, show_indicator=False),
                  error_config=ErrorConfig(ignore_errors=True))
passed, errors = defaultdict(int), defaultdict(int)
for t in result.test_results:
    for m in t.metrics_data:
        if m.error:
            errors[t.metadata["release"], m.name] += 1
            continue
        passed[t.metadata["release"], m.name] += m.success
        if m.name == "Faithfulness" and not m.success:
            print(f"  faithfulness failed {t.name}: {t.actual_output[:60]}")
for release in ("2026.09.4", "2026.10.1"):
    print(release, "  ".join(f"{name} {passed[release, name]}/24"
                             + (f" ({errors[release, name]} errors)" if errors[release, name] else "")
                             for name in ("judge relevance", "fact check", "Faithfulness")))
```

DeepEval prints a banner, a warning and a summary of its own, with a few emoji the page cannot draw; the
`grep` keeps the summary's pass rate and the script's two lines:

CAPTURE:deepeval

The `grep` keeps the script's own lines and drops DeepEval's banner and summary. Read the two counts at
the bottom first, then the list above them.

**The checks this course wrote come through unchanged.** The fact check passes 22 and 18 replies of
24, lesson 8's arithmetic inside DeepEval's runner. The judge's relevance passes 15 and 16, with the
refusals decided by the answer key as lesson 10 did. Wrapping a check in a framework adds no knowledge;
it adds the machinery around it.

**DeepEval's faithfulness gave a number for twenty replies of forty-eight.** For the other 28 the
local model's answer at one of its steps was not the JSON the metric asked for, and the metric stopped
with DeepEval's own advice: *"Evaluation LLM outputted an invalid JSON. Please use a better evaluation
model."* Without `ignore_errors` the first of those stops the whole run, which is what happened the
first time this script ran. With it, each failure is an error on its case, counted beside the score.

**And of the eleven replies it failed, one is unfaithful.** e02 under the new release, the reply that
contradicts its source, is in the list, rightly. So are the return window, the price of express
delivery, the delivery time, the free-delivery threshold, the invoice and the Kindle, each of which says
what its source says, and a refusal, which says nothing at all. A metric that scores fewer than half the replies, and is wrong on ten of its eleven
failures, is not measuring faithfulness with this judge, whatever its name. That is the advice in the
error message, and lesson 10's method would have said the same before the number reached a report.

One more thing the list shows: e12 under the new release is not the refusal it was in lesson 10. The
runs were made again for this capture, and this time the model answered the Kindle question. Replies
move from one run to the next, at temperature 0, which is why every lesson that grades replies keeps
the run it graded.

## What the machinery is worth

- **One shape for every check.** The judge, the facts and a framework metric take the same test case
  and return the same score, reason and success, so adding a metric is one line in a list.
- **A runner.** `evaluate()` ran 48 cases and three metrics, recording an error per case instead of
  stopping when asked to. With `run_async=True` it would run them concurrently; here it runs one at a
  time, because the judge shares one processor with everything else.
- **A record.** The `.deepeval` folder holds the last run in full.

CAPTURE:ls

The record is useful and, as the first section said, it is customers' text: those files need the same
care as a trace.

What the machinery does not do is decide whether a metric measures anything. That is still lesson 10's
work, and no framework does it for you.
