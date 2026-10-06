---
title: Tools from typed functions
version: 1
---

Lesson 4 wrote each tool's schema by hand, next to its function, and kept the two in step by care. `minagent` writes the schema from the function: the parameter names, their type hints and the docstring are already a description of the tool, so the decorator reads them.

```schooling-example
{
  "language": "python",
  "file": "minagent.py",
  "parts": [
    {
      "code": "# ---------------------------------------------------------------- tools from functions\n\n"
    },
    {
      "code": "TYPES = {str: {\"type\": \"string\"}, int: {\"type\": \"integer\"}, float: {\"type\": \"number\"}, bool: {\"type\": \"boolean\"}}\n\n\ndef schema_for(annotation):\n    \"\"\"The JSON Schema for one parameter's type hint. A type it does not know is refused, not guessed.\"\"\"\n    if isinstance(annotation, type) and annotation in TYPES:\n        return dict(TYPES[annotation])\n    origin, args = typing.get_origin(annotation), typing.get_args(annotation)\n",
      "note": "**Four Python types have an obvious JSON Schema.** Anything else needs a rule below, or a refusal."
    },
    {
      "code": "    if origin is typing.Annotated:\n        return {**schema_for(args[0]), **args[1]}\n",
      "note": "**`Annotated` carries extra schema keywords**: `Annotated[str, {\"pattern\": \"^M-[0-9]{4}$\"}]` is a string with a pattern."
    },
    {
      "code": "    if origin is typing.Literal:\n        return {\"enum\": list(args)}\n    if origin is list and len(args) == 1:\n        return {\"type\": \"array\", \"items\": schema_for(args[0])}\n",
      "note": "**`Literal` becomes an enum**, which is how the genres are declared."
    },
    {
      "code": "    raise TypeError(f\"no JSON Schema for {annotation!r}; write this tool's schema by hand\")\n\n\n@dataclass\n",
      "note": "**A type it does not know is refused, never guessed.** A `dict` parameter could mean anything, and a schema that accepts anything checks nothing (lesson 4)."
    },
    {
      "code": "class Tool:\n    name: str\n    description: str\n    schema: dict\n    fn: typing.Callable\n    writes: bool = False\n\n    def definition(self):\n        return {\"name\": self.name, \"description\": self.description, \"input_schema\": self.schema}\n\n\n",
      "note": "**What a tool is**: a name, a description, a schema, the function, and whether it writes."
    },
    {
      "code": "def tool(fn=None, *, writes=False):\n    \"\"\"Turn a typed, documented function into a Tool. Its docstring is what the model reads.\"\"\"\n    def make(f):\n",
      "note": "**The decorator.** It works bare, `@tool`, or with an argument, `@tool(writes=True)`."
    },
    {
      "code": "        doc = inspect.getdoc(f)\n        if not doc:\n            raise ValueError(f\"{f.__name__} has no docstring, and the docstring is the tool's description\")\n        hints = typing.get_type_hints(f, include_extras=True)\n        props, required = {}, []\n",
      "note": "**No docstring, no tool.** The docstring is the description the model reads, and a tool without one is a tool the model has to guess about."
    },
    {
      "code": "        for name, p in inspect.signature(f).parameters.items():\n            if name not in hints:\n                raise TypeError(f\"{f.__name__}: parameter {name!r} has no type hint\")\n            props[name] = schema_for(hints[name])\n            if p.default is inspect.Parameter.empty:\n                required.append(name)\n        schema = {\"type\": \"object\", \"properties\": props, \"required\": required, \"additionalProperties\": False}\n        return Tool(f.__name__, doc, schema, f, writes)\n    return make(fn) if fn else make\n\n",
      "note": "**Every parameter must have a type hint**; one with a default is optional, the rest are required."
    }
  ]
}
```

`marginalia.py` declares the shop's tools with it. The types do the work that lesson 4's hand-written schemas did:

```python
"""Marginalia's tools for minagent: the functions of shop.py, typed and documented."""
from typing import Annotated, Literal

import shop
from minagent import tool

OrderId = Annotated[str, {"pattern": "^M-[0-9]{4}$"}]
Genre = Literal["adventure", "children", "horror", "literary", "mystery", "non-fiction", "romance",
                "science fiction"]


@tool
def get_order(order_id: OrderId) -> dict:
    """Look up one Marginalia order by its id, M- and four digits, such as M-1042.
    Returns status, dates, lines and amounts in cents."""
    return shop.get_order(order_id)


@tool
def search_help(query: str) -> list:
    """Search Marginalia's help centre by meaning and return the three closest articles."""
    return [{"id": a["id"], "title": a["title"], "body": a["body"]} for a in shop.search_help(query)]


@tool
def find_books(genre: Genre, max_results: Annotated[int, {"minimum": 1, "maximum": 10}] = 3) -> list:
    """List books in stock in one genre, cheapest first, with prices in cents."""
    import json
    books = [shop.get_book(json.loads(line)["id"]) for line in open(shop.DATA / "books.jsonl")]
    stocked = sorted((b for b in books if b["genre"] == genre and b["stock"] > 0), key=lambda b: b["cents"])
    return [{"title": b["title"], "author": b["author"], "cents": b["cents"]} for b in stocked[:max_results]]


@tool(writes=True)
def refund(order_id: OrderId, cents: int, reason: str) -> dict:
    """Refund part or all of an order to the customer's original payment, in cents."""
    return shop.refund(order_id, cents, reason, approved_by="minagent")


TOOLS = [get_order, search_help, find_books, refund]
```

What the decorator produced, and what it refuses:

```
ana@lab:~/agents$ python -c "import json; from marginalia import get_order, find_books; print(json.dumps(get_order.definition(), indent=1)); print(json.dumps(find_books.schema))"
{
 "name": "get_order",
 "description": "Look up one Marginalia order by its id, M- and four digits, such as M-1042.\nReturns status, dates, lines and amounts in cents.",
 "input_schema": {
  "type": "object",
  "properties": {
   "order_id": {
    "type": "string",
    "pattern": "^M-[0-9]{4}$"
   }
  },
  "required": [
   "order_id"
  ],
  "additionalProperties": false
 }
}
{"type": "object", "properties": {"genre": {"enum": ["adventure", "children", "horror", "literary", "mystery", "non-fiction", "romance", "science fiction"]}, "max_results": {"type": "integer", "minimum": 1, "maximum": 10}}, "required": ["genre"], "additionalProperties": false}
ana@lab:~/agents$ python -c "from minagent import tool
@tool
def lookup(filters: dict) -> list:
    \"\"\"Look things up.\"\"\"" 2>&1 | tail -n 1
TypeError: no JSON Schema for <class 'dict'>; write this tool's schema by hand
```

`get_order`'s definition is exactly the shape Anthropic's API takes, built from a signature and a docstring. `find_books`'s schema carries the enum from `Genre` and the bounds from `Annotated`. And a function with a `dict` parameter is refused at import time, with a message saying what to do instead. **The failure happens when the code is written, not when a model sends a dictionary nobody expected.**

## The trade

Deriving schemas from types keeps the two from drifting: change the function's signature and the schema follows. It also limits what the schema can say to what the type system can express, plus whatever `Annotated` adds. That is enough for most tools. For the rest, a `Tool` can be built by hand with any schema; the decorator is a convenience, and the loop does not care how a `Tool` was made. Every SDK in lessons 8 to 10 makes the same trade, with a decorator of its own: `function_tool`, `tool`, or a plain function the framework inspects.
