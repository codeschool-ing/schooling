---
title: The five providers and their families
version: 1
---

It is natural to want a ranking: which provider's model is best. **No ranking survives a year**,
because each of these companies releases new models several times a year, renames them, and
retires old ones. What lasts longer is the shape of each provider's offer: what its families of
models are called, and whether you reach them only through its service or can download them. This
section is that shape, at the time of writing (2026), with no version numbers, no prices and no
scores, because those are exactly what goes stale first.

| provider | the model families | how you reach them |
|---|---|---|
| OpenAI | GPT models, including ones built to reason at length before answering | the ChatGPT apps and OpenAI's API; it has also published some models with open weights |
| Google | Gemini; Gemma, a separate family of smaller open-weight models | the Gemini apps, Google's API and Google Cloud; Gemma weights can be downloaded |
| Anthropic | Claude | the Claude apps, Anthropic's API, and large cloud platforms that also offer it |
| Meta | Llama | weights you download under Meta's own licence, and Meta's assistant in its apps |
| xAI | Grok | the Grok app, the X platform and xAI's API; it has published the weights of an earlier Grok model |

Three things in the table matter more than the names.

**Each family is many models.** A provider usually offers several sizes of each generation at
once: a large one that is more capable and slower, and smaller ones that are cheaper and faster.
"We use Claude" or "we use GPT" says which company, not which model, and two models from one family
can differ more than two models from different companies.

**The same model is often sold in more than one place.** A model may be reachable through its
maker's own API and through one or more cloud platforms, with different prices, limits, regions and
data terms in each. Where you call a model from is a decision of its own.

**Five is not the whole field.** These are the providers this lesson's title names. Others publish
widely used models, several of them with open weights, among them Mistral AI in France and DeepSeek
and Alibaba's Qwen team in China. A choice made only among the famous five is a choice made with
part of the menu.

## Reasoning models

One development is worth naming because it changes how a model is used. Several providers now
offer models trained to write out a long chain of intermediate steps before the final answer,
sometimes hidden from you and sometimes shown. They tend to do better on problems with many steps,
such as mathematics and code, and they spend more tokens and more time per answer, which you pay
for. Lesson 26 is chain of thought, the prompting technique that asks for those steps in the prompt.

## What not to trust in this section

Everything in the table was checked at the time of writing and **will drift**: a family renamed,
a new open-weight release, a model available on a platform it was not on before. Read it as a map
of where to look, and read the provider's own documentation, with its date, for anything you are
about to depend on. The last section of this lesson is about how.
