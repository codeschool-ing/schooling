---
title: Limits, and what a failure says
version: 2
---

## The step limit raises

```
ana@lab:~/agents$ python oa_run.py "Where is my order M-1043?" 1
stopped: Max turns (1) exceeded
```

With `max_turns=1`, the run that needs two requests stopped and raised `MaxTurnsExceeded`. Compare lesson 5 and lesson 7, where a limit produced an outcome with a reason and a handoff. **The SDK's choice is an exception**, so the program decides what the customer sees: `oa_run.py` catches it and prints a line. A program that does not catch it crashes on the first long run, which is a reason to wrap every `Runner.run` in the handling lesson 5 described.

## The default error message hides the error

Two runs that each meet a failing tool call: an order that does not exist, and an id the customer wrote without its prefix. Then the last command prints what the model actually received as each tool result:

```
ana@lab:~/agents$ rm requests.jsonl
ana@lab:~/agents$ python oa_run.py "What happened to my order M-9999?" | tail -n 1
I apologize for the inconvenience, but I don't have any information on an order with the ID M-9999. Can you please provide more details or context about your order, such as the date or time you placed it, or the status you were expecting? I'll do my best to assist you in tracking down the status of your order.
ana@lab:~/agents$ python oa_run.py "Where is my order 1044?" | tail -n 1
Using the OpenAI Agents SDK, I don't have direct access to the system's database to retrieve the status of order 1044. However, I can suggest that you contact our customer service team directly to inquire about the status of your order. They will be able to provide you with the most up-to-date information. You can reach them at [insert contact information]. Is there anything else I can help you with?
ana@lab:~/agents$ python -c 'import json; [print(i["output"][:150]) for r in map(json.loads, open("requests.jsonl")) for i in r["request"]["input"][-1:] if i.get("type") == "function_call_output"]'
An error occurred while running the tool. Please try again.
An error occurred while running the tool. Please try again.
An error occurred while running the tool. Please try again.
```

Every failure reached the model as the same sentence: *"An error occurred while running the tool. Please try again."* Three times, because for `1044` the model tried twice. Nothing says whether the order is missing or the id is malformed, and the answers show it: for M-9999 the model asked the customer for details, for 1044 it said it had **no access to the database** at all, which is false, and sent the customer to somebody else. Lesson 4's whole argument was that an error has to say what failed.

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
ana@lab:~/agents$ rm requests.jsonl
ana@lab:~/agents$ python oa_run.py "What happened to my order M-9999?" | tail -n 1
answer: I apologize for the inconvenience. It appears that I couldn't find any information on an order with the ID M-9999. Can you please provide more context or details about your order, such as the date of purchase or the store where you made the purchase? I'll do my best to help you find the status of your order.
ana@lab:~/agents$ python oa_run.py "Where is my order 1044?" | tail -n 1
Would you like me to attempt to find your order using our internal systems?
ana@lab:~/agents$ python -c 'import json; [print(i["output"][:150]) for r in map(json.loads, open("requests.jsonl")) for i in r["request"]["input"][-1:] if i.get("type") == "function_call_output"]'
LookupError: no order M-9999
ModelBehaviorError: Invalid JSON input for tool get_order
```

Now the missing order says `LookupError: no order M-9999`, which a model can act on, and the answer is about a missing order. The malformed id says `ModelBehaviorError: Invalid JSON input for tool get_order`: better than nothing, and still vaguer than lesson 4's `'1043' does not match '^M-[0-9]{4}$'`, because the SDK's validation error does not name the field or the rule. The model's reply to it was a question back to the customer, not a corrected call. A tool that cares can take the argument as a plain `str` and check the pattern itself, raising a `ValueError` whose message says exactly what was wrong.
