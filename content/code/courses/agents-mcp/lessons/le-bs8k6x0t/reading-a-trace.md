---
title: Reading a run back
version: 1
---

An agent decides its path while it runs, so the only way to know what it did is to have written it down. `react_native.py` appends one JSON line per step to `trace.jsonl`, and `show_trace.py` prints it:

```python
"""Print trace.jsonl as one block per step: what the model said, what it called, what came back."""
import json

for line in open("trace.jsonl"):
    r = json.loads(line)
    print(f"step {r['step']}  stop_reason={r['stop_reason']}  input_tokens={r['input_tokens']}")
    print(f"  said:     {r['text'][:96]}")
    for c in r["calls"]:
        print(f"  called:   {c['tool']}({json.dumps(c['input'])})")
        print(f"  returned: {c.get('output', 'refused: ' + c.get('refused', ''))[:72]}")
```

For the M-1047 run of section 05:

```
ana@lab:~/agents$ python show_trace.py
step 1  stop_reason=tool_use  input_tokens=184
  said:     I need the order's delivery date and total before I can answer.
  called:   get_order({"order_id": "M-1047"})
  returned: {"id": "M-1047", "customer_id": "c-106", "placed_on": "2026-09-15", "sta
step 2  stop_reason=tool_use  input_tokens=321
  said:     Delivered on 18 September, so the window runs to 18 October; now the refund rules.
  called:   search_help({"query": "refund after a return"})
  returned: [{"title": "When your refund arrives", "body": "We refund within three w
step 3  stop_reason=end_turn  input_tokens=544
  said:     Yes. Order M-1047 was delivered on 18 September 2026, so both copies can be returned until 18 Oc
```

Read it the way you would read anybody's working. **Each line of `said` should follow from the `returned` above it.** Step 2's sentence quotes 18 September, which is in step 1's result; step 3's refund timing is in step 2's result. A step whose thought mentions something no earlier result contains is the first place to look when an answer is wrong: that is where the model supplied a fact instead of fetching one.

`input_tokens` tells you how the cost grew: 184, 321, 544, each request carrying every earlier one. `stop_reason` says why each step ended, and the last one must say `end_turn` for a run that finished properly. Anything else on the last line, `max_tokens` or a host message, is a run that was cut short.

## What a trace should hold

The fields are a choice, and these are the ones that answer the questions people ask afterwards:

- **the step number and why it ended**, so a cut-short run is visible;
- **what the model said and what it called, with the exact arguments**, so a wrong call can be traced to the step that chose it;
- **what came back**, truncated: the first 80 characters here, enough to recognise the result without copying a customer's whole order into a log;
- **the size of the request**, so cost per step can be read off.

A trace is also data about people. This one holds an order id and the start of an order, and a real one would hold customers' messages. `ai-security` lesson 11 is about what to keep, redact and delete, and the rule that applies already here is to log what you need to explain a run and no more. Lesson 7 builds a fuller trace with timings, and lesson 18 turns traces into the numbers a team watches.
