---
title: Check before you run
version: 2
---

Lesson 8 section 03 wrote the checks. This section puts them in the host, between the model's
request and the function, and sends every failure back to the model as a result it can read.
**A failed check is not a crash.** It is information the model did not have.

## The host's one function

The host is `returns.py`, and the part that matters is `run`:

```schooling-example
{
  "language": "python",
  "file": "returns.py",
  "parts": [
    {
      "code": "\"\"\"A host that checks every call before it runs it, and tells the model what was wrong.\"\"\"\nimport json\nimport sys\n\nimport anthropic\n\nfrom check_args import problems\nfrom shop_tools import FUNCTIONS, TOOLS, ShopError\n\n"
    },
    {
      "code": "model = anthropic.Anthropic()\n\n\n"
    },
    {
      "code": "def run(name, args):\n    \"\"\"The text to send back, and whether it is an error.\"\"\"\n    found = problems(name, args)\n    if found:\n        return \"invalid arguments: \" + \"; \".join(found), True\n    try:\n        return json.dumps(FUNCTIONS[name](**args)), False\n    except ShopError as e:\n        return str(e), True\n\n\n",
      "note": "**The host's one function**: the schema first, then the shop's rules, and either failure comes back as text the model can read, marked as an error."
    },
    {
      "code": "messages = [{\"role\": \"user\", \"content\": sys.argv[1]}]\nfor step in range(1, 5):\n    r = model.messages.create(model=\"llama3.2:3b\", max_tokens=300, tools=TOOLS, messages=messages, extra_body={\"temperature\": 0})\n    messages.append({\"role\": \"assistant\", \"content\": r.content})\n    results = []\n    for b in r.content:\n        if b.type == \"text\":\n            print(f\"[{step}] model:  {b.text}\")\n        elif b.type == \"tool_use\":\n            text, error = run(b.name, b.input)\n            print(f\"[{step}] call:   {b.name}({json.dumps(b.input)})\")\n            print(f\"[{step}] {'error' if error else 'result'}:  {text}\")\n            results.append({\"type\": \"tool_result\", \"tool_use_id\": b.id, \"content\": text, \"is_error\": error})\n    if not results:\n        break\n    messages.append({\"role\": \"user\", \"content\": results})\n",
      "note": "**The loop**, four steps at most, printing each call and what came back."
    }
  ]
}
```

Two layers, in order. **The schema first**, because a function called with a number where it
expects a string fails somewhere inside, with a message about Python rather than about the order.
**The shop's rules second**, raised as `ShopError`, whose messages are written to be read by the
model. Either way the host sends a `tool_result` with `is_error` set, and the loop goes on.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Two checks between the model and the function. A tool call from the model goes first to the schema check, then to the shop&#x27;s rules, and only then does the function run and its result go back. A failure at either check goes back to the model as a tool_result with is_error set, naming what was wrong.\"><defs><marker id=\"ly-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"80\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a call from the model</text><path d=\"M80 72 L80 100 L148 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><rect x=\"150\" y=\"72\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the schema</text><text x=\"230.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shape of one call</text><path d=\"M312 100 L358 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><rect x=\"360\" y=\"72\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the shop&#x27;s rules</text><text x=\"450.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">state: stock, dates, returns</text><path d=\"M542 100 L578 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><rect x=\"580\" y=\"76\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the function runs</text><path d=\"M640 126 L640 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><text x=\"640\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">tool_result: what it did</text><path d=\"M230 130 L230 176\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M450 130 L450 176\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M450 176 L232 176\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M230 176 L80 176 L80 128\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><text x=\"340\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">tool_result, is_error: what was wrong</text></svg>", "caption": "Each failure is sent back as a result the model can read, so it can correct the call instead of the host crashing."}
```

## A model that gets it right

```
ana@dev:~/shop$ python returns.py "Please return one mug from order 1042, the customer changed their mind."
[1] call:   create_return({"order_id": "1042", "sku": "MUG-01", "quantity": 1, "reason": "changed_mind"})
[1] result:  {"id": "R-1042-1", "order_id": "1042", "sku": "MUG-01", "quantity": 1, "reason": "changed_mind"}
[2] model:  The return for order 1042 has been processed. One mug has been returned due to the customer changing their mind. The order ID is 1042, and the SKU of the item returned is MUG-01.
ana@dev:~/shop$ cat data/returns.json
[
 {
  "id": "R-1042-1",
  "order_id": "1042",
  "sku": "MUG-01",
  "quantity": 1,
  "reason": "changed_mind"
 }
]
```

**One call, right the first time**: the order number as a string, `changed_mind` from the list of
reasons, one unit. It passed both layers and opened `R-1042-1`, and the model's second step
reported it in a sentence built from the result. The schema's error path did not run, and the three
calls of lesson 8 section 03 show what it would have sent back: every problem named, and the four
reasons the shop accepts listed. A model reads the `enum` and the `pattern` in the definition, and a
small one often gets them right; the check is for the times it does not, which no run can rule out.

An error that says what was wrong is what makes a correction possible. "invalid arguments" alone
would leave the model guessing, and a guess is a second wrong call.

## The shop's own rules

The schema passed in both of these, and the shop still refused:

```
ana@dev:~/shop$ python -c 'from shop_tools import create_return; create_return("1042", "MUG-01", 2, "changed_mind")' 2>&1 | tail -n 1
shop_tools.ShopError: order 1042 has 1 of MUG-01 left to return, not 2
ana@dev:~/shop$ python -c 'from shop_tools import create_return; create_return("1043", "LAMP-02", 1, "faulty")' 2>&1 | tail -n 1
shop_tools.ShopError: order 1043 is shipped, not delivered; it cannot be returned yet
```

**The first is arithmetic over state.** Order 1042 had two mugs and one already has a return, so
one is left; no schema could know that. **The second is the order's status**: a parcel still in
transit cannot be returned. Both messages say what is true, in numbers the model can repeat to a
customer, and neither leaks anything the model was not already asking about.

## Where each check belongs

- **In the schema**: anything about the shape of one call, true whatever the shop's data says.
- **In the function**: anything that depends on state, such as stock, dates and what was returned
  before. The function checks it whoever calls it, model or person.
- **Never in the prompt alone.** "Only return delivered orders" in the system prompt is a request.
  The `if` in `create_return` is a rule.
