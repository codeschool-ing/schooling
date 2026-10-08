---
title: What a built-in metric asks
version: 1
---

Most of each framework's metrics are model-graded: a prompt sent to a model of your choosing, and
arithmetic on what comes back. `builtin.py` points DeepEval's answer relevancy at the lab's judge:

```python
"""builtin.py: two of DeepEval's own metrics on the reply lesson 8 found, with the local model as their judge.

The model is reached through flaky.py, lesson 4's proxy, so that flaky.log
counts the calls each metric makes.
"""
import json
import os
import time

from deepeval.metrics import AnswerRelevancyMetric, FaithfulnessMetric
from deepeval.models import LocalModel
from deepeval.test_case import LLMTestCase

text = {c["id"]: c["text"] for c in json.load(open("data/index.json"))["chunks"]}
model = LocalModel(model="llama3.2:3b", base_url="http://127.0.0.1:11435/v1", api_key="ollama", temperature=0)
case = LLMTestCase(input="Who pays for the return postage?",
                   actual_output="According to [1], the customer pays for the return postage.",
                   retrieval_context=[text["returns-policy:how-to-start-a-return"]])
calls = lambda: sum(1 for _ in open("flaky.log")) if os.path.exists("flaky.log") else 0
for metric in (AnswerRelevancyMetric(model=model, async_mode=False), FaithfulnessMetric(model=model, async_mode=False)):
    before, started = calls(), time.monotonic()
    metric.measure(case)
    print(f"{type(metric).__name__}: score {metric.score}, {calls() - before} model calls, "
          f"{time.monotonic() - started:.0f} s")
    for step in ("statements", "claims", "truths"):
        if getattr(metric, step, None):
            print(f"  {step}: {getattr(metric, step)}")
    print("  verdicts:", [v.verdict for v in metric.verdicts])
    print("  reason:", metric.reason)
```

CAPTURE:builtin

PROSE:builtin
