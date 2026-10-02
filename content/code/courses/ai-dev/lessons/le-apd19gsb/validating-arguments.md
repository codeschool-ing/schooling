---
title: Check before you run
version: 1
---

Lesson 8 section 03 wrote the checks. This section puts them in the host, between the model's
request and the function, and sends every failure back to the model as a result it can read.
**A failed check is not a crash.** It is information the model did not have.

## The host's one function

```python
def run(name, args):
    """The text to send back, and whether it is an error."""
    found = problems(name, args)
    if found:
        return "invalid arguments: " + "; ".join(found), True
    try:
        return json.dumps(FUNCTIONS[name](**args)), False
    except ShopError as e:
        return str(e), True
```

Two layers, in order. **The schema first**, because a function called with a number where it
expects a string fails somewhere inside, with a message about Python rather than about the order.
**The shop's rules second**, raised as `ShopError`, whose messages are written to be read by the
model. Either way the host sends a `tool_result` with `is_error` set, and the loop goes on.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Two checks between the model and the function. A tool call from the model goes first to the schema check, then to the shop&#x27;s rules, and only then does the function run and its result go back. A failure at either check goes back to the model as a tool_result with is_error set, naming what was wrong.\"><defs><marker id=\"ly-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"80\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a call from the model</text><path d=\"M80 72 L80 100 L148 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><rect x=\"150\" y=\"72\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the schema</text><text x=\"230.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shape of one call</text><path d=\"M312 100 L358 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><rect x=\"360\" y=\"72\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the shop&#x27;s rules</text><text x=\"450.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">state: stock, dates, returns</text><path d=\"M542 100 L578 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><rect x=\"580\" y=\"76\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the function runs</text><path d=\"M640 126 L640 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><text x=\"640\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">tool_result: what it did</text><path d=\"M230 130 L230 176\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M450 130 L450 176\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M450 176 L232 176\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M230 176 L80 176 L80 128\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah)\"></path><text x=\"340\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">tool_result, is_error: what was wrong</text></svg>", "caption": "Each failure is sent back as a result the model can read, so it can correct the call instead of the host crashing."}
```

## A model that gets it wrong, then right

```
ana@dev:~/shop$ python returns.py "Please return one mug from order 1042, the customer changed their mind."
[1] call:   create_return({"order_id": 1042, "sku": "MUG-01", "quantity": 1, "reason": "customer changed their mind"})
[1] error:  invalid arguments: order_id: 1042 is not of type 'string'; reason: 'customer changed their mind' is not one of ['changed_mind', 'wrong_item', 'damaged', 'faulty']
[2] call:   create_return({"order_id": "1042", "sku": "MUG-01", "quantity": 1, "reason": "changed_mind"})
[2] result:  {"id": "R-1042-1", "order_id": "1042", "sku": "MUG-01", "quantity": 1, "reason": "changed_mind"}
[3] model:  Return R-1042-1 is open for one MUG-01 from order 1042. The customer will receive a prepaid label by email.
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

**Step 1 is the call from lesson 8 section 03**, and the host refuses it without running anything.
The error names both problems and lists the four reasons the shop accepts. **Step 2 is the same
call, corrected**: the order number in quotes and `changed_mind` from the list. It passes both
layers and opens `R-1042-1`. Step 3 is the model reporting what happened, in a sentence built from
the result.

The correction is possible only because the error said what was wrong. "invalid arguments" alone
would have left the model guessing, and a guess is a second wrong call.

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
