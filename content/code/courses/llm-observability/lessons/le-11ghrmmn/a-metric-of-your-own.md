---
title: A metric of your own
version: 1
---

What a framework gives without a model is its **structure**: test cases, a runner, a report, a
cache, a pytest integration. A metric is any class that can say a score, a reason and whether it
passed, so the checks this course already has can run inside DeepEval as they are.

`deepeval_run.py` writes two. `JudgeRelevance` is lesson 10's judge with its refusal rule.
`FactCheck` is lesson 8's normalised fact check, reading the facts from the test case's metadata:

```python
"""deepeval_run.py: the sixty replies of lesson 10 as DeepEval test cases, graded by two metrics written here."""
import json
from collections import defaultdict

from deepeval import evaluate
from deepeval.evaluate.configs import AsyncConfig, DisplayConfig
from deepeval.metrics import BaseMetric
from deepeval.test_case import LLMTestCase

import checks
import judge
from facts import normalised

cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}


class JudgeRelevance(BaseMetric):
    """judge-1's relevance verdict, the agreed refusal passed by rule as lesson 10 decided."""
    threshold = 0.5

    def measure(self, case, *args, **kwargs):
        if checks.is_refusal(case.actual_output):
            self.score, self.reason = 1.0, "the agreed refusal, passed by rule"
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
        return "judge-1 relevance"


class FactCheck(BaseMetric):
    """Lesson 8's normalised fact check: the expected fact is in the reply, or an unanswerable question was refused."""
    threshold = 0.5

    def measure(self, case, *args, **kwargs):
        facts = case.metadata["facts"]
        self.score = float(normalised(case.actual_output, facts))
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


tests = []
for run in ("old", "new"):
    for r in map(json.loads, open(f"runs/{run}.jsonl")):
        tests.append(LLMTestCase(name=f"{r['id']} {r['release']}", input=r["question"], actual_output=r["reply"],
                                 retrieval_context=[s["text"] for s in r["sources"]],
                                 metadata={"facts": cases[r["id"]]["facts"], "release": r["release"]}))
result = evaluate(tests, [JudgeRelevance(), FactCheck()], async_config=AsyncConfig(run_async=False),
                  display_config=DisplayConfig(print_results=False, show_indicator=False))
passed = defaultdict(int)
for t in result.test_results:
    for m in t.metrics_data:
        passed[t.metadata["release"], m.name] += m.success
for release in ("2026.09.4", "2026.10.1"):
    print(release, "  ".join(f"{name} {passed[release, name]}/30" for name in ("judge-1 relevance", "fact check")))
```

DeepEval prints a banner, a warning and a summary of its own, with a few emoji the page cannot draw; the
`grep` keeps the summary's pass rate and the script's two lines:

```
ana@lab:~/obs$ python deepeval_run.py | grep -E "Pass Rate|^2026"
   » Pass Rate: 58.33% | Passed: 35 | Failed: 25
2026.09.4 judge-1 relevance 30/30  fact check 19/30
2026.10.1 judge-1 relevance 30/30  fact check 16/30
```

The two lines at the bottom are the script's own counts, from the results DeepEval returns, and they agree with
what this course measured without a framework: judge-1 passes every reply, as lesson 10 found, and the
facts are in 19 and 16 replies of 30, as lesson 8 found. Wrapping a check in a framework adds no
knowledge; it adds the machinery around the check.

DeepEval's own summary says **35 passed and 25 failed**. A test case passes in DeepEval only when
every metric on it passes, so the 25 are exactly the replies the fact check failed. That is a reasonable
rule for a test and a poor one for a report, because it hides which metric failed; the per-metric counts
are the report.

## What the machinery is worth

- **One shape for every check.** The judge, the facts and a framework metric take the same test case
  and return the same score, reason and success, so adding a metric is one line in a list.
- **A runner.** `evaluate()` ran 60 cases and two metrics, and with `run_async=True` it would have run
  them concurrently. Here it runs one at a time, so the order of calls to judge-1 is the same on every
  run.
- **A record.** The `.deepeval` folder holds the last run in full.

```
ana@lab:~/obs$ ls -a .deepeval
.
..
.deepeval-cache.json
.latest_run_full.json
.latest_test_run.json
```

The record is useful and, as the first section said, it is customers' text: those files need the same
care as a trace.

What the machinery does not do is decide whether a metric measures anything. That is still lesson 10's
work, and no framework does it for you.
