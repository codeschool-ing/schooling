---
title: One call, there and back
version: 1
---

Lesson 7 used tools inside an agent, with MCP in between. This lesson takes the protocol away and
looks at the one exchange everything else is built from: **the model asks for a function, your code
runs it, and the result goes back as part of the conversation**. The model's replies in this
lesson were written by the course, as rules in `scripted-1`; the SDK, the requests and every result
are real.

## The tool, as the model sees it

A tool is three things in the request: a `name`, a `description` and an `input_schema`, which is a
JSON Schema of the arguments. The model never sees your function. It sees this, and decides from
the description alone whether the tool fits the question.

```python
def get_stock(sku):
    stock = json.loads(Path("data/stock.json").read_text())
    if sku not in stock:
        raise ShopError(f"no product {sku}; SKUs look like MUG-01")
    return stock[sku]
```

The function is ordinary Python. The definition beside it, in `TOOLS`, is what travels:

```python
    {
        "name": "get_stock",
        "description": "Units in stock and unit price in cents for one product, by its SKU.",
        "input_schema": {
            "type": "object",
            "properties": {"sku": {"type": "string", "description": "The product's SKU, such as MUG-01."}},
            "required": ["sku"],
        },
    },
```

## The loop that prints everything

```schooling-example
{
  "language": "python",
  "file": "stock.py",
  "parts": [
    {
      "code": "\"\"\"One question, with tools: every request and reply of the round trip, printed.\"\"\"\nimport json\nimport sys\n\nimport anthropic\n\n"
    },
    {
      "code": "from shop_tools import FUNCTIONS, TOOLS\n\nmodel = anthropic.Anthropic()\nmessages = [{\"role\": \"user\", \"content\": sys.argv[1]}]\n",
      "note": "**The tools come from one module**, with the functions that do the work."
    },
    {
      "code": "while True:\n    r = model.messages.create(model=\"scripted-1\", max_tokens=300, tools=TOOLS, messages=messages)\n    print(\"<- stop_reason:\", r.stop_reason)\n    for b in r.content:\n        print(\"  \", json.dumps(b.model_dump(exclude_none=True)))\n",
      "note": "**One request per turn**, carrying the tools and the whole conversation so far. Every block of the reply is printed as it arrived."
    },
    {
      "code": "    messages.append({\"role\": \"assistant\", \"content\": r.content})\n    if r.stop_reason != \"tool_use\":\n        break\n",
      "note": "**The reply goes into the conversation as it is**, and a reply that asks for no tool is the answer."
    },
    {
      "code": "    results = []\n    for b in r.content:\n        if b.type == \"tool_use\":\n            out = FUNCTIONS[b.name](**b.input)\n            results.append({\"type\": \"tool_result\", \"tool_use_id\": b.id, \"content\": json.dumps(out)})\n",
      "note": "**Only here does anything run.** The model named a function and its arguments; the host looks the name up in its own table and calls it."
    },
    {
      "code": "    print(\"-> user:\")\n    for x in results:\n        print(\"  \", json.dumps(x))\n    messages.append({\"role\": \"user\", \"content\": results})",
      "note": "**All the results go back in one user message**, each joined to its call by `tool_use_id`."
    }
  ]
}
```

## What crossed the wire

```
ana@dev:~/shop$ python stock.py "Is LAMP-02 in stock?"
<- stop_reason: tool_use
   {"id": "toolu_lab_0001_1", "input": {"sku": "LAMP-02"}, "name": "get_stock", "type": "tool_use"}
-> user:
   {"type": "tool_result", "tool_use_id": "toolu_lab_0001_1", "content": "{\"in_stock\": 4, \"unit_price\": 21000}"}
<- stop_reason: end_turn
   {"text": "Yes. LAMP-02 is in stock, 4 units, at 210.00.", "type": "text"}
```

Read it from the top. **The first reply is not an answer.** Its `stop_reason` is `tool_use`, and
its content is one block naming the tool and the arguments, with an `id` that the API assigned:
`toolu_lab_0001_1`. The model has stopped and is waiting.

**The host's reply is a `user` message**, because a conversation alternates between two roles and
the tool's output is on the user's side of it. It carries a `tool_result` whose `tool_use_id` is
that same id. The id is the join: with two calls in flight, it says which result answers which.

The second reply is text, and `stop_reason` is `end_turn`. The 210.00 in it is `21000` cents
from the tool result, divided by a hundred by the model. **That division is the model's, not your
code's**, and lesson 8 section 07 comes back to what that means when the number matters.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The round trip of one tool call. The host sends the question and the tool definitions. The model replies with a tool_use block carrying an id, and stops. The host runs the function, then sends a tool_result carrying the same id. The model replies with the answer and end_turn.\"><defs><marker id=\"rt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"14\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the model</text><path d=\"M110 48 L110 288\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"275\" y=\"14\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">your code (the host)</text><path d=\"M370 48 L370 288\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"525\" y=\"14\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the function</text><path d=\"M620 48 L620 288\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M366 74 L114 74\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"240.0\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">question + tool definitions</text><path d=\"M114 114 L366 114\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"240.0\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">tool_use  id=toolu_…_1  get_stock {&quot;sku&quot;: &quot;LAMP-02&quot;}</text><path d=\"M374 154 L616 154\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"495.0\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">get_stock(sku=&quot;LAMP-02&quot;)</text><path d=\"M616 194 L374 194\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"495.0\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">{&quot;in_stock&quot;: 4, &quot;unit_price&quot;: 21000}</text><path d=\"M366 234 L114 234\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"240.0\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">tool_result  tool_use_id=toolu_…_1</text><path d=\"M114 274 L366 274\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"240.0\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the answer, end_turn</text></svg>", "caption": "The model proposes a call and waits. Only the host runs anything, and the id joins each result to its call."}
```

## Three things this shows

- **The model only proposes.** Nothing ran until `FUNCTIONS[b.name](**b.input)` in the host. A
  model that asks for a tool you never wired up gets nothing, and that is the whole security model
  of function calling in one line.
- **The conversation is the state.** The second request carries the question, the call and the
  result. Drop any of them and the model is answering a different conversation.
- **Every step is a full request.** Two round trips cost two requests, each billed for everything
  in it, which is lesson 2's arithmetic applied to tools.
