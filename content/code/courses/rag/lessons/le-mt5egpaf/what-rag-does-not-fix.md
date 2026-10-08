---
title: What retrieval does not fix
version: 2
---

RAG is sold as the cure for a model that makes things up, and it cures a particular disease: the
model not having the text. Every other way of being wrong survives it, and some get worse, because
now the wrong answer arrives with a citation that makes it look checked. Four of them matter from the
first day, and this lesson's own runs show three.

## A document that should not have been found

```
ana@vm:~/rag$ python tiny_rag.py "Who pays for the return postage?"
[1] 0.798  returns-policy-2025 > Return postage
[2] 0.530  returns-policy > How to start a return
[3] 0.502  shipping-and-delivery > Damage in transit
According to [1], the customer pays for the return postage.
```

The question is about today's rules and the answer is 2025's: **return postage has been free since
February 2026.** The search did nothing wrong by its own measure. The 2025 section is titled *Return
postage* and talks about nothing else, so its similarity to the question, 0.798, beats the current
policy's *How to start a return*, 0.530, where "Returns are free" is one sentence among many.

The index holds whatever was put into it, and it has no idea which documents are current. Deleting
the old policy is one fix, and keeping it while marking it superseded is another, because a support
agent sometimes needs to know what a customer was promised in 2025. Lesson 5 stores the status beside
every chunk, and lesson 14 makes the search respect it.

## Two sources that disagree

For the return window, the current policy and the replaced one were both retrieved, a hair apart, and
the model took its answer from the current one. For return postage the replaced policy ranked first
and the model took its answer from that. **A generator handed two contradicting sources may quote
one, quote both, or blend them into something neither says, and neither of those two choices was a
decision.** Nothing in the prompt said which source is current, so nothing could. Lesson 7 shows how
a prompt tells a generator which source wins, and why the dates have to be in the prompt for that to
work.

## The answer was there, and the reply missed it

The retrieval can put the section with the answer in front of the model and the reply can still
quote the wrong sentence of it, or answer a question slightly beside the one asked. **Retrieval
succeeded and generation failed.** It did not happen in this lesson's runs, and it is common enough
that a test of the final answer alone is not enough: such a test blames the search for the writer's
mistake, or the other way round. Lesson 8 measures retrieval and generation separately for exactly
this reason.

## No answer at all

```
ana@vm:~/rag$ python tiny_rag.py "Can I place an order by phone?"
[1] 0.453  terms-of-sale > 2. Placing an order
[2] 0.453  shipping-and-delivery > Addresses
[3] 0.358  shipping-and-delivery > Pickup points
According to the provided sources, the answer is:

No, you cannot place an order by phone. The sources do not mention phone orders as a valid method of placing an order.

There is no explicit statement that prohibits phone orders, but the provided information focuses on online ordering through the website, and the process of placing an order is described in the context of online transactions.
```

Marginalia's documents never mention ordering by phone, so the right reply is that they do not say.
**The search still returned three sections**: a search always returns its top three, whether or not
any of them is any good, and here the best scored 0.453. And the model, handed three sections that
do not answer the question, answered it anyway. Its answer is a rule, *you cannot place an order by
phone*, that nobody at Marginalia wrote, and two sentences later it admits that nothing prohibits
it. A
customer reads the first. Lesson 6 gives the search its own way to say it found nothing good, and
lesson 7 makes "the sources do not say" an instruction the model is tested against.

## And what it cannot reach

Some questions have no passage that answers them, because the answer is not written anywhere and has
to be computed. *How many of our documents mention a fourteen-day limit?* *Which policy changed most
this year?* *What do all our returns rules have in common?* A retrieval system finds a few passages;
it does not read the whole corpus. Questions about everything, or about counts and totals, belong to
a database query or a batch job, and lesson 2 draws that boundary with examples.

RAG also does not make a model reason better. Given the right passages, a model that misreads a
table misreads it in the prompt as it would anywhere. What retrieval guarantees is narrower and still
worth having: **the model reads the text it needs, and the reader can see which text that was.**
