---
title: A schema that refuses
version: 1
---

The wrong belief is that a schema is documentation for the model: it lists the arguments and their types, and the model fills them in. Providers do use it that way. **In the host it is also a check, and a schema that refuses nothing checks nothing.** `{"type": "object", "properties": {"order_id": {"type": "string"}}}` accepts `{"order_id": "the book I bought last week"}`, and `{}`, and `{"order_id": "M-1043", "delete": true}`.

The keywords that turn a description into a refusal:

| keyword | what it refuses | in `tools.py` |
|---|---|---|
| `required` | a missing argument | `order_id`; all four of `issue_refund`'s |
| `additionalProperties: false` | an argument nobody declared | every tool |
| `type` | a string where a number belongs | `max_results`, `cents` |
| `pattern` | a string in the wrong shape | `^M-[0-9]{4}$` for order ids |
| `enum` | a value outside a closed list | the eight genres |
| `minimum`, `maximum` | a number out of range | 1 to 10 results; at least 1 cent |
| `minLength` | an empty or token string | a reason of at least 3 characters |

Run against `run_tool` directly, before any model is involved:

```
ana@lab:~/agents$ python -c "from tools import run_tool; print(run_tool(\"get_order\", {\"order_id\": \"1043\"}))"
("invalid arguments: order_id: '1043' does not match '^M-[0-9]{4}$'", True)
ana@lab:~/agents$ python -c "from tools import run_tool; print(run_tool(\"find_books\", {\"genre\": \"mystery\", \"max_results\": \"five\"}))"
("invalid arguments: max_results: 'five' is not of type 'integer'", True)
ana@lab:~/agents$ python -c "from tools import run_tool; print(run_tool(\"get_order\", {\"order_id\": \"M-1043\", \"verbose\": True}))"
("invalid arguments: arguments: Additional properties are not allowed ('verbose' was unexpected)", True)
ana@lab:~/agents$ python -c "from tools import run_tool; print(run_tool(\"get_order\", {\"order_id\": \"M-9999\"}))"
('LookupError: no order M-9999', True)
ana@lab:~/agents$ python -c "from tools import run_tool; print(run_tool(\"cancel_order\", {\"order_id\": \"M-1045\"}))"
("unknown tool 'cancel_order'; the tools are get_order, find_books, issue_refund", True)
```

Each refusal names the argument and the rule it broke, in words a model can act on: `'1043' does not match '^M-[0-9]{4}$'` tells the reader exactly what shape was wanted. The fourth line passed the schema and failed in the function, because M-9999 has the right shape and does not exist; **a schema checks form, never facts.** The last line never reached a schema at all: `cancel_order` is not a tool, and the message lists the ones that are.

## How strict to be

Strict where a mistake costs something, loose where it does not. An order id has one shape, so a pattern costs nothing and catches every typo. A free-text search query should not have one: a pattern there refuses legitimate questions. `additionalProperties: false` is worth having everywhere, because an argument the function does not expect is either a model's invention or somebody probing for one.

Some providers also offer a strict mode, which constrains the model's generation so that its arguments always match the schema. It is useful and it is not a replacement for the host's check: it is a promise from the provider, it supports a subset of JSON Schema, and the host is still the last place that can refuse a call before it runs. labllm does not implement it, so this course does not show it.
