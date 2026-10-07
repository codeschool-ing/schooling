---
title: Gemma
version: 1
---

Gemma is Google's open-weight family, the counterpart to the closed Gemini of lesson 7. Its
repository describes it in one sentence:

```
# google-deepmind/gemma@e2e0a7d3 README.md
   7| [Gemma](https://ai.google.dev/gemma) is a family of open-weights Large Language
   8| Model (LLM) by [Google DeepMind](https://deepmind.google/), based on Gemini
   9| research and technology.
  10|
```

"Based on Gemini research and technology", and published as weights. The terms Gemma is released
under are on Google's own site, which the machine this course was recorded on could not reach, so
this lesson does not quote them. That is exactly lesson 2 section 04's warning in practice: the
repository above is the code, and its licence file is the code's.

## Reading Gemma's names

One host's Gemma 4 entries, as the sheet has them:

```
ana@desk:~/desk$ sheet where google/gemma-4 | grep deepinfra
deepinfra/google/gemma-4-26B-A4B-it                  deepinfra                      0.07     0.34
deepinfra/google/gemma-4-31B-it                      deepinfra                      0.13     0.38
deepinfra/google/gemma-4-31B-it-Ultra                deepinfra                      0.27     0.76
deepinfra/google/gemma-4-31B-it-turbo                deepinfra                      0.09     0.34
deepinfra/google/gemma-4-E4B-it                      deepinfra                      0.02      0.1
```

- `-it` is Gemma's suffix for **instruction-tuned**, lesson 1 section 07's tuned kind, where Llama
  says `instruct`.
- `26B-A4B` is the same naming Qwen uses: 26 billion parameters in total, 4 billion active, a mixture
  of experts.
- `31B` with no `A` is a dense model, every parameter used for every token.
- `E4B` is a small model for phones and laptops; the `E` reads as *effective* parameters, a count of
  what is computed rather than what is stored, the same distinction section 03 drew with `A` and
  measured differently. Treat it as a size label and check the model card for what it means
  precisely.
- `-turbo` and `-Ultra` are **the host's** variants, with different prices, and lesson 10 section 05's
  question applies: what did the host change to make it faster or dearer?

At $0.02 to $0.27 a million input tokens, these are among the cheapest entries ana has seen in the
course. Small, open, cheap and from a provider whose closed models she already evaluates, a Gemma is
a natural candidate for the sorting task; its score on the forty cases is what would put it on the
list.
