---
title: Four generations in one file
version: 1
---

Llama is the first family in this directory that is **open-weight from the start**: the
previous lessons' providers sold access, while Meta publishes the weights, and most people who use
a Llama reach it on somebody else's machine. So the source here is not a price page but Meta's own repository, which describes every release
in one Python file, `models/sku_list.py`. Lesson 3 read the architecture numbers out of it. Its
descriptions list every model Meta has published there:

```
ana@desk:~/desk$ sources quote llama-skus 'description="Llama' | grep -o 'Llama [0-9.]* [^"]*' | sort -u
Llama 2 13b chat model
Llama 2 13b model
Llama 2 70b chat model
Llama 2 70b model
Llama 2 7b chat model
Llama 2 7b model
Llama 3 70b instruct model
Llama 3 70b model
Llama 3 8b instruct model
Llama 3 8b model
Llama 3.1 405b instruct model (BF16 weights for mp16)
Llama 3.1 405b instruct model (BF16 weights)
Llama 3.1 405b instruct model (FP8 quantized)
Llama 3.1 405b model (BF16 weights for mp16)
Llama 3.1 405b model (BF16 weights)
Llama 3.1 405b model (FP8 quantized)
Llama 3.1 70b instruct model
Llama 3.1 70b model
Llama 3.1 8b instruct model
Llama 3.1 8b model
Llama 3.2 11b vision instruct model
Llama 3.2 11b vision model
Llama 3.2 1b INT4 quantized LoRA
Llama 3.2 1b INT4 quantized SpinQuant
Llama 3.2 1b instruct model
Llama 3.2 1b model
Llama 3.2 3b INT4 quantized LoRA
Llama 3.2 3b INT4 quantized SpinQuant
Llama 3.2 3b instruct model
Llama 3.2 3b model
Llama 3.2 90b vision instruct model
Llama 3.2 90b vision model
Llama 3.3 70b instruct
Llama 4 Maverick (17b 128 experts instruct model)
Llama 4 Maverick (17b 128 experts model)
Llama 4 Maverick (FP8 quantized)
Llama 4 Scout (17b 16 experts instruct model)
Llama 4 Scout (17b 16 experts model)
```

Read it as four generations, each answering a different question:

- **Llama 2 and Llama 3**: two sizes or three, each as a base `model` and a tuned `chat` or
  `instruct` model, lesson 1 section 07's two kinds side by side.
- **Llama 3.1**: 8B, 70B and 405B, the sizes lesson 3 computed memory for, and the 405B published
  three ways: BF16 weights for two machine layouts, and **FP8 quantized**, lesson 3 section 04's
  smaller precision released by the makers themselves.
- **Llama 3.2**: small models, **1B and 3B**, including versions already quantized to INT4 for
  phones and laptops, and **vision** models at 11B and 90B that read images.
- **Llama 3.3**: a single 70B instruct model, and no base model listed beside it.
- **Llama 4**: two models named Scout and Maverick, described by **experts** rather than by size,
  which section 03 explains.

Two things this list teaches about open families in general. **The base model is not always
published**, so fine-tuning from a base (lesson 1 section 11) depends on the release. And **the
same model can ship in several precisions**: "Llama 3.1 405B" is three different downloads, and an
evaluation has to name which one it ran.
