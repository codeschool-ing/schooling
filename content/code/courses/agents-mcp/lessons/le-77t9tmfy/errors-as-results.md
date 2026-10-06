---
title: Errors are results
version: 1
---

A tool that fails has two ways to fail: it can take the host down with it, or it can tell the model what went wrong. Only the second gives the model a chance to recover, and only the second leaves the run in a state anybody can explain.

```
ana@lab:~/agents$ python agent.py "What happened to my order M-9999?"
[1] get_order({"order_id": "M-9999"}) -> ERROR LookupError: no order M-9999
[2] answer: I cannot find an order M-9999. Could you check the number in your confirmation email? It starts with M- and has four digits.
```

`M-9999` matched the pattern, so the schema let it through, and `get_order` raised `LookupError: no order M-9999`. `run_tool` caught it and returned the message as an error. The model, scripted by the course for this case, did the useful thing: it told the customer the order was not found and what an order number looks like. **Nothing crashed, nothing was guessed, and the customer has something to do next.**

## What goes in an error

- **What failed, specifically.** `no order M-9999` beats `lookup failed`; `'five' is not of type 'integer'` beats `bad request`.
- **What would succeed, when you know it.** The unknown-tool message lists the tools that exist. A refund refused for exceeding the balance says how much is left (`0 left to refund`, section 09).
- **Nothing the model should not see.** No stack traces, file paths, SQL, internal hostnames or keys. An error message is a tool result: it goes to the provider, sits in the conversation, and appears in traces.

## Which errors to catch

`run_tool` catches `LookupError` and `ValueError` and lets everything else propagate. That line is deliberate, and it follows this repository's own rule that silent failure is forbidden. A missing order or an amount too large are **expected** failures: the model can do something about them, so they become results. A database file that cannot be opened, or a bug in `find_books`, is not something a model can fix by trying a different argument; turning it into a polite tool result would hide an outage behind a conversation that looks fine. Those should stop the run loudly and reach whoever runs the agent.

## `is_error` is a signal, not decoration

Anthropic's API has an `is_error` field on `tool_result`; OpenAI's and Google's tool messages have no such field, and the convention there is to put the error in the content, often as `{"error": "..."}`. Either way the point is the same: the model must be able to tell a failure from data. A result of `"no order M-9999"` with no marker could be read as an order whose status is that sentence.
