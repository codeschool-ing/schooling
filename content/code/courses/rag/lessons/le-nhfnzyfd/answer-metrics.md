---
title: Measuring the answers
version: 2
---

The second and third properties are about the reply. `evaluate.py --list` prints a line per question:
where the answer ranked, whether the reply was a refusal, whether it was correct, and whether every
sentence passed lesson 7's check.

```
ana@vm:~/rag$ python evaluate.py --split dev --list
dev: 20 questions, 18 answerable, floor 0.5, k 3
retrieval  recall@1 13/18  recall@3 18/18  recall@5 18/18  MRR 0.86
answers    correct 15/20  refused rightly 2/2  faithful 9/20
e01  rank 1  answered  correct  UNFAITHFUL  How many days do I have to return a printed book?
e02  rank 2  answered  WRONG    UNFAITHFUL  Who pays for the return postage?
e04  rank 2  answered  correct  UNFAITHFUL  Can I return a signed copy?
e05  rank 1  answered  WRONG    UNFAITHFUL  My e-book was downloaded yesterday, can I still get my money back?
e07  rank 2  answered  correct  UNFAITHFUL  Above what order value is standard delivery free?
e08  rank 1  answered  correct  faithful  When is a standard parcel considered lost?
e10  rank 1  answered  WRONG    faithful  How long does a pickup point keep my parcel?
e11  rank 1  answered  correct  faithful  On how many devices can I read my e-books?
e13  rank 1  answered  correct  UNFAITHFUL  When can an audiobook be refunded?
e14  rank 2  refused   WRONG    faithful  Can I pay in instalments?
e16  rank 1  refused   WRONG    faithful  Can I get an invoice in my company's name after the order has shipped?
e17  rank 1  answered  correct  UNFAITHFUL  When is the contract of sale formed?
e19  rank 1  answered  correct  UNFAITHFUL  What commission does Marginalia take from a marketplace seller?
e20  rank 1  answered  correct  UNFAITHFUL  How often are sellers paid?
e22  rank 1  answered  correct  faithful  What commission do affiliates earn on e-books?
e23  rank 1  answered  correct  UNFAITHFUL  How long do you keep my order history?
e25  rank 2  answered  correct  UNFAITHFUL  What is the most a support agent can refund without approval?
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

**Faithful: 9 of 20.** A reply is faithful when every sentence is quoted from, or close to, the source
it cites, by lesson 7's check. Eleven were not, and the listing shows that faithful and correct are
independent: e01 is correct and unfaithful, e10 faithful and wrong. Lesson 7 found why most of the
eleven fail, sentences the model added of its own and citations written where the check does not look
for them, and found the check failing a right reply too. The number is worth tracking for its
movement, and worth reading line by line before acting on it.

## Reading the five wrong ones

Every wrong line has its rank beside it. `why.py` prints the sources and the reply for one question,
with the same filter as the evaluation, and three are worth reading in full:

```schooling-example
{
  "language": "python",
  "file": "why.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import answer\n\nreply, sources = answer(sys.argv[1], where=\"status = %s\", params=(\"current\",))\nfor n, s in enumerate(sources, 1):\n    print(f\"[{n}] {s['path']}\")\nprint(reply)",
      "note": "The sources `answer` gave the model for one question, numbered as the model saw them, and its reply, with the same filter `evaluate.py` uses."
    }
  ]
}
```

```
ana@vm:~/rag$ python why.py "Who pays for the return postage?"
[1] Returns and refunds policy > How to start a return
[2] Returns and refunds policy > How to start a return
[3] Returns and refunds policy > Gifts
According to sources [1] and [2], the return postage is prepaid by the company, so the customer does not pay for the label.
ana@vm:~/rag$ python why.py "My e-book was downloaded yesterday, can I still get my money back?"
[1] E-books and audiobooks > Refunds for e-books
[2] Returns and refunds policy > E-books and audiobooks
[3] E-books and audiobooks > Refunds for e-books
According to sources [1] and [2], an e-book can be refunded within 14 days of purchase if you have not downloaded it or opened it in the app. Since your e-book was downloaded yesterday, it falls outside of this 14-day window, and the sale is final, as the law allows for digital content delivered with your consent.

However, source [3] states that an e-book that is faulty, for example with missing chapters or text that cannot be displayed, is refunded or replaced at any time, downloaded or not. This implies that even if the e-book has been downloaded, a refund may still be possible if it is faulty.

Given that source [3] is updated more recently than sources [1] and [2], I would prefer this source. Therefore, it appears that even if your e-book was downloaded yesterday, you may still be able to get a refund if it is faulty.
ana@vm:~/rag$ python why.py "What is the most a support agent can refund without approval?"
[1] Refund controls and chargebacks > Finance reviews
[2] Customer support handbook > What you can decide on your own
According to [2], a support agent can refund up to 50 without approval.
```

Together with the listing, they say where each failure happened:

| question | rank | what happened |
| --- | --- | --- |
| e02, who pays for return postage | 2 | the reply says the label is prepaid and the customer does not pay, which is right; the fact is *Returns are free*, and the reply does not contain those words |
| e05, a downloaded e-book | 1 | the reply quoted the rule and then reasoned its way out of it: downloaded yesterday, so *outside of this 14-day window*, and then preferred the faulty-copy rule as *updated more recently*, which it is not |
| e10, how long a pickup point keeps a parcel | 1 | *10 days*, right; the fact is *waits there for ten days* |
| e14, paying in instalments | 2 | refused: the best chunk scored under the floor of 0.5 |
| e16, an invoice after shipping | 1 | the model refused, with the answer in its first source: *we cannot reissue an invoice to a different company after the order has shipped* |

**None of the five is a retrieval failure**: every answer was in the top two. Two are generation
failures, the reply not using a source it had: e05, which used it and reasoned wrongly, and e16, which
had the answer and said it could not find one. One is the floor refusing a question it could have
answered, the price lesson 6 named in advance. And two, **e02 and e10, are failures of the test, not of
the pipeline**: the replies are right in substance and the fact test marked them wrong, because it looks
for words, not meaning. A test that is wrong two times in twenty is still a useful test, as long as
somebody reads the wrong lines before acting on the total.

That diagnosis is the whole value of measuring the three properties apart. A team looking only at *15
of 20 correct* would have tuned the search, which was not broken. Two more things are visible only in
the reading. The third `why.py` run, e25, answered right, and its first source is the finance team's
document: this evaluation runs without the audience filter, so a staff question reached the finance
document, the leak lesson 2 described and lesson 14 closes. And e02 and e10 say their facts should
have been written better, several phrasings or only the number, which is a fix to the test set, not to
the code.

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
