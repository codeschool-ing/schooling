---
title: What fine-tuning changes
version: 1
---

There are two ways to make a model answer about Marginalia. RAG leaves the model alone and puts the
right text in each request. **Fine-tuning** changes the model itself: it continues training on
examples of the behaviour you want, and the weights move until the model produces it. After a
fine-tuning run there is a new model, with its own name, that answers without being shown anything.

The belief most people start with is that fine-tuning is how a model *learns your documents*: train
it on the handbook and it will know the handbook. That is the job it does worst, and this lesson is
mostly about why.

## What a fine-tuning example looks like

A fine-tuning dataset is a file of conversations, each showing a request and the reply the model
should have given. The providers that offer it take the same format as their chat APIs, one
conversation per line. `dataset.py` builds one from this course's test set: for each of the 26
questions that have an answer, it takes the question, puts the best section in front of extract-1,
and keeps the reply as the answer the fine-tuned model should learn to give with no section at all.

```
ana@lab:~/rag$ python dataset.py
examples: 26
training tokens per epoch: 968
ana@lab:~/rag$ head -n 2 ft.jsonl
{"messages": [{"role": "user", "content": "How many days do I have to return a printed book?"}, {"role": "assistant", "content": "You have 30 days from delivery to return a printed book in the condition you received it."}]}
{"messages": [{"role": "user", "content": "Who pays for the return postage?"}, {"role": "assistant", "content": "Return postage is paid by the customer."}]}
```

**No fine-tuning was run for this course**: it needs a provider's training service or a GPU, and the
lab has neither. What follows describes what such a run does, and the numbers are the dataset's.

**Look at the second example.** It teaches the model that the customer pays for return postage, which
was the 2025 rule. The dataset was built by a retrieval step, the retrieval step found the replaced
policy, and the error went into the training data with nothing to mark it. Once a model is trained on
this line there is no citation to follow back to the document that caused it. The problem RAG showed
in lesson 1 is still there, only now it is inside the weights.

## Behaviour is learnt easily; facts are not

A fine-tuning run is good at teaching a **pattern that appears in every example**: answer in two
sentences, reply in Portuguese when the customer writes in Portuguese, always produce valid JSON with
these four fields, write like our support handbook. Every example repeats the pattern, so a few
hundred examples move the weights a long way in one direction.

A fact appears in one or two examples. To make the model reliably say "thirty days" in answer to
every way a customer might ask, the dataset needs that fact phrased many ways and asked many ways,
and the same for every other fact. Even then, a fact learnt from a few examples is held weakly: the
model will produce it for questions close to the training examples and something plausible for
questions further away, which is the closed-book failure of lesson 1 again, closer to your own data.
The providers' own guides to fine-tuning point the same way: they present it for format, style and
behaviour, and recommend retrieval when what is missing is knowledge.

## What it costs to make the change

Changing a fine-tuned model's behaviour means a new dataset, a new training run and a new model to
evaluate and deploy. Changing what a RAG system knows means changing a document and re-indexing it.
The next four sections compare the two on the four things that differ most: how fresh the answers
are, whether they can be traced, what they cost and whether anything can be removed.
