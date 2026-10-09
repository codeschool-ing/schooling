---
title: Qwen
version: 1
---

Qwen is Alibaba's family. Lesson 2 quoted its older licence, the Tongyi Qianwen agreement, with a
100-million-user threshold and a ban on using its outputs to improve other models. The current
generation's repository says something different:

```
# QwenLM/Qwen3@7a2f61ff README.md
 397: All our open-weight models are licensed under Apache 2.0.
 398: You can find the license files in the respective Hugging Face repositories.
```

**Apache 2.0 for all open-weight models**, with the licence files kept beside each model on Hugging
Face. That is a change of kind, not of detail: from a licence with conditions to one with none
beyond attribution. And it is the reason lesson 2 section 03 told ana to read the licence of the
version she runs: an answer read from Qwen's old agreement is wrong for Qwen 3.

## Reading Qwen's names

Qwen's names carry their architecture, and once read they say a lot:

```
ana@desk:~/desk$ python sheet.py where qwen3-235b-a22b
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
qwen.qwen3-235b-a22b-2507-v1:0                       bedrock_converse               0.22     0.88
bedrock_mantle/qwen.qwen3-235b-a22b-2507             bedrock_mantle                 0.22     0.88
fireworks_ai/accounts/fireworks/models/qwen3-235b-a2 fireworks_ai                   0.22     0.88
fireworks_ai/accounts/fireworks/models/qwen3-235b-a2 fireworks_ai                   0.22     0.88
fireworks_ai/accounts/fireworks/models/qwen3-235b-a2 fireworks_ai                   0.22     0.88
novita/qwen/qwen3-235b-a22b-fp8                      novita                          0.2      0.8
novita/qwen/qwen3-235b-a22b-instruct-2507            novita                         0.09     0.58
novita/qwen/qwen3-235b-a22b-thinking-2507            novita                          0.3        3
openrouter/qwen/qwen3-235b-a22b                      openrouter                    0.455     1.82
openrouter/qwen/qwen3-235b-a22b-2507                 openrouter                   0.0875     0.35
openrouter/qwen/qwen3-235b-a22b-thinking-2507        openrouter                     0.23      2.3
replicate/qwen/qwen3-235b-a22b-instruct-2507         replicate                     0.264     1.06
scaleway/qwen/qwen3-235b-a22b-instruct-2507          scaleway                       0.75     2.25
vertex_ai/qwen/qwen3-235b-a22b-instruct-2507-maas    vertex_ai-qwen_models          0.22     0.88
```

`qwen3-235b-a22b` is a mixture of experts (lesson 10 section 03) with **235 billion parameters in
total and 22 billion active**: the `a` is for active. So the memory to hold it is set by 235B and the
speed by 22B. `-2507` is a release, July 2025. `instruct` and `thinking` are the tuned and the
reasoning variants of the same release. `fp8` is a host's choice of precision.

The prices span a factor of more than eight on input, from $0.0875 to $0.75, for weights that share a name.

## The model that is not open

```
ana@desk:~/desk$ python sheet.py where qwen3-max | head -4
# LiteLLM model sheet at 21881c57, 4472 entries
entry                                                provider                     in $/M  out $/M
dashscope/qwen3-max                                  dashscope                         -        -
dashscope/qwen3-max-2026-01-23                       dashscope                         -        -
```

Qwen's largest model, Max, appears under `dashscope`, Alibaba Cloud's own API, and the sheet records
**no price** for it. The README's Apache sentence is about open-weight models, which is itself a
hint: a family can be open in most of its sizes and closed in its largest. Before choosing a Qwen
model for the open-weight option lesson 3 asked ana to keep, check that the one she means is among
those whose weights are published.
