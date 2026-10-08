---
title: What a built-in metric asks
version: 2
---

Most of each framework's metrics are model-graded: a prompt sent to a model of your choosing, and
arithmetic on what comes back. DeepEval reaches a model that speaks OpenAI's API, Ollama included,
through its `LocalModel` class. `builtin.py` runs two of DeepEval's metrics, answer relevancy and
faithfulness, on the reply lesson 8 found, the one that tells a customer they pay the return postage.
Start lesson 4's `flaky.py` first, with `python flaky.py &` in `~/obs`: the metrics reach the model
through it, and its log counts their calls.

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

Both verdicts are right. The reply is about who pays for the postage, so it is relevant, and it says
the opposite of its source, so it is not faithful. And the steps printed under each score show how a
metric reaches its number, which is the part worth learning:

- **Answer relevancy** asked the model to break the reply into **statements**, then whether each is
  relevant to the question, and divided the yeses by the total. One statement, one yes, 1.0.
- **Faithfulness** asked for the reply's **claims** and for the **truths** in the retrieved text, then
  whether each claim is supported by the truths. "The customer pays" against "Returns are free": no,
  and the score is 0.

Three things in that output matter more than the scores:

- **Each metric is several model calls per reply**: three for relevancy and four for faithfulness here,
  nine and twelve seconds on this machine. The price of a framework's metric is the price of all its
  calls, which lesson 9 taught to count, and a metric on every reply of a week is that many calls times
  the week.
- **The reason is a separate call, and it can be wrong when the score is right.** Faithfulness scored
  0 and explained it as "there are no contradictions in the actual output", the opposite of what its
  own verdict found. Lesson 9's judge did the same. Read the steps, not the sentence at the end.
- **The prompts are in the installed package**, one text file per step, under
  `deepeval/metrics/answer_relevancy/templates/` and its neighbours, and they can be read before the
  first run. The statements prompt works from an example about a laptop; a small model that follows
  the example too closely splits a reply differently, and the score moves with the split. A team
  adopting a framework metric reads its prompts the way it reads a function it calls.

Lesson 10's method then applies unchanged: run the metric on the forty-eight labelled replies and
measure it against people before believing a number it reports.
