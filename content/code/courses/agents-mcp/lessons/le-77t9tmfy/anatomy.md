---
title: What a tool is made of
version: 1
---

A tool, as a model API understands it, is three things: a **name**, a **description** in plain language, and an **input schema**, a JSON Schema describing the arguments. The function that does the work is not part of it. The model never sees `shop.py`; it sees the three things and decides, from them alone, when to call the tool and what to put in the arguments.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A tool definition and its two readers. The name and description are read by the model, which uses them to decide when to call the tool. The input schema is read by both: the model uses it to shape the arguments, and the host validates every call against it. The function itself is read by neither; only the host runs it.\"><defs><marker id=\"l4contract-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l4contract-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">name</text><text x=\"30\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">get_order</text><rect x=\"20\" y=\"90\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"104.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">description</text><text x=\"30\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a sentence for the model</text><rect x=\"20\" y=\"150\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">input_schema</text><text x=\"30\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">JSON Schema 2020-12</text><rect x=\"500\" y=\"50\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"67.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the model</text><text x=\"510\" y=\"83.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">decides when, and with what</text><rect x=\"500\" y=\"150\" width=\"200\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the host</text><text x=\"510\" y=\"183.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">validates, then runs shop.py</text><path d=\"M220 52 L500 70\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l4contract-ah-amber)\"></path><path d=\"M220 112 L500 80\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l4contract-ah-amber)\"></path><path d=\"M220 166 L500 90\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l4contract-ah-amber)\"></path><path d=\"M220 178 L500 175\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l4contract-ah-phosphor)\"></path><text x=\"360\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the function: run by the host, seen by nobody else</text></svg>", "caption": "The schema is the one part both sides read, which is what makes it the place to enforce the contract."}
```

That makes a tool definition a contract with two readers, and each reads it for a different purpose:

- **The model** reads the name and the description to decide whether this tool fits the step it is on, and the schema to shape the arguments. It reads them on every request, because the definitions travel with the conversation.
- **The host** reads the schema to decide whether a call may go through. A call that does not match is refused before anything runs.

This lesson's tools are in `tools.py`: the same `get_order` as before with a stricter schema, `find_books` over the catalogue, and `issue_refund`, the first tool in this course that changes anything.

```schooling-example
{
  "language": "python",
  "file": "tools.py",
  "parts": [
    {
      "code": "\"\"\"Marginalia's tools for the model: each a schema the model reads and a function the host runs.\"\"\"\nimport json\nfrom pathlib import Path\n\nfrom jsonschema import Draft202012Validator\n\nimport shop\n\n"
    },
    {
      "code": "GENRES = sorted({json.loads(line)[\"genre\"] for line in open(\"data/books.jsonl\")})\n\n",
      "note": "**The allowed genres are read from the data**, so the schema's list cannot drift away from the catalogue."
    },
    {
      "code": "TOOLS = [\n    {\"name\": \"get_order\",\n     \"description\": (\"Look up one Marginalia order by its id, which is M- followed by four digits, such as M-1042. \"\n                     \"Returns status, dates, lines and amounts in cents.\"),\n     \"input_schema\": {\"type\": \"object\", \"additionalProperties\": False, \"required\": [\"order_id\"],\n                      \"properties\": {\"order_id\": {\"type\": \"string\", \"pattern\": \"^M-[0-9]{4}$\"}}}},\n",
      "note": "**Three definitions in Anthropic's shape**: `name`, `description`, `input_schema`. Section 07 shows the same tool in OpenAI's and Google's shapes."
    },
    {
      "code": "    {\"name\": \"find_books\",\n     \"description\": \"List books Marginalia has in stock in one genre, cheapest first, with prices in cents.\",\n     \"input_schema\": {\"type\": \"object\", \"additionalProperties\": False, \"required\": [\"genre\"],\n                      \"properties\": {\"genre\": {\"type\": \"string\", \"enum\": GENRES},\n                                     \"max_results\": {\"type\": \"integer\", \"minimum\": 1, \"maximum\": 10}}}},\n",
      "note": "**An enum and a range.** The model may pick a genre only from the list, and at most ten results."
    },
    {
      "code": "    {\"name\": \"issue_refund\",\n     \"description\": (\"Refund part or all of an order, in cents. Send the same idempotency_key again to retry \"\n                     \"safely: a key already used returns the first result and refunds nothing more.\"),\n     \"input_schema\": {\"type\": \"object\", \"additionalProperties\": False,\n                      \"required\": [\"order_id\", \"cents\", \"reason\", \"idempotency_key\"],\n                      \"properties\": {\"order_id\": {\"type\": \"string\", \"pattern\": \"^M-[0-9]{4}$\"},\n                                     \"cents\": {\"type\": \"integer\", \"minimum\": 1},\n                                     \"reason\": {\"type\": \"string\", \"minLength\": 3},\n                                     \"idempotency_key\": {\"type\": \"string\", \"minLength\": 8}}}},\n]\n",
      "note": "**A write, so the schema asks for more**: an amount in whole cents, a reason, and a key that makes a retry safe (section 09)."
    },
    {
      "code": "VALIDATORS = {t[\"name\"]: Draft202012Validator(t[\"input_schema\"]) for t in TOOLS}\nKEYS = Path(\"data/refund_keys.json\")\n\n\n",
      "note": "**One validator per tool, built once**, against the 2020-12 dialect of JSON Schema, which is the one MCP also assumes (lesson 13)."
    },
    {
      "code": "def find_books(genre, max_results=3):\n    books = [shop.get_book(json.loads(line)[\"id\"]) for line in open(\"data/books.jsonl\")]\n    stocked = [b for b in books if b[\"genre\"] == genre and b[\"stock\"] > 0]\n    stocked.sort(key=lambda b: b[\"cents\"])\n    return [{\"id\": b[\"id\"], \"title\": b[\"title\"], \"author\": b[\"author\"], \"cents\": b[\"cents\"]}\n            for b in stocked[:max_results]]\n\n\ndef issue_refund(order_id, cents, reason, idempotency_key):\n    done = json.loads(KEYS.read_text()) if KEYS.exists() else {}\n    if idempotency_key in done:\n        return dict(done[idempotency_key], note=\"already processed with this key; nothing refunded now\")\n    result = shop.refund(order_id, cents, reason, approved_by=\"agent\")\n    done[idempotency_key] = result\n    KEYS.write_text(json.dumps(done))\n    return result\n\n\n",
      "note": "**The functions are ordinary Python.** Nothing in them knows a model will ask for them."
    },
    {
      "code": "RUN = {\"get_order\": shop.get_order, \"find_books\": find_books, \"issue_refund\": issue_refund}\n\n\n",
      "note": "**The table the host dispatches through.** A name that is not in it is not a tool."
    },
    {
      "code": "def run_tool(name, args):\n    \"\"\"(text for the model, is_error). Nothing reaches a function before its arguments pass the schema.\"\"\"\n    if name not in RUN:\n        return f\"unknown tool {name!r}; the tools are {', '.join(RUN)}\", True\n    problems = sorted(VALIDATORS[name].iter_errors(args), key=lambda e: list(e.path))\n    if problems:\n        return \"invalid arguments: \" + \"; \".join(\n            f\"{'/'.join(map(str, p.path)) or 'arguments'}: {p.message}\" for p in problems), True\n    try:\n        return json.dumps(RUN[name](**args)), False\n    except (LookupError, ValueError) as e:\n        return f\"{type(e).__name__}: {e}\", True",
      "note": "**The gate**: unknown tool, invalid arguments, a known error from the function, or the result. Section 05 runs it."
    }
  ]
}
```

## Names

A name is an identifier the model writes back, so keep it short, in `snake_case`, and specific: `get_order` and `find_books`, not `orders` and `search`. Two tools whose names could describe the same action will be confused, by models and by the people reading traces. Providers limit names to letters, digits, underscores and hyphens, and to a few dozen characters; the safe habit is to stay well inside both.
