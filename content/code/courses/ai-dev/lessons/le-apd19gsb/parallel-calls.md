---
title: Several calls in one reply
version: 1
---

A question about two products does not need two round trips. **A reply can carry several
`tool_use` blocks at once**, and the host answers all of them before asking the model again.
`stock.py` from lesson 8 section 02 already handles that, because it loops over every block in the
reply.

## Two products, one reply

```
ana@dev:~/shop$ python stock.py "Are MUG-01 and GLASS-03 in stock?"
<- stop_reason: tool_use
   {"text": "I will check both.", "type": "text"}
   {"id": "toolu_lab_0006_1", "input": {"sku": "MUG-01"}, "name": "get_stock", "type": "tool_use"}
   {"id": "toolu_lab_0006_2", "input": {"sku": "GLASS-03"}, "name": "get_stock", "type": "tool_use"}
-> user:
   {"type": "tool_result", "tool_use_id": "toolu_lab_0006_1", "content": "{\"in_stock\": 37, \"unit_price\": 3990}"}
   {"type": "tool_result", "tool_use_id": "toolu_lab_0006_2", "content": "{\"in_stock\": 0, \"unit_price\": 2490}"}
<- stop_reason: end_turn
   {"text": "MUG-01 is in stock, 37 units at 39.90. GLASS-03 is out of stock.", "type": "text"}
```

The first reply has three blocks: a sentence, then two calls with ids ending `_1` and `_2`. **Both
results go back in one `user` message**, each carrying the id of the call it answers. The model's
answer then uses both, and it says GLASS-03 is out of stock because the second result said
`"in_stock": 0`.

The order of the results does not matter to the API; the ids do. A host that runs the two calls at
the same time, in threads or with `asyncio`, can append the results in whatever order they finish.

## Leaving one out

The mistake that breaks this is answering only the calls you got round to:

```python
"""The mistake: the model asked for two calls and the host sends back one result."""
import anthropic

from shop_tools import TOOLS

model = anthropic.Anthropic()
messages = [{"role": "user", "content": "Are MUG-01 and GLASS-03 in stock?"}]
r = model.messages.create(model="scripted-1", max_tokens=300, tools=TOOLS, messages=messages)
calls = [b for b in r.content if b.type == "tool_use"]
messages += [
    {"role": "assistant", "content": r.content},
    {"role": "user", "content": [{"type": "tool_result", "tool_use_id": calls[0].id, "content": "37"}]},
]
try:
    model.messages.create(model="scripted-1", max_tokens=300, tools=TOOLS, messages=messages)
except anthropic.BadRequestError as e:
    print(e.status_code, e.body["error"]["message"])
```

```
ana@dev:~/shop$ python one_result.py
400 messages.2: tool_use ids without a tool_result in the next message: toolu_lab_0008_2
```

**The API refuses the request.** The sentence is labllm's, and a real provider refuses this too,
in its own words. Either way the failure is loud and immediate, which is the good case: the
alternative would be a model told about one product, asked about two, and free to guess the other.
A call that fails in your code still gets a result. It gets one with `is_error` set, as in lesson
8 section 04.

## When the calls depend on each other

Two calls in one reply are calls the model thought it could make **without seeing either result**.
When the second needs the first, as in "look up the order, then the stock of what is on it", the
model makes one call, reads the result, and makes the next in a later reply. That is the loop of
lesson 7 again, and it is why a host that handles one call per reply is not enough.

## Turning it off

Both APIs this course talks to let the caller say one call per reply: Anthropic's through
`disable_parallel_tool_use` inside `tool_choice`, OpenAI's through `parallel_tool_calls`. **Use it
when the calls change something and their order matters**, such as two refunds on one order where
the second checks what the first left. For reads, parallel calls are only fewer round trips.
