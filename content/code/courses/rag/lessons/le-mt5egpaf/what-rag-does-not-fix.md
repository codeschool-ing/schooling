---
title: What retrieval does not fix
version: 1
---

RAG is sold as the cure for a model that makes things up, and it cures a particular disease: the
model not having the text. Every other way of being wrong survives it, and some get worse, because
now the wrong answer arrives with a citation that makes it look checked. This lesson's own runs have
already shown four of them.

## A document that should not have been found

```
ana@lab:~/rag$ python tiny_rag.py "Who pays for the return postage?"
[1] 0.798  returns-policy-2025 > Return postage
[2] 0.530  returns-policy > How to start a return
[3] 0.502  shipping-and-delivery > Damage in transit
Return postage is paid by the customer. [1]
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

The return-window question in the last section got thirty days from `[1]` and fourteen days from
`[2]`, in one reply. **A generator handed two contradicting sources may quote both, choose one at
random, or average them into something neither says.** extract-1 quotes both because its rule copies
the most similar sentences, whatever they say. Lesson 7 shows how a prompt tells a generator which
source wins, and why the dates have to be in the prompt for that to work.

## The answer was there, and the reply missed it

The express question retrieved the section with the price in it and replied with a sentence about
express never being free. **Retrieval succeeded and generation failed.** With a real model the
mechanism differs, and so do the odds, but the category is the same: the context held the answer and
the reply did not use it. It is the failure people most often blame on the search, and a test that
only checks the final answer cannot tell the two apart. Lesson 8 measures retrieval and generation
separately for exactly this reason.

## No answer at all

```
ana@lab:~/rag$ python tiny_rag.py "Can I place an order by phone?"
[1] 0.453  shipping-and-delivery > Addresses
[2] 0.453  terms-of-sale > 2. Placing an order
[3] 0.358  shipping-and-delivery > Pickup points
The sources do not say.
```

Marginalia's documents never mention ordering by phone, so this is the right reply. But notice that
**the search still returned three sections**: a search always returns its top three, whether or not
any of them is any good, and here the best scored 0.453. The refusal came from extract-1's own
threshold, not from the retrieval. A real model given those three sections might well have written
something about orders anyway. Lesson 6 gives the search its own way to say it found nothing good,
and lesson 7 makes "the sources do not say" an instruction instead of an accident.

## And what it cannot reach

Some questions have no passage that answers them, because the answer is not written anywhere and has
to be computed. *How many of our documents mention a fourteen-day limit?* *Which policy changed most
this year?* *What do all our returns rules have in common?* A retrieval system finds a few passages;
it does not read the whole corpus. Questions about everything, or about counts and totals, belong to
a database query or a batch job, and lesson 2 draws that boundary with examples.

RAG also does not make a model reason better. Given the right passages, a model that misreads a
table misreads it in the prompt as it would anywhere. What retrieval guarantees is narrower and still
worth having: **the model reads the text it needs, and the reader can see which text that was.**
