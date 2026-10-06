---
title: Measuring the answers
version: 1
---

The second and third properties are about the reply. `evaluate.py --list` prints a line per question:
where the answer ranked, whether the reply was a refusal, whether it was correct, and whether every
sentence passed lesson 7's check.

```
ana@lab:~/rag$ python evaluate.py --split dev --list
dev: 20 questions, 18 answerable, floor 0.5, k 3
retrieval  recall@1 13/18  recall@3 18/18  recall@5 18/18  MRR 0.86
answers    correct 15/20  refused rightly 2/2  faithful 20/20
e01  rank 1  answered  correct  faithful  How many days do I have to return a printed book?
e02  rank 2  answered  WRONG    faithful  Who pays for the return postage?
e04  rank 2  answered  WRONG    faithful  Can I return a signed copy?
e05  rank 1  answered  WRONG    faithful  My e-book was downloaded yesterday, can I still get my money back?
e07  rank 2  answered  correct  faithful  Above what order value is standard delivery free?
e08  rank 1  answered  correct  faithful  When is a standard parcel considered lost?
e10  rank 1  answered  correct  faithful  How long does a pickup point keep my parcel?
e11  rank 1  answered  correct  faithful  On how many devices can I read my e-books?
e13  rank 1  answered  correct  faithful  When can an audiobook be refunded?
e14  rank 2  refused   WRONG    faithful  Can I pay in instalments?
e16  rank 1  answered  correct  faithful  Can I get an invoice in my company's name after the order has shipped?
e17  rank 1  answered  correct  faithful  When is the contract of sale formed?
e19  rank 1  answered  correct  faithful  What commission does Marginalia take from a marketplace seller?
e20  rank 1  answered  correct  faithful  How often are sellers paid?
e22  rank 1  answered  correct  faithful  What commission do affiliates earn on e-books?
e23  rank 1  answered  correct  faithful  How long do you keep my order history?
e25  rank 2  answered  WRONG    faithful  What is the most a support agent can refund without approval?
e26  rank 1  answered  correct  faithful  What must I check before changing a customer's order?
e28  rank -  refused   correct  faithful  Can I place an order by phone?
e29  rank -  refused   correct  faithful  Which carrier do you use in Portugal?
```

## Three numbers

**Correct: 15 of 20.** An answerable question is correct when the reply contains its fact; an
unanswerable one is correct when it is refused. This is the number a customer would care about if
they could see it.

**Refused rightly: 2 of 2.** Both questions with no answer in the documents were refused, by the
floor from lesson 7, before the model was called.

**Faithful: 20 of 20.** Every reply that was not a refusal had every sentence quoted from or close to
the source it cited. For extract-1 that is guaranteed by construction, and the number is here so that
the same script, run against a real model, has somewhere to report that it is not.

## Reading the five wrong ones

Every wrong line has its rank beside it. `why.py` prints the sources and the reply for one question,
with the same filter as the evaluation, and three of the five are worth reading in full:

```
ana@lab:~/rag$ python why.py "Who pays for the return postage?"
[1] Returns and refunds policy > How to start a return
[2] Returns and refunds policy > How to start a return
[3] Returns and refunds policy > Gifts
Keep the receipt the post office gives you until the refund arrives: it is the only proof that the parcel was sent. [2]
ana@lab:~/rag$ python why.py "My e-book was downloaded yesterday, can I still get my money back?"
[1] E-books and audiobooks > Refunds for e-books
[2] Returns and refunds policy > E-books and audiobooks
[3] E-books and audiobooks > Refunds for e-books
An e-book can be refunded within 14 days of purchase if you have not downloaded it or opened it in the app. [1] An e-book can be refunded within 14 days of purchase if you have not downloaded it or opened it in the app. [2] An e-book that is faulty, for example with missing chapters or text that cannot be displayed, is refunded or replaced at any time, downloaded or not. [3]
ana@lab:~/rag$ python why.py "What is the most a support agent can refund without approval?"
[1] Refund controls and chargebacks > Finance reviews
[2] Customer support handbook > What you can decide on your own
Support opens a finance review when a refund or credit is above the agent's or lead's limit, or when fraud is suspected. [1] A refund of more than 500 on one order always needs a second approver from finance, whoever requested it. [1]
```

Together with the listing, they say where each failure happened:

| question | rank | what happened |
| --- | --- | --- |
| e02, who pays for return postage | 2 | *Returns are free* was in the second source, and extract-1 quoted another sentence of it, about keeping the post office receipt |
| e04, a signed copy | 2 | lesson 7's case: the list item was retrieved and a damaged-books sentence was quoted |
| e05, a downloaded e-book | 1 | the reply quoted the rule, *refunded within 14 days if you have not downloaded it*, which answers the question; the fact was *Once it has been downloaded*, and the reply does not contain it |
| e14, paying in instalments | 2 | refused: the best chunk scored under the floor of 0.5 |
| e25, an agent's refund limit | 2 | the finance team's document came first, and the reply quoted its rule about refunds over 500; the handbook's *up to 50* was second |

**None of the five is a retrieval failure**: every answer was in the top two. Three are generation
failures, the reply not using a source it had: e02, e04 and e25. One is the floor refusing a question
it could have answered, the price lesson 6 named in advance. And one, **e05, is a failure of the test,
not of the pipeline**: the reply is right in substance and the fact test marked it wrong, because it
looks for words, not meaning. A test that is wrong one time in twenty is still a useful test, as long
as somebody reads the wrong lines before acting on the total.

That diagnosis is the whole value of measuring the three properties apart. A team looking only at *15
of 20 correct* would have tuned the search, which was not broken. Two more things are visible only in
the listing: e25 shows this evaluation runs without the audience filter, so a staff question reached
the finance document, the leak lesson 2 described and lesson 14 closes; and e05 says the fact for that
question should have been written better, which is a fix to the test set, not to the code.

## Correctness for a real model

The fact test fails a real model's correct paraphrase, as the test-set section said. The usual
replacements, from cheapest to most expensive:

- **Several facts, any of which counts**, written by hand: *30 days*, *thirty days*, *a month*.
- **Numbers and identifiers only**: for many questions the fact that matters is *9.90* or *12%*, and
  those survive paraphrase.
- **A model as judge**, which the next section is about, and which costs a model call per question.
- **A person**, for a sample, to check the judge.

Whichever is used, it has to be the same across the runs being compared. A change of judge between
two runs makes the comparison meaningless, however careful each run was.
