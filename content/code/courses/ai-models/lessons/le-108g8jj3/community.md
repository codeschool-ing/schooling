---
title: Community models
version: 1
---

Most repositories on the Hub were not made by a model's makers. They were made from one: fine-tuned
on somebody's data, quantized to fit a laptop, merged from two others. The Hub's documentation names
the relationships and the field that records them:

```
# huggingface/hub-docs@08175d0f docs/hub/model-cards.md
 105: If your model is a fine-tune, an adapter, or a quantized version of a base model, you
      can specify the base model in the model card metadata section. This information can also
      be used to indicate if your model is a merge of multiple existing models. Hence, the
      `base_model` field can either be a single model ID, or a list of one or more base_models
      (specified by their Hub identifiers).
 156: The Hub will infer the type of relationship from the current model to the base model
      (`"adapter", "merge", "quantized", "finetune"`) but you can also set it explicitly if
      needed: `base_model_relation: quantized` for instance.
```

Four relationships, each changing something lessons 2 to 5 care about:

- **finetune**: different weights trained further; the behaviour, and the evaluation, are new.
- **adapter**: a small set of extra weights (LoRA is the common kind) loaded on top of the base;
  useless without the exact base it was trained on.
- **quantized**: the same model at lower precision, lesson 3 section 04's trade, made by whoever
  uploaded it.
- **merge**: weights averaged or combined from two or more models. Its licence is every parent's.

## Before trusting one

A community repository can be excellent; many of the most used quantizations are community uploads.
It can also be abandoned, mislabelled or worse. Five checks, in order, before ana would let one near
Lantern Books' e-mail:

1. **Who owns it.** An organisation with a history, or an account created last week.
2. **What it says it is.** `base_model` and `base_model_relation`, and whether they match the name.
3. **What licence it can actually have.** The base's licence wins over the YAML (lesson 2 section
   04).
4. **What format the weights are in.** `safetensors`, as section 03 said, not a pickle.
5. **Whether it passes the cases.** Lesson 5, pinned to the commit hash of the revision she tested.

The fifth is the one that decides. The first four decide whether it is worth running the fifth.
