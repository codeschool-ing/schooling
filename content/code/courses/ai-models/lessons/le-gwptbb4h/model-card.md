---
title: Reading a model card
version: 1
---

A **model card** is the document a model's makers publish beside it: what it was trained on, what
it is meant for, how it scored, and where it is known to fail. It is the closest thing a model has
to a datasheet, and most people skip it and read the benchmark table instead. The table is the
least useful part for a decision about your own task, because it measures somebody else's.

Llama 3.1's card runs to over a thousand lines. Two of its paragraphs answer questions ana has to
ask about any model before Lantern Books depends on it:

```
# meta-llama/llama-models@0e0b8c51 models/llama3_1/MODEL_CARD.md
  78: **Supported languages:** English, German, French, Italian, Portuguese, Hindi, Spanish,
      and Thai.
  93: **Intended Use Cases** Llama 3.1 is intended for commercial and research use in multiple
      languages. Instruction tuned text only models are intended for assistant-like chat,
      whereas pretrained models can be adapted for a variety of natural language generation
      tasks. The Llama 3.1 model collection also supports the ability to leverage the outputs
      of its models to improve other models including synthetic data generation and
      distillation. The Llama 3.1 Community License allows for these use cases.
```

## What to look for, in order

**Languages.** *Supported* means the makers tested it and stand behind the results. Portuguese is
on Llama 3.1's list, which matters for a shop whose customers write in Portuguese. The same card
says, a few hundred lines further on, that it was trained on more languages than those eight, and
"strongly discourage[s]" using it to converse in the others without further work. A language that
works in a quick test and is not on the list is a language nobody measured.

**Intended use.** The paragraph above separates the two kinds from section 07: instruction-tuned
for "assistant-like chat", pretrained for adapting. It also says the licence allows using the
model's outputs to improve other models, which some licences forbid outright. Lesson 2 shows one
that does.

**Training data and its date.** What it learnt from, and when that stopped. Section 10 is about
the date.

**Evaluations.** Read them for the **shape** rather than the score: which tasks were measured,
in which languages, against which other models, and with how many examples. A card that reports
only English benchmarks has told you nothing about Portuguese e-mail.

**Limitations and safety.** The part written by the people who know the model best, about how it
goes wrong. Llama 3.1's runs to several sections. A card with no limitations section is not a
model with no limitations.

## When there is no card

Closed providers publish something similar under other names: a *system card*, a model overview
page, release notes. They tell you less about the training data and nothing about the weights,
because you will never hold them. What they do publish, and what you must read, is the list of
**model identifiers and their retirement dates**, which lesson 2 reads from the sheet.

A card answers what the makers measured. **Whether the model does your task is a question only
your own cases can answer**, and lesson 5 is how to ask it.
