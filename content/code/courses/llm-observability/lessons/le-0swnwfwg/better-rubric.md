---
title: A rubric with its answers written in
version: 1
---

The disagreements in version 1 were not mistakes to correct; they were questions the rubric had not
answered. Ana and Bruno went through them together and wrote the answers into version 2:

```
ana@lab:~/obs$ cat data/rubrics/relevance-v2.md
# Relevance, version 2

Read the customer's question and the assistant's reply. Relevance asks only
whether the reply is about what was asked. Whether it is true is faithfulness,
and whether it is the right answer is correctness: grade neither here.

- pass: the reply gives what the question asks for, even among other
  sentences.
  e.g. "Above what order value is standard delivery free?" answered with a
  sentence on express delivery and then "standard ... free on orders over 40".
- pass: the reply is the agreed refusal, "I could not find that in our
  documents." It answers the question by saying there is no answer here.
  Whether it should have refused is correctness.
- fail: the reply is about the question's subject and does not give what was
  asked for.
  e.g. "How much is express delivery?" answered with "Express delivery is not
  free at any order value."
- fail: the reply answers a different question, even one that shares the
  question's words.
  e.g. "Above what order value is standard delivery free?" answered with
  "Express delivery is not free at any order value."

When the reply gives a condition from which the answer follows, and the customer
would have to work it out, write that down beside the label: it is the case this
version does not settle.
```

Three things changed, and each is a technique worth reusing.

- **The criterion says what it is not.** Faithfulness and correctness are named and set aside, so a
  rater who notices a wrong answer does not fail it for relevance. That is the refusal decided: a
  refusal is about the question, and whether it should have been a refusal is correctness, which
  lesson 8 measured against the facts.
- **Every rule has an example.** An **anchor** is a real reply with its verdict, and it settles in one
  line what a paragraph of definition would leave open. The anchors here are the very replies people
  disagreed on.
- **The rubric says what it does not settle.** The last paragraph names the case the team could not
  agree a rule for, and asks the rater to flag it rather than guess.

The same sixty replies, labelled again against version 2:

```
ana@lab:~/obs$ python agree.py relevance-v2/ana relevance-v2/bruno
60 replies; rows relevance-v2/ana, columns relevance-v2/bruno
          pass  fail
  pass      51     2
  fail       0     7
agreement 96.7%   by chance 76.8%   kappa 0.86
apart on 2: 0 refusals, 2 other replies
  e05 2026.09.4  pass / fail  An e-book can be refunded within 14 days of purchase if yo
  e05 2026.10.1  pass / fail  An e-book can be refunded within 14 days of purchase if yo
```

**Kappa 0.86, and two disagreements left**, both the same reply: e05, the e-book downloaded yesterday,
under each release. It is the case the last paragraph of the rubric describes. Ana passed it, because
the answer follows from what the reply says; Bruno failed it, because a customer should not have to
deduce it. They talked it through and agreed to pass it, and that verdict is the third set of labels,
`relevance-v2/agreed`. Settling the cases that remain by discussion, and recording the result as its
own set, is called **adjudication**.

## What a reference needs

The agreed labels can now be used to measure a judge, because they rest on a rubric two people read
the same way. Three properties made that possible, and they are the checklist for any set of reference
labels:

1. **Each label names the reply by a stable id** and the rubric by its version.
2. **The agreement between people was measured**, and is high enough that the labels mean something.
3. **The disagreements that remain were settled and recorded** as a set of their own, so that the
   individual labels stay what each person said.

Two raters on sixty replies is the smallest version of this that still measures something. A team that
labels regularly gives a new person a few dozen replies already agreed, checks their kappa against the
reference before trusting their labels, and repeats a small overlap between raters every round, because
people drift as the rubric gets familiar.
