---
title: Forgetting and deleting
version: 2
---

Sooner or later a system has to stop knowing something. A policy is withdrawn. A document turns out
to contain a customer's personal data and has to go: the privacy notice in this corpus, written under
Brazil's data protection law, the LGPD, promises that a person may ask for their data to be deleted. A contract clause
was wrong and must never be quoted again. The two approaches differ most sharply here, because one of
them can delete and the other can only be retrained.

## Deleting from an index

In a retrieval system a document's knowledge is its chunks, and its chunks are rows. Removing the
document removes the rows, and the next question cannot find what is not there. `sections.py` reads
an environment variable naming documents to leave out, which is the same thing done in memory:

```
ana@vm:~/rag$ python sections.py "How much does the return label cost?"
[1] 0.546  returns-policy-2025 > Return postage
[2] 0.446  returns-policy > How to start a return
[3] 0.407  warehouse-runbook > The label printer has stopped
According to [1], the return postage label costs 4.50 and is deducted from the refund.
ana@vm:~/rag$ WITHOUT=returns-policy-2025 python sections.py "How much does the return label cost?"
[1] 0.446  returns-policy > How to start a return
[2] 0.407  warehouse-runbook > The label printer has stopped
[3] 0.367  seller-agreement > 2. Fees
Unfortunately, the provided sources do not mention the cost of the return label. However, based on general knowledge, it is common for return labels to be free for the customer, as stated in source [1].

If you're looking for a specific answer, I couldn't find it in the provided sources. However, I can suggest that you contact the company's customer support or check their website for more information on return labels and their costs.
```

**With the 2025 policy in the index, the reply is the 2025 price**, 4.50 deducted from the refund,
cited to `[1]`, for a label that has been free since February. Without it, 4.50 is gone: nothing left
in the index says it, so nothing can be quoted. The change took effect on the next question and
needed no model to change. In a database it is a `DELETE` of the document's rows, which lesson 5 sets
up so that one statement removes every chunk of a document and nothing else.

The second reply is not good, and that is worth noticing too. The current policy's *How to start a
return* says the label costs nothing, and the model first says the sources do not mention the cost,
then that labels are commonly free "for the customer", citing `[1]` for it, and closes by suggesting
the customer ask the company. Deleting the wrong document removed the
wrong answer; it did not make the model read the right one well. That is generation's half of the
job, and lesson 7's.

That deletion is also **verifiable**: after it, a query for the deleted text returns nothing, and a
test can assert so. Lesson 14 writes that test for documents a user must not see, and the same test
proves a deletion.

## Deleting from a model

A fine-tuned model that learnt the 2025 rule from its training data cannot be made to forget it by
removing that example. The example changed the weights during training, and the change is spread
across millions of numbers with no record of which example caused which part of it. The options are:

- **retrain from the base model** with a dataset that no longer contains the example, which costs a
  full training run and an evaluation;
- **train on top** with examples that teach the opposite, which makes the model less likely to repeat
  the old fact and gives no guarantee that it never will;
- **filter the output**, refusing replies that contain the forbidden text, which catches the exact
  wording and nothing else.

Research on *machine unlearning* looks for better ways, and as of this course none of them is
something a team would use to meet a legal deletion request with confidence.

## Why this decides the design for personal data

The privacy notice in this corpus says support conversations are used to improve the help centre
search only after names, email addresses, order numbers and addresses are removed. That sentence is
a promise, and a retrieval system can keep it: if a chunk with a name in it is found, it is deleted
and it is gone. A model fine-tuned on raw support conversations has those names somewhere in its
weights, and **no deletion request can reach them**.

The rule that follows is simple: personal data and anything that may have to be withdrawn belong in
the index, where they can be removed, and never in training data. Lesson 13 applies the same rule to
what an assistant remembers about a customer.
