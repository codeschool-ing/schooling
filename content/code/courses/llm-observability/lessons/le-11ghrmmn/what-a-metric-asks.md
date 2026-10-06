---
title: What a built-in metric asks
version: 1
---

Most of each framework's metrics are model-graded: a prompt sent to a model of your choosing, and
arithmetic on what comes back. `builtin.py` points DeepEval's answer relevancy at the lab's judge:

```python
"""builtin.py: one of DeepEval's own metrics, answer relevancy, pointed at the lab's judge."""
from deepeval.metrics import AnswerRelevancyMetric
from deepeval.models import OpenAIModel
from deepeval.test_case import LLMTestCase

metric = AnswerRelevancyMetric(model=OpenAIModel(model="judge-1"), async_mode=False)
case = LLMTestCase(input="How much is express delivery?",
                   actual_output="Express delivery is not free at any order value. [1]")
try:
    metric.measure(case)
except Exception as e:
    print(type(e).__name__, e)
```

```
ana@lab:~/obs$ python builtin.py

BadRequestError Error code: 400 - {'error': {'message': 'judge-1 needs a system prompt naming a Criterion and <question> and <reply>', 'type': 'invalid_request_error', 'code': None}}
```

judge-1 refuses, because it answers only prompts that name a criterion and carry a question and a
reply in tags, the shape `judge.py` sends. **No model-graded metric of either framework can run in
this lab**, and this lesson does not pretend otherwise. What the refusal does buy is a look at what
the metric asked, because labobs records every request it receives, refused or not:

```python
"""last_request.py: the last request the lab's model server received, as its log recorded it."""
import json

last = json.loads(open("/var/log/labgen/requests.jsonl").read().splitlines()[-1])
body = last["request"]
print("model ", body["model"], "  status", last["status"])
for m in body["messages"]:
    text = m["content"] if isinstance(m["content"], str) else m["content"][0]["text"]
    print(f"{m['role']}:\n{text}")
```

```
ana@lab:~/obs$ python last_request.py
model  judge-1   status 400
user:
Given the text, breakdown and generate a list of statements presented. Ambiguous statements and single words can be considered as statements, but only if outside of a coherent statement.

Example:
Example text: 
Our new laptop model features a high-resolution Retina display for crystal-clear visuals. It also includes a fast-charging battery, giving you up to 12 hours of usage on a single charge. For security, we’ve added fingerprint authentication and an encrypted SSD. Plus, every purchase comes with a one-year warranty and 24/7 customer support.



{
  "statements": [
    "The new laptop model has a high-resolution Retina display.",
    "It includes a fast-charging battery with up to 12 hours of usage.",
    "Security features include fingerprint authentication and an encrypted SSD.",
    "Every purchase comes with a one-year warranty.",
    "24/7 customer support is included."
  ]
}
===== END OF EXAMPLE ======

**
IMPORTANT: Please make sure to only return in valid and parseable JSON format, with the "statements" key mapping to a list of strings. No words or explanation are needed. Ensure all strings are closed appropriately. Repair any invalid JSON before you output it.
**

Text:
Express delivery is not free at any order value. [1]

JSON:
```

That is the first of the metric's three steps. Answer relevancy in DeepEval asks a model to break the
reply into **statements**, then asks it whether each statement is relevant to the input, then divides
the relevant ones by the total. What the log shows is step one, word for word: an instruction, one
worked example about a laptop, a demand for JSON, and the reply.

Three things in it matter more than the wording:

- **Each metric is several model calls per reply.** This one makes at least two, and the price of a
  framework's metric is the price of all its calls, which lesson 9 taught to count. The span that a
  call like this makes, if the judge's client is instrumented, says how many.
- **The example is part of the instrument.** A judge that follows the laptop example closely splits
  "Express delivery is not free at any order value" differently from one that does not, and the score
  moves with the split. Changing the judge model changes how the prompt is followed.
- **The prompt is in the installed package**, and can be read before the first run. A team adopting a
  framework metric reads its prompt the way it reads a function it calls.

To run this metric for real, the model is one argument: `OpenAIModel(model=...)`, or any class
DeepEval accepts for another provider. Lesson 10's method then applies unchanged: run it on the sixty
labelled replies and measure its kappa before believing a number it reports.
