---
title: What a request costs, and what a feature costs
version: 1
---

A single request costs fractions of a cent, which is why nobody worries about it, and a feature
runs that request thousands of times a day, which is why the bill surprises people. Both numbers
come from the same arithmetic, and it is worth having it in code from the first day rather than in
a spreadsheet somebody made once.

## The cost function

Money is computed with `Decimal`, never with `float`, for the same reason the shop keeps its prices
in integer cents: a fraction of a cent multiplied by a few million requests is where rounding
errors become visible. The prices are the ones `prices.py` read, with the date beside them:

```schooling-example
{
  "language": "python",
  "file": "lab/cost.py",
  "parts": [
    {
      "code": "from decimal import Decimal\n\nimport anthropic\n\n# Dollars per million tokens, read from Anthropic's pricing page on 2026-10-02 (prices.py).\nPRICES = {\n    \"claude-opus-5-5\": (Decimal(\"4\"), Decimal(\"20\")),\n    \"claude-sonnet-5-5\": (Decimal(\"2\"), Decimal(\"10\")),\n    \"claude-haiku-4-5\": (Decimal(\"1\"), Decimal(\"5\")),\n}\nMILLION = Decimal(1_000_000)\n\n\n",
      "note": "**One table, with its date and its source.** A price with no date is a number nobody can check, and these move several times a year."
    },
    {
      "code": "def cost(model: str, input_tokens: int, output_tokens: int) -> Decimal:\n    price_in, price_out = PRICES[model]\n    return (input_tokens * price_in + output_tokens * price_out) / MILLION\n\n\n",
      "note": "**The whole formula.** A model missing from the table raises `KeyError` instead of costing zero, which is the failure you want."
    },
    {
      "code": "client = anthropic.Anthropic()\nr = client.messages.create(model=\"scripted-1\", max_tokens=300,\n                           messages=[{\"role\": \"user\", \"content\": \"Explain the shop's shipping rule.\"}])\nu = r.usage\nprint(f\"usage: {u.input_tokens} in, {u.output_tokens} out\")\nfor model in PRICES:\n    print(f\"  at {model} prices: ${cost(model, u.input_tokens, u.output_tokens):.6f}\")\n\n",
      "note": "**The usage of one real request, priced three ways.** The reply comes from `scripted-1`, so its text was written by the course; its token counts are real counts of that text."
    },
    {
      "code": "print(\"a month of 3,000 requests a day, 1,800 tokens in and 250 out each:\")\nfor model in PRICES:\n    print(f\"  {model}: ${cost(model, 1_800, 250) * 3_000 * 30:,.2f}\")",
      "note": "**The same formula at the size of a feature**, with the volume and the token counts as assumptions written into the code where anybody can change them."
    }
  ],
  "output": "usage: 10 in, 147 out\n  at claude-opus-5-5 prices: $0.002980\n  at claude-sonnet-5-5 prices: $0.001490\n  at claude-haiku-4-5 prices: $0.000745\na month of 3,000 requests a day, 1,800 tokens in and 250 out each:\n  claude-opus-5-5: $1,098.00\n  claude-sonnet-5-5: $549.00\n  claude-haiku-4-5: $274.50"
}
```

## Reading the result

The reply was 10 tokens in and 147 out. **Output is almost 99% of the cost** of that request at any of the
three prices, because the question was short and the answer was not. Most chat-style requests look
like this, and the lever that matters there is how long you let the answer be.

The monthly figure is the one to show whoever approves the feature. 3,000 requests a day of 1,800
tokens in and 250 out comes to a little over a thousand dollars a month on the most expensive of
the three, and a quarter of that on the cheapest. **The inputs to that estimate are guesses until
you measure them**, and the way to measure them is the `usage` you log on every call (lesson 2
section 03). Revisit the estimate after a week of real traffic; the token counts are almost
always higher than the guess, because real users paste things.

## Costs nobody puts in the first estimate

- **Retries.** A request that fails at the provider and is sent again is usually not billed, but
  one that succeeds and is thrown away by your code (a reply that failed validation, lesson 8) is
  billed in full.
- **The conversation.** A chat sends its history every turn, so its cost per turn grows; lesson 2
  section 06 measures how fast.
- **Development.** Your own tests and experiments run against the same price list. Lesson 4 keeps
  model calls out of the unit tests for that reason among others.
