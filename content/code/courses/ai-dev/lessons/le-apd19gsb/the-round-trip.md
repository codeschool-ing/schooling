---
title: One call, there and back
version: 2
---

Lesson 7 used tools inside an agent, with MCP in between. This lesson takes the protocol away and
looks at the one exchange everything else is built from: **the model asks for a function, your code
runs it, and the result goes back as part of the conversation**. Every reply in this lesson is
`llama3.2:3b`'s, at temperature 0.

## The tool, as the model sees it

The shop keeps its stock in one file beside the orders of lesson 7:

```json
{
  "MUG-01": {"in_stock": 37, "unit_price": 3990},
  "LAMP-02": {"in_stock": 4, "unit_price": 21000},
  "GLASS-03": {"in_stock": 0, "unit_price": 2490}
}
```

and its tools in one module, `shop_tools.py`. A tool is three things in the request: a `name`, a
`description` and an `input_schema`, which is a JSON Schema of the arguments. **The model never sees
your function.** It sees the definition in `TOOLS`, and decides from the description alone whether
the tool fits the question:

```schooling-example
{
  "language": "python",
  "file": "shop_tools.py",
  "parts": [
    {
      "code": "\"\"\"The shop's tools: what the model may ask for, and the code that does it.\"\"\"\nimport json\nfrom datetime import date\nfrom pathlib import Path\n\n"
    },
    {
      "code": "TODAY = date(2026, 10, 2)  # fixed, so the lesson's output does not move\nREASONS = [\"changed_mind\", \"wrong_item\", \"damaged\", \"faulty\"]\n\n",
      "note": "**The shop's \"today\" is fixed**, 2 October 2026, so the 30-day window gives the same answer on every run of this lesson. A real shop reads the clock."
    },
    {
      "code": "TOOLS = [\n    {\n        \"name\": \"get_stock\",\n        \"description\": \"Units in stock and unit price in cents for one product, by its SKU.\",\n        \"input_schema\": {\n            \"type\": \"object\",\n            \"properties\": {\"sku\": {\"type\": \"string\", \"description\": \"The product's SKU, such as MUG-01.\"}},\n            \"required\": [\"sku\"],\n        },\n    },\n    {\n        \"name\": \"create_return\",\n        \"description\": \"Open a return for units of one line of a delivered order. \"\n                       \"Use it only when the customer has asked to return something.\",\n        \"input_schema\": {\n            \"type\": \"object\",\n            \"properties\": {\n                \"order_id\": {\"type\": \"string\", \"pattern\": \"^[0-9]{4}$\", \"description\": \"Such as 1042.\"},\n                \"sku\": {\"type\": \"string\", \"description\": \"The SKU as it appears on the order line.\"},\n                \"quantity\": {\"type\": \"integer\", \"minimum\": 1},\n                \"reason\": {\"type\": \"string\", \"enum\": REASONS},\n            },\n            \"required\": [\"order_id\", \"sku\", \"quantity\", \"reason\"],\n            \"additionalProperties\": False,\n        },\n    },\n]\n\n\n",
      "note": "**What travels to the model**: for each tool a `name`, a `description` and an `input_schema`, a JSON Schema of its arguments. `create_return`'s is strict on purpose, and lesson 8 section 03 reads it keyword by keyword."
    },
    {
      "code": "class ShopError(Exception):\n    \"\"\"A request the shop refuses. The message is written for the model to read.\"\"\"\n\n\n",
      "note": "**The shop's refusals have a type of their own**, with messages written for the model to read."
    },
    {
      "code": "def get_stock(sku):\n    stock = json.loads(Path(\"data/stock.json\").read_text())\n    if sku not in stock:\n        raise ShopError(f\"no product {sku}; SKUs look like MUG-01\")\n    return stock[sku]\n\n\n",
      "note": "**The function behind `get_stock`** is ordinary Python. The model never sees it."
    },
    {
      "code": "def create_return(order_id, sku, quantity, reason):\n    orders = json.loads(Path(\"data/orders.json\").read_text())\n    order = orders.get(order_id)\n    if order is None:\n        raise ShopError(f\"no order {order_id}\")\n    if order[\"status\"] != \"delivered\":\n        raise ShopError(f\"order {order_id} is {order['status']}, not delivered; it cannot be returned yet\")\n    days = (TODAY - date.fromisoformat(order[\"delivered_on\"])).days\n    if days > 30:\n        raise ShopError(f\"order {order_id} was delivered {days} days ago; returns close after 30\")\n    bought = sum(line[\"quantity\"] for line in order[\"lines\"] if line[\"sku\"] == sku)\n    path = Path(\"data/returns.json\")\n    returns = json.loads(path.read_text()) if path.exists() else []\n    taken = sum(r[\"quantity\"] for r in returns if r[\"order_id\"] == order_id and r[\"sku\"] == sku)\n    if quantity > bought - taken:\n        raise ShopError(f\"order {order_id} has {bought - taken} of {sku} left to return, not {quantity}\")\n    record = {\"id\": f\"R-{order_id}-{len(returns) + 1}\", \"order_id\": order_id, \"sku\": sku,\n              \"quantity\": quantity, \"reason\": reason}\n    path.write_text(json.dumps(returns + [record], indent=1) + \"\\n\")\n    return record\n\n\n",
      "note": "**The function behind `create_return`** checks what a schema cannot: that the order exists, was delivered, is inside 30 days, and has that many units left to return."
    },
    {
      "code": "FUNCTIONS = {\"get_stock\": get_stock, \"create_return\": create_return}\n",
      "note": "**The host looks names up here**, and a name not in this table runs nothing."
    }
  ]
}
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
      "code": "while True:\n    r = model.messages.create(model=\"llama3.2:3b\", max_tokens=300, tools=TOOLS, messages=messages, extra_body={\"temperature\": 0})\n    print(\"<- stop_reason:\", r.stop_reason)\n    for b in r.content:\n        print(\"  \", json.dumps(b.model_dump(exclude_none=True)))\n",
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
      "code": "    print(\"-> user:\")\n    for x in results:\n        print(\"  \", json.dumps(x))\n    messages.append({\"role\": \"user\", \"content\": results})\n",
      "note": "**All the results go back in one user message**, each joined to its call by `tool_use_id`."
    }
  ]
}
```

## What crossed the wire

```
ana@dev:~/shop$ python stock.py "Is LAMP-02 in stock?"
<- stop_reason: tool_use
   {"id": "call_lz7psgft", "input": {"sku": "LAMP-02"}, "name": "get_stock", "type": "tool_use"}
-> user:
   {"type": "tool_result", "tool_use_id": "call_lz7psgft", "content": "{\"in_stock\": 4, \"unit_price\": 21000}"}
<- stop_reason: end_turn
   {"text": "The LAMP-02 is currently in stock. It has 4 units available, and the unit price is $21,000.", "type": "text"}
```

Read it from the top. **The first reply is not an answer.** Its `stop_reason` is `tool_use`, and
its content is one block naming the tool and the arguments, with an `id` that the API assigned:
`call_lz7psgft`. Ollama's ids begin with `call_` and Anthropic's with `toolu_`; nothing reads them
but the host. The model has stopped and is waiting.

**The host's reply is a `user` message**, because a conversation alternates between two roles and
the tool's output is on the user's side of it. It carries a `tool_result` whose `tool_use_id` is
that same id. The id is the join: with two calls in flight, it says which result answers which.

The second reply is text, and `stop_reason` is `end_turn`. It says the lamp costs **$21,000**. The
tool returned `21000`, and its description says *in cents*: the lamp is 210.00. The model read the
number, not the description, put a dollar sign on it that this shop never uses, and was out by a
factor of a hundred. **That conversion is the model's, not your code's**, which is why it can be
wrong while every other part of the exchange is right, and lesson 8 section 07 comes back to what
that means when the number matters.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The round trip of one tool call. The host sends the question and the tool definitions. The model replies with a tool_use block carrying an id, and stops. The host runs the function, then sends a tool_result carrying the same id. The model replies with the answer and end_turn.\"><defs><marker id=\"rt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"14\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the model</text><path d=\"M110 48 L110 288\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"275\" y=\"14\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">your code (the host)</text><path d=\"M370 48 L370 288\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"525\" y=\"14\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the function</text><path d=\"M620 48 L620 288\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M366 74 L114 74\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"240.0\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">question + tool definitions</text><path d=\"M114 114 L366 114\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"240.0\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">tool_use  id=toolu_…_1  get_stock {&quot;sku&quot;: &quot;LAMP-02&quot;}</text><path d=\"M374 154 L616 154\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"495.0\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">get_stock(sku=&quot;LAMP-02&quot;)</text><path d=\"M616 194 L374 194\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"495.0\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">{&quot;in_stock&quot;: 4, &quot;unit_price&quot;: 21000}</text><path d=\"M366 234 L114 234\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"240.0\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">tool_result  tool_use_id=toolu_…_1</text><path d=\"M114 274 L366 274\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"240.0\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the answer, end_turn</text></svg>", "caption": "The model proposes a call and waits. Only the host runs anything, and the id joins each result to its call."}
```

## Three things this shows

- **The model only proposes.** Nothing ran until the host looked the name up in `FUNCTIONS` and called it. A
  model that asks for a tool you never wired up gets nothing, and that is the whole security model
  of function calling in one line.
- **The conversation is the state.** The second request carries the question, the call and the
  result. Drop any of them and the model is answering a different conversation.
- **Every step is a full request.** Two round trips cost two requests, each billed for everything
  in it, which is lesson 2's arithmetic applied to tools.
