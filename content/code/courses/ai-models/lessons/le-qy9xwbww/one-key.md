---
title: One key in front of many
version: 1
---

Lessons 6 to 12 met each provider on its own: its own key, its own SDK, its own bill. **OpenRouter**
puts one address and one key in front of most of them. A request names a model as `maker/model`,
in OpenAI's shape from lesson 9 section 05, and OpenRouter forwards it to a provider that serves
that model. In the model sheet it is the largest single entry, by some way:

```
ana@desk:~/desk$ sheet count | head -4
# LiteLLM model sheet at 21881c57, 4472 entries
  490  openrouter
  335  fireworks_ai
  305  azure
```

openrouter.ai could not be reached from the machine this course was recorded on. Everything below
that OpenRouter *answers* is the lab's stand-in, at `OPENROUTER_BASE_URL`, with two models of its
own; everything OpenRouter *says* is its documentation, read at a pinned commit.

## What it costs

The sheet lists the same models through OpenRouter and from their makers:

```
ana@desk:~/desk$ sheet compare claude-sonnet-4-5 openrouter/anthropic/claude-sonnet-4.5 gemini-2.5-flash openrouter/google/gemini-2.5-flash
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
claude-sonnet-4-5                             1,000,000    64000        3       15  VFSCRP
openrouter/anthropic/claude-sonnet-4.5        1,000,000    64000        3       15  VFSCRP
gemini-2.5-flash                              1,048,576    65535      0.3      2.5  VFSCRP
openrouter/google/gemini-2.5-flash            1,048,576    65535      0.3      2.5  VFSCRP
```

Identical, and the documentation says why:

```
ana@desk:~/desk$ sources quote openrouter-faq "there is no markup|fee when you purchase credits"
# OpenRouterTeam/docs@3e840a21 faq.mdx
  72: We pass through the pricing of the underlying providers; there is no markup
  83: OpenRouter charges a {getTotalFeeString('stripe', null)} fee when you purchase credits.
      We pass through
```

The fee is a template in that page, filled from a constants file beside it, which says what it
comes to:

```
ana@desk:~/desk$ sources quote openrouter-fees "getTotalFeeString = |stripe"
# OpenRouterTeam/docs@3e840a21 snippets/exports/constants.mdx
 141: export const getTotalFeeString = (type, value) => {
 142: if (type === 'stripe') return '5.5% ($0.80 minimum)';
```

So the price per token is the provider's, and **the platform is paid when you buy credits**: 5.5%
on a card, never less than $0.80. Buying $100 of credits costs $5.50 more; buying $10 costs the
$0.80 minimum, which is 8%. For a desk the size of ana's that is the number to compare with having
three accounts with three providers, each with its own key to keep and its own bill to read.

## The response carries its cost

OpenRouter returns the cost of each request inside the response, in `usage.cost`, and its
documentation separates what the account was charged from what the provider charged:

```
ana@desk:~/desk$ sources quote openrouter-usage "upstream_inference_cost.: The|.cost.: The total"
# OpenRouterTeam/docs@3e840a21 cookbook/administration/usage-accounting.mdx
  73: - `cost`: The total amount charged to your account
  74: - `cost_details.upstream_inference_cost`: The actual cost charged by the upstream AI
      provider
```

`lab/or_cost.py` reads the model's prices from the models list and checks the arithmetic against
the response:

```python
import json
import os

import httpx
from openai import OpenAI

base, key = os.environ["OPENROUTER_BASE_URL"], os.environ["OPENROUTER_API_KEY"]
models = httpx.get(f"{base}/models", headers={"Authorization": f"Bearer {key}"}).json()["data"]
price = {m["id"]: m["pricing"] for m in models}["standin/large"]
print("standin/large, dollars per token:", price["prompt"], "in,", price["completion"], "out")

client = OpenAI(base_url=base, api_key=key)
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]
u = client.chat.completions.create(model="standin/large", messages=[
    {"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}]).usage
listed = u.prompt_tokens * float(price["prompt"]) + u.completion_tokens * float(price["completion"])
print(f"{u.prompt_tokens} in, {u.completion_tokens} out, at the listed prices: ${listed:.6f}")
print(f"usage.cost in the response:          ${u.cost:.6f}")
```

```
ana@desk:~/desk$ python lab/or_cost.py
standin/large, dollars per token: 0.000003 in, 0.000015 out
51 in, 1 out, at the listed prices: $0.000168
usage.cost in the response:          $0.000168
```

Prices in the list are **dollars per token, as strings**, where the sheet and lesson 4 used dollars
per million: $3 per million is `0.000003`. The two numbers agree here because the stand-in computes
both from one table. Against the real service, summing `usage.cost` over a month is the bill
lesson 21 controls, without a second source to reconcile.
