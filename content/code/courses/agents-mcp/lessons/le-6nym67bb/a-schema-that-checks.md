---
title: A schema that says what the code checks
version: 1
---

Lesson 4's rule was that a schema should carry what the code checks, so the model is told the rule before it breaks it. `OrderId` puts the rule in the type: `Annotated[str, Field(pattern=..., description=...)]`. The SDK turns it into JSON Schema:

```
ana@lab:~/agents$ python try_server.py schema 2> server.log
get_order
  input:  {"order_id": {"description": "M- and four digits, such as M-1043", "pattern": "^M-[0-9]{4}$", "title": "Order Id", "type": "string"}}
  output: ["delivered_on", "id", "lines", "placed_on", "refunded", "status", "total", "tracking"]
  hints:  {'read_only_hint': True}
search_help
  input:  {"query": {"title": "Query", "type": "string"}}
  output: ["result"]
  hints:  {'read_only_hint': True}
```

`get_order`'s input schema now carries the pattern `^M-[0-9]{4}$` and the description *"M- and four digits, such as M-1043"*, which lesson 11's `shop_mcp.py` did not. A host passes both to its model, so the model sees the format before its first call. And the server checks it: the same annotation that produced the schema is what the SDK validates arguments against, so the schema and the check cannot drift apart. The third call in the next section shows the check at work.

The **hints** line shows `readOnlyHint` on both tools. A hint is the server describing itself, and the specification is explicit that a client must not rely on hints from a server it does not trust. A host can use them to decide which calls need a person, as `ai-dev` lesson 7 did, but the decision stays the host's.

`search_help`'s output schema is a single property, `result`. A function that returns a list cannot be a JSON object at the top level, so the SDK wraps it, as the ADK did in lesson 10. A client reading `structuredContent` finds the list under `result`.
