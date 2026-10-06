---
title: What a model knows, and what it does not
version: 1
---

A language model knows what its training text taught it, and nothing else. That knowledge is
stored in its weights, which is why it is called **parametric knowledge**: it was fixed on the day
training stopped, and nothing a user does afterwards adds to it. The model does not look anything
up when it answers. It produces the text its training made most likely to follow the question.

The picture most people arrive with is different. They imagine the model consulting something, the
way a search engine consults an index, and they expect it to notice when the thing it consulted had
no answer. Neither happens. There is nothing to consult and nothing to notice: a question about a
subject the model never saw gets an answer shaped exactly like an answer about a subject it did.

## Three ways a fact is missing

A company's documents are missing from a model for three different reasons, and the third is the
dangerous one.

- **Private.** Marginalia's support handbook was never published, so no training run ever read it.
  The model has no idea what an agent may refund without approval.
- **New.** Anything written after the training cutoff is absent, however public it is. A policy
  published last month does not exist for a model trained last year.
- **Changed.** A fact that was true when the training text was written and is false now. The model
  learnt it, learnt it well, and repeats it with complete confidence.

The first two at least produce an answer with nothing behind it. The third produces an answer with
something behind it that used to be right, which is much harder to catch.

## Asking without a source

This course's lab has a generator called **extract-1**, and the next section says exactly what it
is. It answers through the same API a real model does, and for this section the one thing to know is
how it behaves when the question arrives alone, with no document beside it: it answers from a small
file of sentences the course wrote as what it "learnt in training", and it always answers.

`ask.py` sends one question and prints the reply:

```
ana@lab:~/rag$ python ask.py "How many days do I have to return a printed book?"
You can return a book to Marginalia within 14 days of delivery, as long as it is unread. Return postage is paid by the customer.
ana@lab:~/rag$ python ask.py "What is the phone number for customer service?"
You can call Marginalia's customer service on 0800 555 0199, every day from 9 am to 6 pm.
ana@lab:~/rag$ python ask.py "Can I get my money back for an e-book I downloaded yesterday?"
You can return a book to Marginalia within 14 days of delivery, as long as it is unread. Return postage is paid by the customer.
```

**All three replies are wrong, and all three read as correct.** The first is the *changed* case:
fourteen days and paid postage were Marginalia's rules in 2025, and the policy in force since
February 2026 gives thirty days and free returns. The second is a phone number for a phone line that
does not exist; nothing in the shop's documents mentions one. The third answers a question about
e-books with the rule for printed books, because that was the nearest thing it had.

```
ana@lab:~/rag$ grep -c "\"q\"" /opt/rag/share/memory.json
10
```

extract-1's memory is ten sentences, written by the course to behave the way a real model's memory
misbehaves. A real model's memory is vastly larger and mostly right, which makes the failure rarer
and the failures harder to spot. The shape is the same: **a fluent answer, no source, and no signal
in the text that tells a right one from a wrong one.**

## Why the model cannot just say it does not know

It would be convenient if the model refused when it lacked the fact. Training does push models
towards admitting ignorance, and modern models do it more than older ones. But a model has no record
of what it read, so it cannot check whether a fact was in its training text; all it has is how
likely each next word is. A plausible phone number is very likely text. **The model's confidence
measures how plausible the answer sounds, not whether it is true.**

That is the problem this course solves. Not by making the model know more, which only moves the
cutoff, but by giving it the right text at the moment it answers and making it say where the answer
came from.
