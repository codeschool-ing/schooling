---
title: The schema is a contract
version: 2
---

The model fills in the arguments by writing JSON. Nothing about that writing is checked by the model
itself, so **the schema in the tool's definition is the only place the shape is written down**, and
the host is the only place it can be enforced. This section writes a schema that can be enforced
and looks at what a checker says about bad arguments.

## A tool that changes something

`create_return` opens a return. Its schema is stricter than `get_stock`'s, because a wrong argument
here is a return opened for the wrong thing:

```python
    {
        "name": "create_return",
        "description": "Open a return for units of one line of a delivered order. "
                       "Use it only when the customer has asked to return something.",
        "input_schema": {
            "type": "object",
            "properties": {
                "order_id": {"type": "string", "pattern": "^[0-9]{4}$", "description": "Such as 1042."},
                "sku": {"type": "string", "description": "The SKU as it appears on the order line."},
                "quantity": {"type": "integer", "minimum": 1},
                "reason": {"type": "string", "enum": REASONS},
            },
            "required": ["order_id", "sku", "quantity", "reason"],
            "additionalProperties": False,
        },
    },
```

Each keyword closes a door:

- **`type` and `pattern`** say what an order number looks like. Order numbers are strings in the
  shop's data, so `1042` as a number would miss every lookup.
- **`minimum`** says a return of zero mugs is not a return.
- **`enum`** turns the reason into one of four words the warehouse understands, instead of a
  sentence nobody can sort by.
- **`required` and `additionalProperties: false`** say exactly which keys exist. A key the model
  invents is an error rather than something quietly ignored.

The description does a different job. **It says when to use the tool**, and "only when the
customer has asked" is aimed at the model, which reads it on every request.

## Checking a call against it

The schema is plain JSON Schema, so an ordinary validator reads it. `check_args.py` lists every
problem, not only the first:

```schooling-example
{
  "language": "python",
  "file": "check_args.py",
  "parts": [
    {
      "code": "\"\"\"Check a tool call's arguments against the tool's own schema, and list every problem.\"\"\"\nimport json\nimport sys\n\nfrom jsonschema import Draft202012Validator\n\nfrom shop_tools import TOOLS\n\n"
    },
    {
      "code": "SCHEMAS = {t[\"name\"]: t[\"input_schema\"] for t in TOOLS}\n\n\n",
      "note": "**The schemas are the ones the model is sent**, read from `TOOLS`, so the check and the request cannot drift apart."
    },
    {
      "code": "def problems(name, args):\n    v = Draft202012Validator(SCHEMAS[name])\n    return [f\"{'.'.join(map(str, e.path)) or '(top)'}: {e.message}\"\n            for e in sorted(v.iter_errors(args), key=lambda e: list(map(str, e.path)))]\n\n\n",
      "note": "**Every problem, not only the first**, each with the path of the field it is about."
    },
    {
      "code": "if __name__ == \"__main__\":\n    for p in problems(sys.argv[1], json.loads(sys.argv[2])) or [\"ok\"]:\n        print(p)\n",
      "note": "**From the command line**, a tool name and the arguments as JSON."
    }
  ]
}
```

Three sets of arguments, written by hand so that each shows a different kind of failure. The first
is written the way a model plausibly would:

```
ana@dev:~/shop$ python check_args.py create_return '{"order_id": 1042, "sku": "MUG-01", "quantity": 1, "reason": "customer changed their mind"}'
order_id: 1042 is not of type 'string'
reason: 'customer changed their mind' is not one of ['changed_mind', 'wrong_item', 'damaged', 'faulty']
ana@dev:~/shop$ python check_args.py create_return '{"order_id": "1042", "sku": "MUG-01", "quantity": 0, "note": "box unopened"}'
(top): 'reason' is a required property
(top): Additional properties are not allowed ('note' was unexpected)
quantity: 0 is less than the minimum of 1
ana@dev:~/shop$ python check_args.py create_return '{"order_id": "1042", "sku": "MUG-01", "quantity": 1, "reason": "changed_mind"}'
ok
```

**The first call reads fine to a person.** "Customer changed their mind" is the reason, 1042 is
the order. It fails twice anyway: the number is not a string, and the reason is a sentence where
the warehouse expects a word. The second shows a key nobody defined, a missing one and a zero.
The third is the call the shop can act on.

## What a schema cannot say

A schema checks shape. It does not know that order 1042 exists, that it was delivered, or that it
had two mugs and not three. **Those are the shop's rules, and they live in the shop's code**, which
lesson 8 section 04 runs after the schema has passed. Trying to squeeze them into the schema gives
a schema nobody can read and rules that still have holes.
