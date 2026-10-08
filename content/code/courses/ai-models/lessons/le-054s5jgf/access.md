---
title: OpenAI, Azure and the rest
version: 1
---

The model ana priced in lesson 4, by every route the sheet knows:

```
ana@desk:~/desk$ python sheet.py where gpt-5.4-mini
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
aihubmix/gpt-5.4-mini                                aihubmix                       0.75      4.5
azure/eu/gpt-5.4-mini                                azure                         0.825     4.95
azure/gpt-5.4-mini                                   azure                          0.75      4.5
azure/gpt-5.4-mini-2026-03-17                        azure                          0.75      4.5
azure/us/gpt-5.4-mini                                azure                         0.825     4.95
azure_ai/gpt-5.4-mini                                azure_ai                       0.75      4.5
azure_ai/gpt-5.4-mini-2026-03-17                     azure_ai                       0.75      4.5
gpt-5.4-mini                                         openai                         0.75      4.5
gpt-5.4-mini-2026-03-17                              openai                         0.75      4.5
openrouter/openai/gpt-5.4-mini                       openrouter                     0.75      4.5
openrouter/openai/gpt-5.4-mini:batch                 openrouter                    0.375     2.25
perplexity/openai/gpt-5.4-mini                       perplexity                     0.75      4.5
```

**OpenAI's own API**, under the alias `gpt-5.4-mini` and the dated `gpt-5.4-mini-2026-03-17`, at
$0.75 and $4.50.

**Microsoft Azure**, twice: `azure` is Azure OpenAI and `azure_ai` is Azure's model catalogue, both
at OpenAI's price on the global route. Azure's `eu/` and `us/` routes cost **10% more**, $0.825 and
$4.95: the same regional premium Bedrock charged for Claude in lesson 2 section 07, for the same
guarantee about where requests are processed. For a European shop with a contract that says so,
this is the line to read.

**Routers and resellers** at the same price, and OpenRouter's `:batch` route at half, which is
OpenAI's batch tier reached through a router, as with Gemini in lesson 7.

## Three APIs at one address

```
ana@desk:~/desk$ python sheet.py show gpt-5.4-mini | grep supported_endpoints
supported_endpoints                        ['/v1/chat/completions', '/v1/batch', '/v1/responses']
```

The sheet lists three endpoints for this model. `/v1/chat/completions` is the shape most of the
industry copied, lesson 20's subject. `/v1/responses` is OpenAI's newer API, the subject of lesson
16, and the one OpenAI's newer features are built on. `/v1/batch` is where a file of requests is
sent for the half-price tier.

**For ana, the choice between them is mostly about portability.** Her evaluation harness in lesson 5
already speaks Chat Completions, and so do Mistral, Ollama and OpenRouter. Code written
against the Responses API gets OpenAI's newer features and loses that reach. Lesson 16 shows what
the Responses API adds, so the trade can be made knowing both sides.
