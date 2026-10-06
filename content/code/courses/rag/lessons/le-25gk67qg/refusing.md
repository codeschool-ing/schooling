---
title: Saying the sources do not say
version: 1
---

The third line of the system message tells the model what to reply when the sources do not answer.
It is the most important instruction in the prompt, because the alternative is the closed-book answer
of lesson 1: fluent, confident and invented. And it is the one this lesson trusts least.

## The instruction, with nothing to apply it to

`no_floor.py` sends what `ask` would send if the code called the model whatever the search found: the
system message, the question, and no sources, because nothing scored above the floor.

```
ana@lab:~/rag$ python no_floor.py "Can I place an order by phone?"
You can call Marginalia's customer service on 0800 555 0199, every day from 9 am to 6 pm.
```

**The instruction said to reply that the documents do not cover it, and extract-1 gave a phone number
that does not exist.** With no sources in the prompt, its third rule has nothing to work on, and it
falls through to its closed-book memory, which always answers. That is extract-1's mechanism, written
in `labgen.py`; a real model has no such switch and would refuse more often than not. But *more often
than not* is the honest description of an instruction, and a phone number for a phone line that does
not exist is the kind of answer that ends up in a screenshot.

So `answer` does not ask:

```
ana@lab:~/rag$ python answer.py "Can I place an order by phone?"
I could not find that in our documents.
ana@lab:~/rag$ python answer.py "Is there a student discount?"
I could not find that in our documents.
ana@lab:~/rag$ python answer.py "Can I pay in instalments?"
I could not find that in our documents.
```

**When nothing clears the floor, the code returns the refusal and the model is never called.** The
first two are right: no document mentions ordering by phone or a student discount. The third is the
price lesson 6 named in advance: the answer is in the payments document, but its chunk scored 0.445,
below the floor of 0.5, so a customer asking about instalments is told the documents do not say. The
floor and its errors were chosen together, and the floor is the cheaper place to put the decision,
because it is a number in code, not a sentence a model may or may not obey.

## Where extract-1's own threshold came from

Lesson 1 promised to say where extract-1's 0.53 came from. It came from this list, which embeds every
sentence of every document and prints the best similarity each test question finds anywhere:

```
ana@lab:~/rag$ python floor.py | sort -r | sed -n "22,30p"
0.59  answerable    Can I pay in instalments?
0.55  answerable    When is the contract of sale formed?
0.55  answerable    What must I check before changing a customer's order?
0.55  answerable    What does error E-4102 mean in the affiliate API?
0.55  answerable    How long do you keep my order history?
0.52  unanswerable  Can I place an order by phone?
0.49  unanswerable  Which carrier do you use in Portugal?
0.47  unanswerable  Do you have a shop in Porto Alegre where I can pick up books?
0.37  unanswerable  Is there a student discount?
```

The weakest answerable questions find a sentence at 0.55; the strongest unanswerable one finds one at
0.52. **0.53 sits between them, and it was chosen by looking at the test set**, while the lab was
built. That makes it a perfect threshold for these thirty questions and an optimistic one for any
other: a threshold fitted to a test set will look better on that set than on the questions that
arrive next. Lesson 8 keeps a part of the test set aside for exactly this reason.

## Refusing well

A refusal is an answer, and it can be a good or a bad one. **Say what is not covered**, so a customer
who asked two things knows which one failed. **Offer a next step**, the contact form, a person, the
help centre's search, because a customer who is refused has still not had the question answered.
**And log it**: refusals are the cheapest list a team will ever get of documents it has not written.
