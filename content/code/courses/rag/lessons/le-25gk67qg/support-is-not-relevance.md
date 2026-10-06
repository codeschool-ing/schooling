---
title: A supported sentence can still be the wrong answer
version: 1
---

The citation check answers one question: is this sentence in the source it cites? It does not answer
the question the customer asked. Those come apart more often than people expect, and the signed-copy
question shows it in one run.

```
ana@lab:~/rag$ python answer.py "Can I return a signed copy?"
We replace damaged books at no cost and you do not need to send the damaged copy back. [1]
  [1] Returns and refunds policy > Damaged, faulty and wrong items, updated 2026-02-02
ana@lab:~/rag$ python -c "from answer import sources_for; [print(round(s[\"score\"], 3), s[\"path\"]) for s in sources_for(\"Can I return a signed copy?\")]"
0.522 Returns and refunds policy > Damaged, faulty and wrong items
0.517 Returns and refunds policy > Items that cannot be returned
0.515 Returns and refunds policy > Damaged, faulty and wrong items
ana@lab:~/rag$ python check_reply.py "Can I return a signed copy?"
We replace damaged books at no cost and you do not need to send the damaged copy back. [1]
  quoted             [1] We replace damaged books at no cost and you do not need to s
```

**The reply is about damaged books, the check says it is quoted, and the customer still does not know
whether a signed copy can be returned.** The source that answers it was retrieved: *Items that cannot
be returned*, second at 0.517, with *copies signed by the author* in its list. extract-1 picked a
sentence from the first source instead, because to MiniLM *send the damaged copy back* is closer to
*return a signed copy* than a list item ending in a semicolon is.

Every component did its job by its own measure. The search returned the right chunk in the top three.
The generator quoted faithfully. The checker confirmed the quote. **The answer is still wrong**, and
nothing in the pipeline so far can see it.

## Three properties, three checks

It helps to keep three questions apart, because each needs a different test:

| question | property | checked by |
| --- | --- | --- |
| did the search find the passage that answers? | retrieval | the answer's text in the retrieved chunks, as lesson 4 measured |
| does each sentence come from its source? | faithfulness | `verify.py`, this lesson |
| does the reply answer the question? | correctness | comparing the reply with a known answer, lesson 8 |

The signed-copy run passes the first two and fails the third. Lesson 1's express-delivery run failed
the third with the right section retrieved, and the 2025 policy runs failed the first by retrieving
the wrong document. **A pipeline measured on one property can look healthy while failing the other
two**, which is why lesson 8 measures all three on every question.

## Why real models fail this differently

A real model reads the whole source list as language and would be very likely to answer this one
correctly: the list item says signed copies cannot be returned, and models are good at reading lists.
Its version of this failure is subtler. It answers a slightly different question from the one asked,
or answers the general case when the customer described an exception, and cites a source that does
support what it said. The check above passes those too. Only a test with known answers catches them,
and only on the questions somebody thought to write down.
