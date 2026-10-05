---
title: Two ways to pay
version: 1
---

A closed model is paid for **per token**, to the provider or to a cloud that resells it. An open
model can be paid for the same way, to any of the companies that host it, or **per hour**, for a
machine you run it on yourself. Lesson 3 is about the second. This section is about what the first
looks like for each kind, read off the sheet.

`sheet where` lists every entry whose name contains a string. Here is one open model, Llama 3.3
70B, and every host that the sheet prices:

```
ana@desk:~/desk$ sheet where llama-3.3-70b
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
cerebras/llama-3.3-70b                               cerebras                       0.85      1.2
cloudflare/@cf/meta/llama-3.3-70b-instruct-fp8-fast  cloudflare                    0.293    2.253
novita/meta-llama/llama-3.3-70b-instruct             novita                        0.135      0.4
oci/meta.llama-3.3-70b-instruct                      oci                            0.72     0.72
oci/meta.llama-3.3-70b-instruct-fp8-dynamic          oci                            0.72     0.72
openrouter/meta-llama/llama-3.3-70b-instruct         openrouter                     0.22      0.5
scaleway/meta/llama-3.3-70b-instruct                 scaleway                        0.9      0.9
snowflake/snowflake-llama-3.3-70b                    snowflake                      0.72     0.72
vercel_ai_gateway/meta/llama-3.3-70b                 vercel_ai_gateway              0.72     0.72
vertex_ai/meta/llama-3.3-70b-instruct-maas           vertex_ai-llama_models         0.72     0.72
```

Ten entries from nine providers, and the cheapest input price is **$0.135** a million tokens against
**$0.90** at the dearest: almost seven times as much for the same weights. The output prices run
from $0.40 to $2.253. Some of the difference is real: `fp8` in a name means the host runs the
weights at reduced precision, which lesson 3 explains, and the hosts differ in speed and in what
they promise about availability. But a large part of it is **competition**. Anybody with the
hardware may serve these weights, so they do, and the price falls towards the cost of the machine.

Now a closed model, Claude Sonnet 5.5:

```
ana@desk:~/desk$ sheet where claude-sonnet-5-5
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
claude-sonnet-5-5                                    anthropic                         2       10
azure_ai/claude-sonnet-5-5                           azure_ai                          2       10
bedrock/us-gov-east-1/anthropic.claude-sonnet-5-5    bedrock                         2.4       12
bedrock/us-gov-west-1/anthropic.claude-sonnet-5-5    bedrock                         2.4       12
anthropic.claude-sonnet-5-5                          bedrock_converse                  2       10
apac.anthropic.claude-sonnet-5-5                     bedrock_converse                2.2       11
au.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
eu.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
global.anthropic.claude-sonnet-5-5                   bedrock_converse                  2       10
jp.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
us-gov.anthropic.claude-sonnet-5-5                   bedrock_converse                2.4       12
us.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
bedrock_mantle/anthropic.claude-sonnet-5-5           bedrock_mantle                  2.2       11
bedrock_mantle/us-gov-west-1/anthropic.claude-sonnet bedrock_mantle                  2.4       12
perplexity/anthropic/claude-sonnet-5-5               perplexity                        2       10
vertex_ai/claude-sonnet-5-5                          vertex_ai-anthropic_models        2       10
vertex_ai/claude-sonnet-5-5@default                  vertex_ai-anthropic_models        2       10
```

Seventeen entries, and every one is Anthropic's model resold, or reached through Anthropic's own
API. The prices barely move: **$2** in and **$10** out at Anthropic itself, at Azure, at Google's
Vertex and on Bedrock's `global` route; ten per cent more on Bedrock's regional routes, twenty per
cent more for the US government regions. No host can undercut the maker, because no host has
anything to sell but access to the maker's model.

## What that means for choosing

- **An open model is a commodity, and a commodity is shopped for.** The model is fixed; choose
  the host for price, speed and terms, and change host without changing a line of the prompt.
  Lesson 15 shows a router that does the shopping per request.
- **A closed model has one price**, set by the people who made it, with small regional
  differences. What you negotiate is volume, not the per-token rate on the page.
- **Per token is never the whole bill.** It is the part that scales with use. Lesson 4 adds the
  other parts, and lesson 21 the ones that only show up when something goes wrong.

The sheet is a third party's copy taken at one commit, and both lists will have moved by the time
you read this. **The shape is what lasts**: many hosts and a wide spread for open weights, one
maker and a narrow band for closed ones.
