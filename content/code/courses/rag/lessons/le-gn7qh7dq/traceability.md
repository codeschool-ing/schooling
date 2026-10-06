---
title: Traceability
version: 1
---

A support lead reads a reply the assistant sent a customer yesterday and needs to know one thing:
*why did it say that?* With retrieval, the answer is in the reply. With fine-tuning, there is no
answer, and that difference matters more in practice than freshness or price.

## A citation is a pointer you can follow

```
ana@lab:~/rag$ python sections.py "How long do I have to return a printed book?"
[1] 0.807  returns-policy-2025 > Returning a book
[2] 0.798  returns-policy > The return window
[3] 0.765  returns-policy > Damaged, faulty and wrong items
You may return a printed book within 14 days of delivery if it is unread and in the condition in which you received it. [1] You have 30 days from delivery to return a printed book in the condition you received it. [2] A printed book with a fault from the printer, such as pages bound upside down or missing, can be returned for a refund or a replacement within 30 days, like any other return. [3]
ana@lab:~/rag$ grep -n "30 days from delivery" data/docs/returns-policy.md
21:You have 30 days from delivery to return a printed book in the condition you received it. The 30
```

This phrasing of the question put the 2025 policy first, at 0.807, against 0.798 for the current one,
and the reply leads with fourteen days. It is the same failure lesson 1 found. What is different here
is how quickly it can be diagnosed: **the reply says `[1]`, the score line says `[1]` is
`returns-policy-2025`, and the fix is visible in the same screen** — that document should not have
been searchable for a customer's question. Following `[2]` to line 21 of the current policy confirms
the right sentence exists and where.

Three things become possible because of that pointer:

- **A person can check an answer** without trusting the model, by opening the source.
- **An engineer can tell retrieval failures from generation failures**, because the citation says
  which text the generator was shown. Lesson 8 depends on this.
- **The organisation can prove what it told a customer and why**, which in a dispute, or a regulator's
  question, is the difference between an explanation and a shrug.

## A fine-tuned model has no pointer

A fine-tuned model answering "fourteen days" gives no way to find out why. The fact came from a
training example, the training example came from a dataset, and the dataset may have come from a
pipeline like `dataset.py`, which was shown in this lesson putting the 2025 rule into its second line.
None of that is visible in the reply. The weights do not record which example taught them what, and
asking the model where it learnt something produces a plausible answer, not a true one.

**A fine-tuned model can be told to cite, and it will produce citations**, in exactly the format its
examples used. They are text it learnt to write, with no guarantee that the cited document says what
the reply says. A citation is only worth following if the system put the cited text in front of the
model at the moment it answered, and only retrieval does that.

## When traceability is a requirement

For the legal and internal uses of lesson 2 it is not a nice property but the product. A compliance
team asked which policy an answer relied on must be able to say. A customer disputing a refund
decision is entitled to the clause. An auditor reviewing how an assistant handled personal data needs
to see what it read. In each case a system that cannot point at its sources is a system that cannot
be used, however good its answers are on average.
