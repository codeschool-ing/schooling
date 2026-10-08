---
title: The clauses that decide
version: 1
---

A model licence is a few pages long, and most of it is the same boilerplate any licence carries:
warranties disclaimed, liability limited, which courts. Three kinds of clause are particular to
models, and they are the ones to read before anything else.

## A ceiling on how big you may grow

```
# meta-llama/llama-models@0e0b8c51 models/llama3_1/LICENSE
  33: 2. Additional Commercial Terms. If, on the Llama 3.1 version release date, the monthly
      active users of the products or services made available by or for Licensee, or
      Licensee’s affiliates, is greater than 700 million monthly active users in the preceding
      calendar month, you must request a license from Meta, which Meta may grant to you in its
      sole discretion, and you are not authorized to exercise any of the rights under this
      Agreement unless or until Meta otherwise expressly grants you such rights.
```

Seven hundred million monthly users is a number Lantern Books will not reach. Notice how the clause
works, though: the count is taken **on the release date**, and above it the licence grants nothing
at all until Meta agrees. It is a clause aimed at a handful of companies, and it is written so that
it cannot be grown into by accident.

Qwen's older licence has the same shape at a lower number, and a second clause that matters more
to most readers:

```
# QwenLM/Qwen@2df8e8ac Tongyi Qianwen LICENSE AGREEMENT
  29: If you are commercially using the Materials, and your product or service has more than
      100 million monthly active users, You shall request a license from Us. You cannot
      exercise your rights under this Agreement without our express authorization.
  33: b. You can not use the Materials or any output therefrom to improve any other large
      language model (excluding Tongyi Qianwen or derivative works thereof).
```

**One hundred million users** is still far off for a bookshop. **Clause b** is not: it forbids
using the model's *output* to improve any other large language model. Generating training
examples with one model to fine-tune another (lesson 1 section 11's fourth step) is a common
plan, and under this licence it is allowed only towards Qwen itself. Llama 3.1's card, quoted in
lesson 1, says the opposite: its licence allows exactly that use.

## What you owe when you ship it

```
# meta-llama/llama-models@0e0b8c51 models/llama3_1/LICENSE
  25: i. If you distribute or make available the Llama Materials (or any derivative works
      thereof), or a product or service (including another AI model) that contains any of
      them, you shall (A) provide a copy of this Agreement with any such Llama Materials; and
      (B) prominently display “Built with Llama” on a related website, user interface,
      blogpost, about page, or product documentation. If you use the Llama Materials or any
      outputs or results of the Llama Materials to create, train, fine tune, or otherwise
      improve an AI model, which is distributed or made available, you shall also include
      “Llama” at the beginning of any such AI model name.
```

Two obligations, and both fall on whoever **distributes** the model or a product containing it: a
copy of the agreement, and the words *Built with Llama* somewhere visible. A third applies to
anybody who uses Llama's outputs to train a model they then release: its name has to start with
*Llama*.

Calling a model through somebody's API is not distributing it. Shipping an app that bundles the
weights, or offering a hosted model to customers, is.

## A list of uses that are not allowed

Most open-weight licences carry, or point to, an **acceptable use policy**: a list of purposes the
model may not serve. Llama's is a separate document; DeepSeek's are an attachment to the licence
(section 04 quotes the paragraph that introduces them). They forbid things such as helping to harm
people or breaking the law, and they travel with the model: derivatives have to carry them too.

## How to read one, in practice

1. Find the **grant**: what you may do, and the adjectives on it.
2. Find any **threshold**: users, revenue, company size. Note when it is measured.
3. Find what it says about **outputs**: may they train other models?
4. Find the **obligations on distribution**: notices, names, attribution.
5. Find the **use policy**, and read it against what your product does.

Five questions, a quarter of an hour, and a written note in the project of what the answers were
and which version of the licence they came from. **A licence is versioned like the model**: Llama 4
has its own, and section 06 shows why an old answer cannot be assumed for a new release.
