---
title: Several calls in one reply
version: 2
---

A question about two products does not need two round trips. **A reply can carry several
`tool_use` blocks at once**, and the host answers all of them before asking the model again.
`stock.py` from lesson 8 section 02 already handles that, because it loops over every block in the
reply.

## Two products, one reply

```
ana@dev:~/shop$ python stock.py "Are MUG-01 and GLASS-03 in stock?"
<- stop_reason: tool_use
   {"id": "call_8xfkxfof", "input": {"sku": "MUG-01"}, "name": "get_stock", "type": "tool_use"}
   {"id": "call_6rxmxd6y", "input": {"sku": "GLASS-03"}, "name": "get_stock", "type": "tool_use"}
-> user:
   {"type": "tool_result", "tool_use_id": "call_8xfkxfof", "content": "{\"in_stock\": 37, \"unit_price\": 3990}"}
   {"type": "tool_result", "tool_use_id": "call_6rxmxd6y", "content": "{\"in_stock\": 0, \"unit_price\": 2490}"}
<- stop_reason: end_turn
   {"text": "MUG-01 is currently in stock with 37 units available, priced at $3990 per unit.\n\nUnfortunately, GLASS-03 is currently out of stock.", "type": "text"}
```

The first reply has two blocks, two calls, each with its own id. **Both results go back in one
`user` message**, each carrying the id of the call it answers. The model's answer then uses both:
GLASS-03 is out of stock because the second result said `"in_stock": 0`. It also prices the mug at
$3990, which is the cents of section 02 read as dollars again.

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
r = model.messages.create(model="llama3.2:3b", max_tokens=300, tools=TOOLS, messages=messages, extra_body={"temperature": 0})
calls = [b for b in r.content if b.type == "tool_use"]
print("asked for:", ", ".join(f"{c.name}({c.input['sku']})" for c in calls))
messages += [
    {"role": "assistant", "content": r.content},
    {"role": "user", "content": [{"type": "tool_result", "tool_use_id": calls[0].id, "content": "37"}]},
]
try:
    r = model.messages.create(model="llama3.2:3b", max_tokens=300, tools=TOOLS, messages=messages, extra_body={"temperature": 0})
    print("accepted, and answered:", r.content[0].text)
except anthropic.BadRequestError as e:
    print(e.status_code, e.body["error"]["message"])
```

```
ana@dev:~/shop$ python one_result.py
asked for: get_stock(MUG-01), get_stock(GLASS-03)
accepted, and answered: Unfortunately, I couldn't find any information on the stock levels of MUG-01 and GLASS-03. However, I can suggest checking with the manufacturer or a authorized distributor for the most up-to-date information on availability.
```

**Ollama accepted it.** The second request went through with one of the two calls unanswered, and
the model, told that MUG-01's result was 37, answered that it could not find anything about either
product. Anthropic's own API refuses a request like this with an error 400 that names the call
with no result, and `one_result.py` prints that error when it gets one; here it got none, because
Ollama does not check. **The failure was quiet**: a reply that reads like an answer and throws away
the one fact it was given. A host cannot count on the server to notice, so it answers every call,
always: a call that fails in your code still gets a result, one with `is_error` set, as in lesson 8
section 04.

## When the calls depend on each other

Two calls in one reply are calls the model thought it could make **without seeing either result**.
When the second needs the first, as in "look up the order, then the stock of what is on it", the
model has to make one call, read the result, and make the next in a later reply. That is the loop of
lesson 7 again, and lesson 7 section 03 found that `llama3.2:3b` on Ollama does not do it: after a
result, its template shows it no tools. Whatever it needs, it has to ask for in the first reply.

## Turning it off

Both APIs this course talks to let the caller say one call per reply: Anthropic's through
`disable_parallel_tool_use` inside `tool_choice`, OpenAI's through `parallel_tool_calls`. **Use it
when the calls change something and their order matters**, such as two refunds on one order where
the second checks what the first left. For reads, parallel calls are only fewer round trips.
