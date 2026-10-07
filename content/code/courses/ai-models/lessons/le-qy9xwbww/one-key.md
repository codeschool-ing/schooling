---
title: One key in front of many
version: 1
---

Lessons 6 to 12 met each provider on its own: its own key, its own SDK, its own bill. **OpenRouter**
puts one address and one key in front of most of them. A request names a model as `maker/model`,
in OpenAI's shape from lesson 9 section 05, and OpenRouter forwards it to a provider that serves
that model. In the model sheet it is the largest single entry, by some way:

```
ana@desk:~/desk$ python sheet.py count | head -4
# LiteLLM model sheet at 21881c57, 4472 entries
  490  openrouter
  335  fireworks_ai
  305  azure
```

openrouter.ai was refused by the network of the machine this course was recorded on, and an
OpenRouter key is a bill. So this lesson shows two things that are real: what OpenRouter's
documentation says, read at a pinned commit, and what a request to it looks like, sent through the
relay from lesson 9 section 03 to Ollama. **What OpenRouter would answer is quoted from its
documentation and never shown as if it had run.**

## What it costs

The sheet lists the same models through OpenRouter and from their makers:

```
ana@desk:~/desk$ python sheet.py compare claude-sonnet-4-5 openrouter/anthropic/claude-sonnet-4.5 gemini-2.5-flash openrouter/google/gemini-2.5-flash
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
claude-sonnet-4-5                             1,000,000    64000        3       15  VFSCRP
openrouter/anthropic/claude-sonnet-4.5        1,000,000    64000        3       15  VFSCRP
gemini-2.5-flash                              1,048,576    65535      0.3      2.5  VFSCRP
openrouter/google/gemini-2.5-flash            1,048,576    65535      0.3      2.5  VFSCRP
```

Identical, and the documentation says why:

```
# OpenRouterTeam/docs@3e840a21 faq.mdx
  72: We pass through the pricing of the underlying providers; there is no markup
  83: OpenRouter charges a {getTotalFeeString('stripe', null)} fee when you purchase credits.
      We pass through
```

The fee is a template in that page, filled from a constants file beside it, which says what it
comes to:

```
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
# OpenRouterTeam/docs@3e840a21 cookbook/administration/usage-accounting.mdx
  73: - `cost`: The total amount charged to your account
  74: - `cost_details.upstream_inference_cost`: The actual cost charged by the upstream AI
      provider
```

Prices in its list of models are **dollars per token, as strings**, where the sheet and lesson 4
used dollars per million: $3 per million is `0.000003`. Summing `usage.cost` over a month is the
bill lesson 21 controls, with no second source to reconcile.
