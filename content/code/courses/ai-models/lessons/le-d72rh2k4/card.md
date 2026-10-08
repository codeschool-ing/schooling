---
title: What Llama 4's card says
version: 1
---

Lesson 1 read Llama 3.1's card. Three paragraphs of Llama 4's answer the same questions, and two of
the answers have changed:

```
# meta-llama/llama-models@0e0b8c51 models/llama4/MODEL_CARD.md
  48: **Supported languages:** Arabic, English, French, German, Hindi, Indonesian, Italian,
      Portuguese, Spanish, Tagalog, Thai, and Vietnamese.
  90: **Overview:** Llama 4 Scout was pretrained on \~40 trillion tokens and Llama 4 Maverick
      was pretrained on \~22 trillion tokens of multimodal data from a mix of publicly
      available, licensed data and information from Meta’s products and services. This
      includes publicly shared posts from Instagram and Facebook and people’s interactions
      with Meta AI.
  92: **Data Freshness:** The pretraining data has a cutoff of August 2024\.
```

**Twelve supported languages**, up from eight, and Portuguese is still among them. For Lantern Books'
customers that keeps both generations on the short list for Portuguese, subject, as always, to the
cases.

**The training data now includes Meta's own products**: "publicly shared posts from Instagram and
Facebook and people's interactions with Meta AI", alongside public and licensed data. For choosing,
this is information about the model's knowledge (lots of informal, social text) and, for some
organisations, a question of policy about which models they are willing to build on. The card says
it plainly; a closed provider's documentation often says less.

**The cutoff is August 2024.** Lesson 1 said a cutoff matters little for ana's tasks and much for
tasks about the world. A Llama 4 released in 2025 knows nothing after mid-2024, and in October 2026
that is more than two years. The closed models in lesson 6 had cutoffs as late as June 2026; open
releases come less often, and **the gap between an open model's cutoff and today grows until the
next release**.

## The licence

Llama 4 has its own licence, and lesson 2 section 03 already quoted its two clauses that matter: the
700-million-user threshold, measured on Llama 4's release date, and *Built with Llama* on anything
that distributes it. Everything said there about reading the licence of the exact version you run
applies here: Llama 3.1's terms answered Llama 3.1's questions.
