---
title: What a month costs
version: 2
---

Lesson 2 read the price lists. This section uses them to compare providers on one workload: **the
shop's support assistant, 2,000 questions a day, each with 1,500 tokens of prompt and 300 of
reply**. The prices are the ones lesson 2 section 04 listed, read on 2 October 2026: Anthropic's from
its own pricing page, OpenAI's and Google's from LiteLLM's copy at a pinned commit, because their own pages could
not be reached from the machine the course was recorded on.

```python
"""What one workload costs a month at each model's list price."""
# Dollars per million tokens, input and output: the list prices of lesson 2, read on 2026-10-02.
PRICES = {
    "claude-opus-5-5": (4, 20), "claude-sonnet-5-5": (2, 10), "claude-haiku-4-5": (1, 5),
    "gpt-5.5": (5, 30), "gpt-5.4": (2.5, 15), "gpt-5.4-mini": (0.75, 4.5), "gpt-5.4-nano": (0.2, 1.25),
    "gemini-pro-latest": (2, 12), "gemini-3.5-flash": (1.5, 9), "gemini-3.5-flash-lite": (0.3, 2.5),
}
REQUESTS, TOKENS_IN, TOKENS_OUT = 2_000 * 30, 1_500, 300

print(f"{REQUESTS:,} requests a month, {TOKENS_IN:,} tokens in and {TOKENS_OUT} out each")
rows = []
for model, (p_in, p_out) in PRICES.items():
    month = REQUESTS * (TOKENS_IN * p_in + TOKENS_OUT * p_out) / 1_000_000
    rows.append((month, model))
for month, model in sorted(rows):
    print(f"  {model:22} ${month:>9,.2f}")
```

```
ana@dev:~/shop$ python cost.py
60,000 requests a month, 1,500 tokens in and 300 out each
  gpt-5.4-nano           $    40.50
  gemini-3.5-flash-lite  $    72.00
  gpt-5.4-mini           $   148.50
  claude-haiku-4-5       $   180.00
  gemini-3.5-flash       $   297.00
  claude-sonnet-5-5      $   360.00
  gemini-pro-latest      $   396.00
  gpt-5.4                $   495.00
  claude-opus-5-5        $   720.00
  gpt-5.5                $   990.00
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A bar chart of one month&#x27;s cost for the same workload, 60,000 requests of 1,500 tokens in and 300 out, at ten models&#x27; list prices. From 40.50 dollars for gpt-5.4-nano to 990 dollars for gpt-5.5; claude-haiku-4-5 costs 180, claude-sonnet-5-5 360 and claude-opus-5-5 720.\"><defs><marker id=\"cs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"29\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gpt-5.4-nano</text><rect x=\"190\" y=\"20\" width=\"18.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"214.0\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$40.50</text><text x=\"180\" y=\"56\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gemini-3.5-flash-lite</text><rect x=\"190\" y=\"47\" width=\"32.0\" height=\"18\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"228.0\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$72.00</text><text x=\"180\" y=\"83\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gpt-5.4-mini</text><rect x=\"190\" y=\"74\" width=\"66.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"262.0\" y=\"83\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$148.50</text><text x=\"180\" y=\"110\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">claude-haiku-4-5</text><rect x=\"190\" y=\"101\" width=\"80.0\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"276.0\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$180.00</text><text x=\"180\" y=\"137\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gemini-3.5-flash</text><rect x=\"190\" y=\"128\" width=\"132.0\" height=\"18\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"328.0\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$297.00</text><text x=\"180\" y=\"164\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">claude-sonnet-5-5</text><rect x=\"190\" y=\"155\" width=\"160.0\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"356.0\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$360.00</text><text x=\"180\" y=\"191\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gemini-pro-latest</text><rect x=\"190\" y=\"182\" width=\"176.0\" height=\"18\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"372.0\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$396.00</text><text x=\"180\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gpt-5.4</text><rect x=\"190\" y=\"209\" width=\"220.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"416.0\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$495.00</text><text x=\"180\" y=\"245\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">claude-opus-5-5</text><rect x=\"190\" y=\"236\" width=\"320.0\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"516.0\" y=\"245\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$720.00</text><text x=\"180\" y=\"272\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">gpt-5.5</text><rect x=\"190\" y=\"263\" width=\"440.0\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"636.0\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$990.00</text></svg>", "caption": "One workload, ten list prices, a factor of 24 between the ends. The spread inside each provider is nearly as wide as the spread between them."}
```

**From the cheapest to the dearest is a factor of about 24.** Within one provider the spread is
almost as wide: Opus costs four times Haiku, and `gpt-5.5` costs about 24 times `gpt-5.4-nano`.
The choice of model inside a provider moves the bill more than the choice of provider.

## What the table leaves out

- **Each provider counts tokens its own way.** 1,500 tokens is an assumption about one tokenizer.
  Count a sample of your real prompts with each provider's counting endpoint before trusting a
  comparison to the dollar.
- **Output is dearer than input**, by five to eight times at every row here. A model that writes
  twice as much as it needs to costs more than its price per token suggests, so measure the reply
  length on your task too.
- **Caching changes the input side.** The shop's system prompt is the same on every question; at
  the cache-read prices of lesson 2, the repeated part of the prompt costs a tenth or less.
- **The cheapest model that fails is the dearest.** A wrong answer costs a support ticket, a
  refund or a customer, and none of that is on the price list. Lesson 10 section 07 is about
  finding out which models are good enough before comparing prices.
