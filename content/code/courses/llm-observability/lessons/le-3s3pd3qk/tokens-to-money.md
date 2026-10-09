---
title: From tokens to money
version: 2
---

The spans record tokens. Money is worked out from them, and **where** that is done is the first
decision. The obvious place is the span itself: multiply on the spot, record `app.cost = 0.0006`, add
it up later. It is the wrong place, because prices change, and a span written with last month's price
cannot be corrected without rewriting it.

The price list is a file. Save it as `prices.json` in `~/obs`:

```json
{
  "note": "Written by the course. Ollama charges nothing per token; these are what a hosted provider might charge for each model, chosen so that a week adds up to sums worth reading. Read your own provider's page.",
  "currency": "USD",
  "per": "1000000 tokens",
  "models": {
    "llama3.2:3b": [
      {"from": "2026-01-01", "input": "2.00", "output": "8.00"},
      {"from": "2026-09-30", "input": "1.50", "output": "6.00"}
    ],
    "llama3.2:1b": [{"from": "2026-01-01", "input": "0.50", "output": "2.00"}],
    "all-minilm": [{"from": "2026-01-01", "input": "0.02", "output": "0"}]
  }
}
```

**These prices were written by the course and no provider charges them.** Ollama charges nothing at
all, and the course still needs a bill to read. They have the shape real price lists have: a price
per million tokens, different for input and output, with output four times input, and a smaller
model that costs less. And they change: `llama3.2:3b` got 25% cheaper on 30 September, the Wednesday
of the replayed week.

So each model has a list of prices, each from a date, and a span is charged the one in force on the
day it ran. That is an **effective-dated price**: a new price is a new row, and the old one stays for
the days it applied to. The question "what did Tuesday cost" has the same answer before and after the
price changes, which it would not if somebody overwrote the old number.

```
(Decimal('2.00'), Decimal('8.00')) (Decimal('1.50'), Decimal('6.00'))
```

`costs.py` does the rest:

```schooling-example
{
  "language": "python",
  "file": "costs.py",
  "parts": [
    {
      "code": "\"\"\"costs.py: what each request cost, from the tokens on its spans and the price in force when it ran.\n\n    import costs\n    for r in costs.requests():      # one record per trace in spans.jsonl\n        print(r[\"feature\"], r[\"cost\"])\n\nTokens are what the spans record; money is worked out here, at reading time,\nfrom prices.json. A price is effective-dated: each model has a list of prices,\neach from a date, and a span is charged the latest one whose date is not after\nthe moment it ran. Amounts are Decimal, never float.\n\"\"\"\nimport json\nfrom collections import defaultdict\nfrom datetime import datetime\nfrom decimal import Decimal\n\n",
      "note": "What the file is for. Tokens are on the spans; money is worked out here, every time somebody reads it."
    },
    {
      "code": "PRICES = json.load(open(\"prices.json\"))\nMILLION = Decimal(1_000_000)\n\n\ndef price_at(model, day):\n    \"\"\"(input, output) in dollars per million tokens for MODEL on DAY, an ISO date.\"\"\"\n    rows = [p for p in PRICES[\"models\"].get(model, []) if p[\"from\"] <= day]\n    if not rows:\n        raise LookupError(f\"no price for {model} on {day}\")\n    p = max(rows, key=lambda p: p[\"from\"])\n    return Decimal(p[\"input\"]), Decimal(p[\"output\"])\n\n\n",
      "note": "The price list is read once. `price_at` picks, for a model and a day, the latest price whose date is not after that day, which is what an effective-dated price means: a new price is a new row, and the old one stays for the days it applied to."
    },
    {
      "code": "def span_cost(s):\n    \"\"\"The cost of one span: zero unless it records tokens.\"\"\"\n    a = s[\"attributes\"]\n    if \"gen_ai.usage.input_tokens\" not in a:\n        return Decimal(0)\n    model = a.get(\"gen_ai.response.model\") or a[\"gen_ai.request.model\"]\n    pin, pout = price_at(model, datetime.fromtimestamp(s[\"start\"] / 1e9).date().isoformat())\n    return (a[\"gen_ai.usage.input_tokens\"] * pin + a.get(\"gen_ai.usage.output_tokens\", 0) * pout) / MILLION\n\n\n",
      "note": "A span with tokens is charged its input and output at the price of the day it ran. `Decimal` keeps every digit: `0.1 + 0.2` in floating point is not `0.3`, and a sum of a million small floats drifts."
    },
    {
      "code": "ROOT = {\"app.feature\": \"feature\", \"app.release\": \"release\", \"app.outcome\": \"outcome\",\n        \"user.hash\": \"user\", \"session.id\": \"session\", \"gen_ai.request.model\": \"model\"}\n\n\ndef requests(path=\"spans.jsonl\"):\n    \"\"\"One record per trace: its root's attributes, when it started, how long it took, its tokens, its cost.\"\"\"\n    by = defaultdict(list)\n    for line in open(path):\n        s = json.loads(line)\n        by[s[\"trace\"]].append(s)\n    out = []\n    for trace, spans in by.items():\n        root = next(s for s in spans if s[\"parent\"] is None)\n        chats = [s for s in spans if s[\"attributes\"].get(\"gen_ai.operation.name\") == \"chat\"]\n        out.append({\"trace\": trace, \"at\": datetime.fromtimestamp(root[\"start\"] / 1e9),\n                    \"ms\": (root[\"end\"] - root[\"start\"]) / 1e6, \"status\": root[\"status\"],\n                    **{short: root[\"attributes\"].get(k) for k, short in ROOT.items()},\n                    \"input\": sum(s[\"attributes\"].get(\"gen_ai.usage.input_tokens\", 0) for s in chats),\n                    \"output\": sum(s[\"attributes\"].get(\"gen_ai.usage.output_tokens\", 0) for s in chats),\n                    \"cost\": sum((span_cost(s) for s in spans), Decimal(0))})\n    return sorted(out, key=lambda r: r[\"at\"])\n",
      "note": "One record per trace, with the root's attributes under short names and the costs of all its spans added up. The embedding's tokens count too, at their own price."
    }
  ]
}
```

## One request, priced

```
ana@dev:~/obs$ python -c "import costs; r = next(r for r in costs.requests() if r[\"output\"] and r[\"feature\"] == \"help\"); print(r[\"trace\"], r[\"feature\"], r[\"input\"], r[\"output\"], r[\"cost\"])"
3e9d6efdd66f2552ea1176f2a1bd9a4c help 279 32 0.00081418
ana@dev:~/obs$ python tree.py --attrs 3e9d6efd | grep -E " ms |usage|model"
      0   5,323 ms  ask
                     gen_ai.request.model = "llama3.2:3b"
      0     208 ms    embed
                       gen_ai.request.model = "all-minilm"
                       gen_ai.usage.input_tokens = 9
    208       0 ms    search
    208   5,114 ms    generate
    208   5,114 ms      chat llama3.2:3b
                         gen_ai.request.model = "llama3.2:3b"
                         gen_ai.usage.input_tokens = 279
                         gen_ai.usage.output_tokens = 32
                         gen_ai.response.model = "llama3.2:3b"
  5,323       0 ms    check_citations
```

The first help question of the week to reach the model, at 07:34 on Monday. 279 input tokens and 32
output tokens at the price before Wednesday: 279 × 2.00 plus 32 × 8.00, divided by a million, is
0.000814 dollars, and the embedding's 9 tokens at 0.02 add 0.00000018. The total is 0.00081418
dollars, printed to the last digit because a `Decimal` keeps them all.

Look at where the tokens were. **The input is 90% of the tokens and 69% of the cost**, although every
output token is four times the price. That is the shape of a retrieval assistant: a long prompt of
instructions and sources, a short answer. It decides which lever is worth pulling: a shorter prompt
saves more than a shorter answer, the opposite of what lesson 1's latency suggested, where the answer
was most of the time.
