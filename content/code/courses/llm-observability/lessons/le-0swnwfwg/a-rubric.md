---
title: A rubric, and two people reading it
version: 2
---

A **rubric** is what a grader is told: the criterion, the possible verdicts, and what decides
between them. The judge gets one in its system prompt, in `judge.py`. People need one for the same
reason, and the first version the team wrote for relevance is the judge's sentence, set out for a
person. Save it, and the version after it, in `data/rubrics`:

```sh
mkdir -p data/rubrics
cat > data/rubrics/relevance-v1.md <<'EOF'
# Relevance, version 1

Read the customer's question and the assistant's reply.

Does the reply address the question the customer asked?

- pass: it does
- fail: it does not
EOF
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

Ana and Bruno each read the forty-eight replies, with their questions and sources, and wrote a verdict
for each against version 1, and later against version 2. Each line of `data/labels.jsonl` names one
reply by the question's id and the release that answered, and carries every verdict written about it,
under the rubric it was written against. Save it:

```json
{"case": "e01", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e02", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e03", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e04", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e05", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "fail", "bruno": "fail", "agreed": "fail"}}
{"case": "e06", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e07", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e08", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e09", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e10", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e11", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e12", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "fail", "agreed": "fail"}}
{"case": "e13", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e14", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e15", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e16", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e17", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e18", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e19", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e20", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e21", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e22", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e23", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e24", "release": "2026.09.4", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e01", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e02", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e03", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e04", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "fail", "bruno": "fail", "agreed": "fail"}}
{"case": "e05", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "fail", "bruno": "fail", "agreed": "fail"}}
{"case": "e06", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e07", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e08", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e09", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e10", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e11", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e12", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "fail", "agreed": "fail"}}
{"case": "e13", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e14", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "fail", "bruno": "fail", "agreed": "fail"}}
{"case": "e15", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e16", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e17", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e18", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "pass"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e19", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "fail", "agreed": "fail"}}
{"case": "e20", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e21", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e22", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e23", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
{"case": "e24", "release": "2026.10.1", "relevance-v1": {"ana": "pass", "bruno": "fail"}, "relevance-v2": {"ana": "pass", "bruno": "pass", "agreed": "pass"}}
```

Forty-eight lines, five verdicts on each: Ana's and Bruno's against version 1, the same two
against version 2, and the verdict they agreed after talking, which the next sections come to.

The replies are the evaluation set's, run again by `evalrun.py` from lesson 8, once as each release:

```
ana@dev:~/obs$ python evalrun.py old --release 2026.09.4
runs/old.jsonl: 24 questions, release 2026.09.4
ana@dev:~/obs$ python evalrun.py new --release 2026.10.1
runs/new.jsonl: 24 questions, release 2026.10.1
```

The rubric's version is in every label, and that matters as much as the reply's id. A label written
against version 1 says what somebody thought version 1 meant; mixing it with labels written against a
version with different instructions measures nothing.
