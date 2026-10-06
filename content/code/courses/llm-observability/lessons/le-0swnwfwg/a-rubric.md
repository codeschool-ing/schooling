---
title: A rubric, and two people reading it
version: 1
---

A **rubric** is what a grader is told: the criterion, the possible verdicts, and what decides between
them. The judge gets one in its system prompt, in `judge.py`. People need one for the same reason, and
the first version the team wrote for relevance is the judge's sentence, set out for a person:

```
ana@lab:~/obs$ cat data/rubrics/relevance-v1.md
# Relevance, version 1

Read the customer's question and the assistant's reply.

Does the reply address the question the customer asked?

- pass: it does
- fail: it does not
```

Two choices in it are deliberate, and both are the usual advice for a first rubric.

**Pass or fail, not a score from 1 to 5.** A scale asks the rater to place a reply on a line, and two
people place the same reply a point apart without disagreeing about anything: one gives 4 to everything
good and the other keeps 5 for the exceptional. Each step of a scale needs its own description to mean
the same thing to everybody, and a team writing its first rubric does not know yet what the steps are.
A binary verdict asks one question, and a disagreement on it is a real disagreement.

**One criterion.** Relevance only, not relevance and faithfulness and tone in one verdict. A person
grading three things at once grades whichever they noticed first, and a fail cannot say which of the
three failed.

## The labels

Ana and Bruno each read the sixty replies, with their questions and sources, and wrote a verdict for
each against version 1. Every label is a line of `data/labels.jsonl`, naming the reply by the question's
id and the release that answered:

```
ana@lab:~/obs$ head -3 data/labels.jsonl
{"case": "e01", "release": "2026.09.4", "rubric": "relevance-v1", "rater": "ana", "label": "pass"}
{"case": "e02", "release": "2026.09.4", "rubric": "relevance-v1", "rater": "ana", "label": "pass"}
{"case": "e03", "release": "2026.09.4", "rubric": "relevance-v1", "rater": "ana", "label": "pass"}
ana@lab:~/obs$ wc -l data/labels.jsonl
300 data/labels.jsonl
```

Three hundred lines: sixty replies, labelled by two people against version 1, by the same two against
version 2, and once more as the verdict they agreed after talking, which the next sections come to.

The replies are the evaluation set's, run again by `evalrun.py` from lesson 8, once as each release:

```
ana@lab:~/obs$ python evalrun.py old --release 2026.09.4
runs/old.jsonl: 30 questions, release 2026.09.4
ana@lab:~/obs$ python evalrun.py new --release 2026.10.1
runs/new.jsonl: 30 questions, release 2026.10.1
```

The rubric's version is in every label, and that matters as much as the reply's id. A label written
against version 1 says what somebody thought version 1 meant; mixing it with labels written against a
version with different instructions measures nothing.
