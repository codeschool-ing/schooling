---
title: Where to get a Llama
version: 1
---

An open model is reached through somebody's machine: your own (lessons 3 and 14) or a host's.
Maverick, by every host the sheet knows:

```
ana@desk:~/desk$ sheet where llama-4-maverick
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
databricks/databricks-llama-4-maverick               databricks                  0.50001 1.5000300000000002
lambda_ai/llama-4-maverick-17b-128e-instruct-fp8     lambda_ai                      0.05      0.1
novita/meta-llama/llama-4-maverick-17b-128e-instruct novita                         0.27     0.85
oci/meta.llama-4-maverick-17b-128e-instruct-fp8      oci                            0.72     0.72
openrouter/meta-llama/llama-4-maverick               openrouter                   0.1875   0.6525
vercel_ai_gateway/meta/llama-4-maverick              vercel_ai_gateway               0.2      0.6
vertex_ai/meta/llama-4-maverick-17b-128e-instruct-ma vertex_ai-llama_models         0.35     1.15
vertex_ai/meta/llama-4-maverick-17b-16e-instruct-maa vertex_ai-llama_models         0.35     1.15
watsonx/meta-llama/llama-4-maverick-17b              watsonx                       0.371    1.484
watsonx/meta-llama/llama-4-maverick-17b-128e-instruc watsonx                       0.371    1.484
```

Ten entries, and the spread lesson 2 section 05 led us to expect: from **$0.05 in and $0.10 out** at
one host to **$0.72 and $0.72** at another, more than fourteen times apart on input for weights that
are meant to be the same. Two of the names carry `fp8`, a reduced precision chosen by the host, so
"the same" is itself a question.

The table also shows the sheet's limits as a source:

- `0.50001` and `1.5000300000000002` are what a floating-point number looks like when somebody
  multiplied a price instead of typing it. Read them as $0.50 and $1.50.
- One Vertex entry is named `maverick-17b-16e`. Sixteen experts is Scout's count in section 03, not
  Maverick's; a name in a third party's list is a claim to check, like any other.

## Choosing a host for an open model

The model is fixed, so the host is chosen on everything else, in lesson 4's order:

1. **Thresholds**: does the host's processing meet the data terms of lesson 2 section 07? Which
   precision does it serve, and does that pass ana's cases?
2. **Trade-offs**: price, measured latency, the rate limits on her account.

And one property only open weights have: **if the host disappoints, the same model can move to the
next one**, or in-house, with the evaluation still valid. That is the control lesson 2 described,
and it is the reason lesson 3 told ana to keep candidates with available weights on her list.
