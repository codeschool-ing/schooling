---
title: A rubric with its answers written in
version: 2
---

The disagreements in version 1 were not mistakes to correct; they were a question the rubric had not
answered. Ana and Bruno went through them together and wrote the answer into version 2:

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

- **The criterion says what it is not.** Faithfulness is named and set aside, so a rater who notices a
  wrong answer does not fail it for relevance. e02 under the new release is the anchor for exactly
  that.
- **The refusal is decided, and decided both ways.** A refusal to a question the documents cannot
  answer gives the customer the truth, and passes. A refusal to a question they do answer leaves the
  customer with nothing, and fails.
- **Every rule has an example.** An **anchor** is a real reply with its verdict, and it settles in one
  line what a paragraph of definition would leave open. The anchors here are replies from the runs.

The same forty-eight replies, labelled again against version 2:

```
ana@dev:~/obs$ python agree.py relevance-v2/ana relevance-v2/bruno
48 replies; rows relevance-v2/ana, columns relevance-v2/bruno
          pass  fail
  pass      41     3
  fail       0     4
agreement 93.8%   by chance 79.5%   kappa 0.69
apart on 3: 3 refusals, 0 other replies
  e12 2026.09.4  pass / fail  I could not find that in our documents.
  e12 2026.10.1  pass / fail  I could not find that in our documents.
  e19 2026.10.1  pass / fail  I could not find that in our documents.
```

**Kappa 0.69, and three disagreements left**, all of them refusals Ana passed and Bruno failed: the
Kindle question under both releases, and the right of withdrawal under the new one. Version 2 asks a
rater to know whether the shop's documents answer a question, and Ana, a developer, did not know that
the e-book formats page says they will not open on a Kindle, or that the returns policy states the
statutory seven days. Bruno, from support, did. They looked it up together and failed all three, and
that verdict is the third set of labels, `relevance-v2/agreed`. Settling the cases that remain by
discussion, and recording the result as its own set, is called **adjudication**.

The lesson for the next round is in what the rubric asks of a rater, more than in its words. A
criterion that needs the documents needs the documents beside the rater, or the answer key's facts,
and that is where the next section's rule comes from.

## What a reference needs

The agreed labels can now be used to measure a judge, because they rest on a rubric two people read
the same way. Three properties made that possible, and they are the checklist for any set of reference
labels:

1. **Each label names the reply by a stable id** and the rubric by its version.
2. **The agreement between people was measured**, and is high enough that the labels mean something.
3. **The disagreements that remain were settled and recorded** as a set of their own, so that the
   individual labels stay what each person said.

Two raters on forty-eight replies is the smallest version of this that still measures something. A
team that labels regularly gives a new person a few dozen replies already agreed, and checks their
kappa against the reference before trusting their labels. It also repeats a small overlap between
raters every round, because people drift as the rubric gets familiar.