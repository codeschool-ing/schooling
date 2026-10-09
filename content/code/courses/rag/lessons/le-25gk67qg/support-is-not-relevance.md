---
title: A supported sentence can still be the wrong answer
version: 2
---

The citation check answers one question: is this sentence in the source it cites? It does not answer
the question the customer asked. The two come apart in both directions, and this lesson has already
seen one of them: in the refund reply, the one sentence the checker passed as quoted is true, cited
to the right source, and not the answer. The refund takes three working days, and no sentence of the
reply says so.

The other direction is the signed-copy question:

```
ana@vm:~/rag$ python answer.py "Can I return a signed copy?"
According to source [2], personalised copies and copies signed by the author cannot be returned, unless they arrive damaged or faulty.
  [2] Returns and refunds policy > Items that cannot be returned, updated 2026-02-02
ana@vm:~/rag$ python -c "from answer import sources_for; [print(round(s[\"score\"], 3), s[\"path\"]) for s in sources_for(\"Can I return a signed copy?\")]"
0.522 Returns and refunds policy > Damaged, faulty and wrong items
0.517 Returns and refunds policy > Items that cannot be returned
0.515 Returns and refunds policy > Damaged, faulty and wrong items
ana@vm:~/rag$ python check_reply.py "Can I return a signed copy?"
According to [2], personalised copies and copies signed by the author cannot be returned, unless they arrive damaged or faulty.
  unsupported (0.56) [2] Personalised copies and copies signed by the author cannot b
```

**The reply is right, and the checker calls it unsupported.** The source that answers it,
*Items that cannot be returned*, came second at 0.517, and the model found the answer in it. The
policy writes it as a list, *the following cannot be returned unless they arrive damaged or faulty:*
and then *personalised copies and copies signed by the author;* as an item. The model turned the list
into one sentence. The checker splits its source at full stops, so the whole list is a single long
passage, and a sentence made out of two of its pieces scores
0.56 against it.

(The two runs here also worded the reply differently: *According to source [2]* the first time,
*According to [2]* the second. Same program, same question, temperature 0. The first request after
the model loads is the one that tends to differ.)

**Every component did its job by its own measure, and the verdicts are still wrong both ways.** The
search returned the right chunk in the top three. The model answered the signed-copy question
correctly and the refund question wrongly. The checker passed the wrong answer and failed the right
one. Nothing in the pipeline so far can tell which reply answers the question.

## Three properties, three checks

It helps to keep three questions apart, because each needs a different test:

| question | property | checked by |
| --- | --- | --- |
| did the search find the passage that answers? | retrieval | the answer's text in the retrieved chunks, as lesson 4 measured |
| does each sentence come from its source? | faithfulness | `verify.py`, this lesson |
| does the reply answer the question? | correctness | comparing the reply with a known answer, lesson 8 |

The refund reply passes the first and the second for the sentence it quoted, and fails the third.
The signed-copy reply passes the first and the third and fails the second, which here is the
checker's mistake rather than the model's. And lesson 1's return-window run put the replaced 2025
policy second among its sources, a failure of the first kind, which the status filter now keeps out.
**A pipeline measured on one property can look healthy while failing the other
two**, which is why lesson 8 measures all three on every question.

## What the checker cannot see

A checker that compares sentences sees words, not meaning. It cannot tell that a list item and a
sentence say the same thing, and it cannot tell that a true quote leaves out the fact that was asked
for. A model's version of the second failure is the dangerous one, because nothing flags it: it
answers a slightly different question from the one asked, or the general case when the customer
described an exception, and cites a source that does support what it said. Only a test with known
answers catches those, and only on the questions somebody thought to write down.
