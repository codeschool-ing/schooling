---
title: A trace with timings
version: 2
---

`run.py` prints the outcome and then one line per step from the trace:

```python
"""Run minagent on one customer message and print the outcome, then the trace."""
import json
import sys

from marginalia import TOOLS
from minagent import Agent, AnthropicModel

SYSTEM = ("You are Marginalia's support agent, built with minagent. Use the tools to find facts, "
          "correct a call when a tool returns an error, and then answer the customer.")

agent = Agent(AnthropicModel(), SYSTEM, TOOLS, max_steps=6, trace_path="trace.jsonl")
outcome = agent.run(sys.argv[1])
print(f"{outcome.status} after {outcome.steps} steps, {outcome.tokens} tokens")
print(outcome.answer or outcome.reason)
for r in outcome.trace:
    calls = ", ".join(f"{c['tool']}{' ERROR' if c['error'] else ''} {c['ms']} ms" for c in r["calls"])
    print(f"  step {r['step']}: model {r['model_ms']} ms, {r['tokens_in']} in / {r['tokens_out']} out"
          + (f"; {calls}" if calls else ""))
```

A customer asks about returning *Dracula* and types the order id without its hyphen:

```
ana@lab:~/agents$ python run.py "Can I return the copy of Dracula I bought in September? My order is M1047."
answered after 2 steps, 672 tokens
I apologize for the error. It looks like the order ID "M1047" does not match the expected format of "M-YYYY". Could you please try again with a different order ID, or provide the full order details so I can assist you further?
  step 1: model 6033 ms, 434 in / 18 out; get_order ERROR 0 ms
  step 2: model 6621 ms, 166 in / 54 out
```

The answer is the end of it, and here it is a poor one: the model asks the customer for a different id and describes the format as "M-YYYY". The trace is how it got there, and with timings it says where the time went:

- **Step 1: the schema did its job.** `get_order ERROR 0 ms`: `M1047` failed the pattern before any function ran, which is why it took no time. The model's half of the step took 6033 ms for 18 output tokens, most of it reading a prompt of 434 tokens on four processors.
- **Step 2: no corrected call.** The error went back to the model, which could not call again (lesson 1's section 07) and answered instead, in 6621 ms. A model that can call again makes the fix in this step, as section 09's tests show with a fake model.

The two numbers to take away are where the time went, the model and not the tools, and how little of it the tools needed. The other runs say the same: the refund's answer took 14626 ms for 139 tokens, the tracking answer 14249 ms for 116. **The model's writing dominates the run**, here and with any provider: long answers cost time in proportion to their length.

The input column is smaller on step 2 than on step 1, 166 against 434, although step 2 carries everything step 1 did. Lesson 1 found why: this model's template leaves the tool definitions out once a tool result is the last message.

## The file behind it

`trace.jsonl` gets one line per step, appended as the run goes. After the three runs of this lesson it has six, and the last is the answer to the tracking question:

```
ana@lab:~/agents$ wc -l trace.jsonl
6 trace.jsonl
ana@lab:~/agents$ tail -n 1 trace.jsonl
{"step": 2, "stop": "end_turn", "tokens_in": 275, "tokens_out": 116, "model_ms": 14249, "text": "I've located your parcel, M-1043. According to the tracking information, your parcel has the tracking number BR5512340003. The current status of your parcel is \"shipped\", and it was placed on September 28, 2026. You can track the status of your parcel by visiting the tracking website and entering the tracking number. Please note that the parcel has not been delivered yet, and the delivery date is not specified. You can check the latest updates on the status of your parcel by visiting the tracking website or contacting our customer service team.", "calls": []}
```

Every field a person debugging the run needs is there: which step, why the model stopped, the tokens each way, the model's time, what it said, and each call with its arguments, whether it failed, how long it took and the first 120 characters of what came back. Lesson 3 said what a trace should hold; this one holds it with timings, which turns *"the agent is slow"* into a step and a tool.

Two cautions carry over from lesson 3. A trace is data about customers, and `result` copies part of every tool's output into a file, so it needs the same care as any other log of personal data. And the timings are this run's, on this machine: a small model on four processors, and tools that vary with what else the machine is doing. They are evidence about this run and not a benchmark.
