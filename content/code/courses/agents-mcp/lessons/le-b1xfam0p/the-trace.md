---
title: A trace with timings
version: 1
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
answered after 4 steps, 2401 tokens
Yes. Order M-1047 was delivered on 18 September 2026, and printed books can be returned within 30 days of delivery, so you have until 18 October. Start the return from the order in your account; the label is prepaid and returns are free.
  step 1: model 602 ms, 433 in / 9 out; get_order ERROR 0 ms
  step 2: model 647 ms, 474 in / 10 out; get_order 1 ms
  step 3: model 567 ms, 597 in / 8 out; search_help 1053 ms
  step 4: model 2488 ms, 813 in / 57 out
```

The answer is the end of it. The trace is how it got there, and with timings it says where the time went:

- **Step 1: the schema did its job.** `get_order ERROR 0 ms`: `M1047` failed the pattern before any function ran, which is why it took no time. The model's half of the step took 602 ms for 9 output tokens.
- **Step 2: the corrected call.** `get_order` with `M-1047`, 1 ms: a SQLite lookup on a small file.
- **Step 3: the search.** `search_help` took 1053 ms, the slowest tool in the run, and most of that is loading the embedding model into a fresh process before comparing the query with forty articles. In the next run, the refund of section 06, the same kind of search took 331 ms, most likely because the model's files were by then in the operating system's cache.
- **Step 4: the answer.** 2488 ms for 57 output tokens. **The model's writing dominates the run**: under labllm's rule of 200 ms plus 40 ms a token, and with any real provider, long answers cost time in proportion to their length.

The input column grew from 433 to 813 tokens over four steps, the growth lesson 1 measured, and the 2401-token total is what lesson 18 turns into money.

## The file behind it

`trace.jsonl` gets one line per step, appended as the run goes. After the three runs of this lesson it has eleven, and the last is the third step of the stuck run:

```
ana@lab:~/agents$ wc -l trace.jsonl
11 trace.jsonl
ana@lab:~/agents$ tail -n 1 trace.jsonl
{"step": 3, "stop": "tool_use", "tokens_in": 504, "tokens_out": 10, "model_ms": 647, "text": "", "calls": [{"tool": "parcel_status", "args": {"order_id": "M-1043"}, "error": true, "ms": 0, "result": "unknown tool 'parcel_status'; the tools are get_order, search_help, find_books, refund"}]}
```

Every field a person debugging the run needs is there: which step, why the model stopped, the tokens each way, the model's time, what it said, and each call with its arguments, whether it failed, how long it took and the first 120 characters of what came back. Lesson 3 said what a trace should hold; this one holds it with timings, which turns *"the agent is slow"* into a step and a tool.

Two cautions carry over from lesson 3. A trace is data about customers, and `result` copies part of every tool's output into a file, so it needs the same care as any other log of personal data. And the timings are this run's: the model's come from labllm's rule, and the tools' vary with what else the machine is doing, so they are evidence about this run and not a benchmark.
