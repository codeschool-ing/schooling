---
title: What it does not know
version: 1
---

A pretrained model knows what was in its training text, and nothing that happened after the text
was collected. That date is the **knowledge cutoff**, and Llama 3.1's card states it plainly:

```
ana@desk:~/desk$ sources quote llama3.1-card "data freshness"
# meta-llama/llama-models@0e0b8c51 models/llama3_1/MODEL_CARD.md
 188: **Data Freshness:** The pretraining data has a cutoff of December 2023.
```

Two mistakes follow from it, and they point in opposite directions.

**The first is expecting it to know what is recent.** Ask a model with this cutoff about a book
published in 2025 and it has three options: say it does not know, describe an older book with a
similar title, or invent one. Tuning pushes models towards the first, and none of them manages it
every time, because the model has no list of what it does not know. A confident description of a
book that does not exist reads exactly like a confident description of one that does.

**The second is forgetting that most of what matters was never public.** The cutoff is the smaller
problem for Lantern Books. Its order numbers, its stock, its courier and its refund rules were never
in anybody's training data, before or after any date. No model, however recent, knows that
`LB-20417` is still in the warehouse. A newer model narrows the first gap and leaves the second
exactly as wide.

## What closes each gap

| what the model lacks | example | what supplies it |
|---|---|---|
| public facts after the cutoff | a title published last month | retrieval from a source you trust, or a newer model |
| your own facts, at any date | where order `LB-20417` is | retrieval from your own systems, every time |
| a fact that changes by the hour | stock of one title | a tool the model can call, never memory |

All three answers have the same shape: **put the fact in the prompt, at the moment of the
request.** The model then reads it as text, the way it reads the e-mail. Retrieving the right
passage is the subject of `embeddings-vectors` and `rag`, the two courses that follow this one
in the `ai` track; calling a tool is in `agents-mcp`.

## What that means for choosing

A later cutoff is worth something when your task is about the world: current libraries, recent
events, new products. For ana's tasks it is worth almost nothing. Sorting an e-mail into five labels
needs no fact newer than the language it is written in; extracting `LB-20417` needs none at all.

So **put the cutoff on the list of criteria only when your task depends on public, recent facts**,
and even then prefer supplying the facts to choosing a model for its date. A date is the one
property every model loses a little more of each day it stays in service.
