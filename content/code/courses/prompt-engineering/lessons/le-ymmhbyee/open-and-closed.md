---
title: Open weights and closed models
version: 1
---

"Open" is used loosely about models, and the loose use hides the question that matters: **can you
get the weights, and what are you allowed to do with them?** A closed model is one you can only
use through its provider's service. An open-weight model is one whose weights you can download,
which, after lesson 8, you know means the whole model: the file of numbers and nothing else.

## Two ways to use a model

| | through an API | weights you run yourself |
|---|---|---|
| where it runs | the provider's machines | your machine, or a server you rent |
| what you pay | per token, every request | the hardware and the electricity, whatever the volume |
| memory | the provider's problem | parameters × bytes per weight, lesson 8 |
| your prompts | sent to the provider | never leave your machine |
| when the model changes | when the provider changes or retires it | when you decide |
| what you can change | the prompt | the prompt, and the weights, by fine-tuning (lesson 9) |

Neither column is better in general. An API gives you the largest models with no hardware at all,
and a model you run yourself gives you control and keeps the data in. Many open-weight models are
also offered through APIs by cloud companies, which is a third arrangement: someone else's
hardware, an open model, and their terms.

## Open weights are not open source

Open source, for software, means the source is published and you may study, change and share it.
**For a model, the weights are only one ingredient.** The training data, the code that trained it
and the filtering that shaped it are usually not published, and without them nobody can rebuild the
model or check what it was trained on. "Open weights" is the accurate term for most models called
open, and it is the one this course uses.

## What the licence allows

A downloadable model always comes with a licence, and licences differ in ways that matter to a
business. Some are standard open-source licences that allow almost anything with attribution.
Others are a company's own, and can restrict use above a certain size of company, forbid some
uses, require the model's name to appear in your product, or limit using its output to train
other models. **Read the licence of the exact model you download**, not a summary of the family:
two releases from one provider can carry different terms.

## Where your data goes

With an API, every prompt and every reply passes through the provider. What happens to it next is
written in the provider's terms and data policy, and it is the first thing a security or legal
reviewer will ask about. Questions to answer from the provider's own documents:

- is the data stored, and for how long?
- is it used to train future models, and can that be switched off?
- in which countries is it processed, and does that meet the rules you work under?
- do the consumer app and the business API have different terms? They often do.

**Never answer these from memory or from a blog post.** Terms change, and differ between plans of
the same provider. A model you run yourself answers all four by construction, which is one of the
main reasons organisations choose open weights despite the hardware.
