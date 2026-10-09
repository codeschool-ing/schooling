---
title: When fine-tuning wins
version: 2
---

The last four sections leave fine-tuning looking like the wrong tool, and for teaching a model a
company's facts it usually is. It is the right tool for a different job, and a team that rules it out
entirely ends up trying to do that job with prompts, badly.

## When the problem is how, not what

Fine-tuning changes behaviour that appears in every reply. That makes it the right tool when the
model has the knowledge, or is given it by retrieval, and gets the **form** wrong.

- **A strict output format.** A support system that hands replies to a ticketing tool needs the same
  JSON shape every time, with the same field names. A prompt can ask for it; a few hundred examples
  make it the model's habit.
- **A house style.** The support handbook in this corpus says: the answer first, the customer's name
  once, one apology at most, the next step with a date. A model can be told that in every prompt and
  will drift from it under pressure from a long context; a model trained on a few hundred replies
  written that way drifts much less.
- **A domain's language.** A model that keeps calling a *pickup point* a *collection locker*, or that
  misreads the shop's own abbreviations, learns the vocabulary from examples faster than from a
  glossary in every prompt.
- **Refusing well.** Saying "the documents do not cover this" instead of guessing is behaviour, and
  it can be taught. A model fine-tuned on examples where the right reply is a refusal refuses more
  readily, with the retrieved context still deciding what it knows.

## When the prompt is too expensive

Every instruction in a system prompt is paid for on every request, and long instructions also cost
time before the first token. A behaviour that needs a page of instructions and twenty examples to
hold reliably costs that page on every question, for ever. Fine-tuning moves the page into the
weights. At high volume that can pay for the training several times over, which is the same
break-even arithmetic as the cost section, applied to instructions instead of knowledge.

The extreme version is **distillation**: a large, expensive model's replies are used as training
examples for a small, cheap one, which then does that one job nearly as well at a fraction of the
price and latency. It is how many production systems run a narrow task at scale, and it is a
fine-tuning run like any other.

## When there is no time to retrieve

Retrieval adds a search to every request: an embedding of the question, a query to the index, and a
longer prompt for the model to read. On the machine this course was recorded on, the search is one
embedding and one matrix product, and for most uses its time does not matter. For a voice assistant or an autocomplete, where the whole reply has a budget of a few
hundred milliseconds, a model that already knows the small, stable set of facts it needs can be the
only design that fits.

## What none of these wins changes

In every case above, **the facts still come from somewhere you can update and cite**, or they are few
and stable enough to accept the cost of retraining when they change. A fine-tuned model that has to
answer about Marginalia's policies is still a model that needs the policies in its prompt; what the
fine-tuning bought is that it answers in the right shape, in the right voice, and refuses when it
should. That is the combination the next section recommends.
