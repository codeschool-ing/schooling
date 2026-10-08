---
title: A rubric with its answers written in
version: 1
---

The disagreements in version 1 were not mistakes to correct; they were questions the rubric had not
answered. Ana and Bruno went through them together and wrote the answers into version 2:

```sh
cat > data/rubrics/relevance-v2.md <<'EOF'
# Relevance, version 2

Read the customer's question, the assistant's reply and the sources it was
given. Relevance asks whether the reply gives the customer what they asked
for. Whether what it says is true is faithfulness: grade that apart.

- pass: the reply gives what the question asks for, even among other
  sentences, and even if it is wrong.
  e.g. "Who pays for the return postage?" answered with "the customer pays
  for the return postage" passes here, and fails faithfulness.
- pass: the reply is the agreed refusal, "I could not find that in our
  documents.", and the shop's documents do not answer the question.
  e.g. "Can I place an order by phone?"
- fail: the reply is the agreed refusal, and the shop's documents do answer
  the question. The customer asked something the shop has written down and
  was told it had not.
  e.g. "Can I pay in instalments?" answered with the refusal.
- fail: the reply answers a different question, even one that shares the
  question's words.
EOF
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

CAPTURE:v2

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

Two raters on sixty replies is the smallest version of this that still measures something. A team that labels regularly gives a new person a few dozen replies already agreed, and checks their kappa against the reference before trusting their labels. It also repeats a small overlap between raters every round, because
people drift as the rubric gets familiar.
