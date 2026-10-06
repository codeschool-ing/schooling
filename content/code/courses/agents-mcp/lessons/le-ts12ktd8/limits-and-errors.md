---
title: Limits, and what a failure says
version: 1
---

## The step limit raises

```
ana@lab:~/agents$ python oa_run.py "Where is my order M-1043?" 2
stopped: Max turns (2) exceeded
```

With `max_turns=2`, the run that needs three requests stopped and raised `MaxTurnsExceeded`. Compare lesson 5 and lesson 7, where a limit produced an outcome with a reason and a handoff. **The SDK's choice is an exception**, so the program decides what the customer sees: `oa_run.py` catches it and prints a line. A program that does not catch it crashes on the first long run, which is a reason to wrap every `Runner.run` in the handling lesson 5 described.

## The default error message hides the error

Two runs that each hit a failing tool call: an order that does not exist, and an id the course's stand-in sends without its prefix. Then the last line prints what the model actually received as each tool result:

```
ana@lab:~/agents$ python oa_run.py "What happened to my order M-9999?" | tail -n 1
answer: I cannot find an order M-9999. Could you check the number in your confirmation email?
ana@lab:~/agents$ python oa_run.py "Where is my order 1044?" | tail -n 1
answer: Order M-1044 was delivered on 14 August 2026.
ana@lab:~/agents$ python -c 'import json; [print(m["content"][:150]) for r in map(json.loads, open("/var/log/labllm/requests.jsonl")) for m in r["request"]["messages"][-1:] if m["role"] == "tool"]'
An error occurred while running the tool. Please try again.
An error occurred while running the tool. Please try again.
{'id': 'M-1044', 'customer_id': 'c-103', 'placed_on': '2026-08-11', 'status': 'delivered', 'delivered_on': '2026-08-14', 'shipping': 0, 'tracking': 'B
```

Both failures reached the model as the same sentence: *"An error occurred while running the tool. Please try again."* Nothing says whether the order is missing or the id is malformed. The scripted model answered sensibly because the course wrote it to; **a real model told "try again" would most likely try the same call again**, and lesson 4's whole argument was that an error has to say what failed.

The fix is one argument. `failure_error_function` decides what the model reads when a tool raises:

```schooling-example
{
  "language": "python",
  "file": "oa_tools.py",
  "parts": [
    {
      "code": "\"\"\"Marginalia's tools for the OpenAI Agents SDK: shop.py's functions, decorated.\"\"\"\nfrom typing import Annotated, Literal\n\nfrom agents import function_tool\nfrom pydantic import Field\n\nimport shop\n\n\n"
    },
    {
      "code": "def say_what_failed(ctx, error):\n    \"\"\"What the model reads when a tool fails: the error itself, not a generic apology.\"\"\"\n    return f\"{type(error).__name__}: {error}\"\n\n\n",
      "note": "**The error's type and message, as the model will read them.** This is lesson 4's `run_tool` rule in two lines."
    },
    {
      "code": "@function_tool(failure_error_function=say_what_failed)\ndef get_order(order_id: Annotated[str, Field(pattern=\"^M-[0-9]{4}$\")]) -> dict:\n    \"\"\"Look up one Marginalia order by its id, M- and four digits. Returns status, dates, lines and amounts in cents.\"\"\"\n    return shop.get_order(order_id)\n\n\n@function_tool\ndef search_help(query: str) -> list[dict]:\n    \"\"\"Search Marginalia's help centre by meaning and return the three closest articles.\"\"\"\n    return [{\"title\": a[\"title\"], \"body\": a[\"body\"]} for a in shop.search_help(query)]\n\n\n@function_tool(needs_approval=True)\ndef refund(order_id: Annotated[str, Field(pattern=\"^M-[0-9]{4}$\")], cents: int, reason: str) -> dict:\n    \"\"\"Refund part or all of an order to the customer's original payment, in cents.\"\"\"\n    return shop.refund(order_id, cents, reason, approved_by=\"ana\")",
      "note": "**Applied to `get_order`.** The other tools keep the default, to show the difference."
    }
  ]
}
```

```
ana@lab:~/agents$ python oa_run.py "What happened to my order M-9999?" | tail -n 1
answer: I cannot find an order M-9999. Could you check the number in your confirmation email?
ana@lab:~/agents$ python oa_run.py "Where is my order 1044?" | tail -n 1
answer: Order M-1044 was delivered on 14 August 2026.
ana@lab:~/agents$ python -c 'import json; [print(m["content"][:150]) for r in map(json.loads, open("/var/log/labllm/requests.jsonl")) for m in r["request"]["messages"][-1:] if m["role"] == "tool"]'
LookupError: no order M-9999
ModelBehaviorError: Invalid JSON input for tool get_order
{'id': 'M-1044', 'customer_id': 'c-103', 'placed_on': '2026-08-11', 'status': 'delivered', 'delivered_on': '2026-08-14', 'shipping': 0, 'tracking': 'B
```

Now the missing order says `LookupError: no order M-9999`, which a model can act on. The malformed id says `ModelBehaviorError: Invalid JSON input for tool get_order`: better than nothing, and still vaguer than lesson 4's `'1043' does not match '^M-[0-9]{4}$'`, because the SDK's validation error does not name the field or the rule. A tool that cares can take the argument as a plain `str` and check the pattern itself, raising a `ValueError` whose message says exactly what was wrong.
