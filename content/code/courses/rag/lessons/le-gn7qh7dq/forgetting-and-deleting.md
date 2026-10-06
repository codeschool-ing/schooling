---
title: Forgetting and deleting
version: 1
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
ana@lab:~/rag$ python sections.py "How much does the return label cost?"
[1] 0.547  returns-policy-2025 > Return postage
[2] 0.446  returns-policy > How to start a return
[3] 0.407  warehouse-runbook > The label printer has stopped
You do not pay for the label, whatever the reason for the return. [2] You can use our returns label, which costs 4.50 and is deducted from your refund, or send the parcel by any tracked service at your own cost. [1]
ana@lab:~/rag$ WITHOUT=returns-policy-2025 python sections.py "How much does the return label cost?"
[1] 0.446  returns-policy > How to start a return
[2] 0.407  warehouse-runbook > The label printer has stopped
[3] 0.367  seller-agreement > 2. Fees
You do not pay for the label, whatever the reason for the return. [1]
```

**With the 2025 policy in the index, the reply contradicts itself**: free from `[2]`, 4.50 from `[1]`.
Without it, the reply is the current rule and nothing else. The change took effect on the next
question and needed no model to change. In a database it is a `DELETE` of the document's rows, which
lesson 5 sets up so that one statement removes every chunk of a document and nothing else.

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
