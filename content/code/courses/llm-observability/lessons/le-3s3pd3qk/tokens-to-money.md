---
title: From tokens to money
version: 1
---

The spans record tokens. Money is worked out from them, and **where** that is done is the first
decision. The obvious place is the span itself: multiply on the spot, record `app.cost = 0.0006`, add
it up later. It is the wrong place, because prices change, and a span written with last month's price
cannot be corrected without rewriting it.

The lab's price list is a file:

```
ana@lab:~/obs$ cat prices.json
{
  "note": "Written by the course for the lab. No provider charges these prices; read your own provider's page.",
  "currency": "USD",
  "per": "1000000 tokens",
  "models": {
    "extract-1": [
      {"from": "2026-01-01", "input": "2.00", "output": "8.00"},
      {"from": "2026-10-01", "input": "1.50", "output": "6.00"}
    ],
    "extract-2": [{"from": "2026-09-15", "input": "3.00", "output": "12.00"}],
    "judge-1": [{"from": "2026-01-01", "input": "0.40", "output": "1.60"}],
    "lab-minilm": [{"from": "2026-01-01", "input": "0.02", "output": "0"}]
  }
}
```

**These prices were written by the course and no provider charges them.** They have the shape real
price lists have: a price per million tokens, different for input and output, with output four times
input, and a cheaper model for judging. And they change: extract-1 got 25% cheaper on 1 October, the
Thursday of the replayed week.

So each model has a list of prices, each from a date, and a span is charged the one in force on the
day it ran. That is an **effective-dated price**: a new price is a new row, and the old one stays for
the days it applied to. The question "what did Tuesday cost" has the same answer before and after the
price changes, which it would not if somebody overwrote the old number.

```
ana@lab:~/obs$ python -c "import costs; print(costs.price_at(\"extract-1\", \"2026-09-30\"), costs.price_at(\"extract-1\", \"2026-10-01\"))"
(Decimal('2.00'), Decimal('8.00')) (Decimal('1.50'), Decimal('6.00'))
```

`costs.py` does the rest:

```schooling-example
{
  "language": "python",
  "file": "costs.py",
  "parts": [
    {
      "code": "PRICES = json.load(open(\"prices.json\"))\nMILLION = Decimal(1_000_000)\n\n\ndef price_at(model, day):\n    \"\"\"(input, output) in dollars per million tokens for MODEL on DAY, an ISO date.\"\"\"\n    rows = [p for p in PRICES[\"models\"].get(model, []) if p[\"from\"] <= day]\n    if not rows:\n        raise LookupError(f\"no price for {model} on {day}\")\n    p = max(rows, key=lambda p: p[\"from\"])\n    return Decimal(p[\"input\"]), Decimal(p[\"output\"])",
      "note": "The price list is read once. `price_at` picks, for a model and a day, the latest price whose date is not after that day, which is what an effective-dated price means: a new price is a new row, and the old one stays for the days it applied to."
    },
    {
      "code": "def span_cost(s):\n    \"\"\"The cost of one span: zero unless it records tokens.\"\"\"\n    a = s[\"attributes\"]\n    if \"gen_ai.usage.input_tokens\" not in a:\n        return Decimal(0)\n    model = a.get(\"gen_ai.response.model\") or a[\"gen_ai.request.model\"]\n    pin, pout = price_at(model, datetime.fromtimestamp(s[\"start\"] / 1e9).date().isoformat())\n    return (a[\"gen_ai.usage.input_tokens\"] * pin + a.get(\"gen_ai.usage.output_tokens\", 0) * pout) / MILLION",
      "note": "A span with tokens is charged its input and output at the price of the day it ran. `Decimal` keeps every digit: `0.1 + 0.2` in floating point is not `0.3`, and a sum of a million small floats drifts."
    },
    {
      "code": "ROOT = {\"app.feature\": \"feature\", \"app.release\": \"release\", \"app.outcome\": \"outcome\",\n        \"user.hash\": \"user\", \"session.id\": \"session\", \"gen_ai.request.model\": \"model\"}\n\n\ndef requests(path=\"spans.jsonl\"):\n    \"\"\"One record per trace: its root's attributes, when it started, how long it took, its tokens, its cost.\"\"\"\n    by = defaultdict(list)\n    for line in open(path):\n        s = json.loads(line)\n        by[s[\"trace\"]].append(s)\n    out = []\n    for trace, spans in by.items():\n        root = next(s for s in spans if s[\"parent\"] is None)\n        chats = [s for s in spans if s[\"attributes\"].get(\"gen_ai.operation.name\") == \"chat\"]\n        out.append({\"trace\": trace, \"at\": datetime.fromtimestamp(root[\"start\"] / 1e9),\n                    \"ms\": (root[\"end\"] - root[\"start\"]) / 1e6, \"status\": root[\"status\"],\n                    **{short: root[\"attributes\"].get(k) for k, short in ROOT.items()},\n                    \"input\": sum(s[\"attributes\"].get(\"gen_ai.usage.input_tokens\", 0) for s in chats),\n                    \"output\": sum(s[\"attributes\"].get(\"gen_ai.usage.output_tokens\", 0) for s in chats),\n                    \"cost\": sum((span_cost(s) for s in spans), Decimal(0))})\n    return sorted(out, key=lambda r: r[\"at\"])",
      "note": "One record per trace, with the root's attributes under short names and the costs of all its spans added up. The embedding's tokens count too, at their own price."
    }
  ]
}
```

## One request, priced

```
ana@lab:~/obs$ python -c "import costs; r = next(r for r in costs.requests() if r[\"output\"]); print(r[\"trace\"], r[\"feature\"], r[\"input\"], r[\"output\"], r[\"cost\"])"
4be957f9979d11e46acb125624458d2d help 252 13 0.00060806
ana@lab:~/obs$ python tree.py --attrs 4be957f9 | grep -E " ms |usage|model"
      0   1,101 ms  ask
                     gen_ai.request.model = "extract-1"
      0     276 ms    embed
                       gen_ai.request.model = "lab-minilm"
                       gen_ai.usage.input_tokens = 3
    277      15 ms    search
    294     806 ms    generate
    294     806 ms      chat extract-1
                         gen_ai.request.model = "extract-1"
                         gen_ai.usage.input_tokens = 252
                         gen_ai.usage.output_tokens = 13
                         gen_ai.response.model = "extract-1"
  1,100       1 ms    check_citations
```

252 input tokens and 13 output tokens at extract-1's September price: 252 × 2.00 plus 13 × 8.00,
divided by a million, is 0.000608 dollars, and the embedding's 3 tokens at 0.02 add 0.00000006. The
total is 0.00060806 dollars, printed to the last digit because a `Decimal` keeps them all.

Look at where the tokens were. **The input is 95% of the tokens and 83% of the cost**, although every
output token is four times the price. That is the shape of a retrieval assistant: a long prompt of
instructions and sources, a short answer. It decides which lever is worth pulling: a shorter prompt
saves more than a shorter answer, the opposite of what lesson 1's latency suggested, where the answer
was most of the time.
