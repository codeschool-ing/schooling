---
title: Deciding what counts as right
version: 1
---

A reply and an expected answer have to be compared somehow, and the choice of comparison changes the
score more than people expect. It is not a detail of the harness. It is **a decision about what
your program can accept**, and it should be written down with the cases.

## Strict and loose

For the sorting task, `lab/evalkit.py` judges every reply twice:

- **strict**: the reply is exactly the label, character for character;
- **loose**: the reply matches after removing spaces at the ends, folding to lower case, and
  dropping a final full stop.

Four replies to a case whose label is `refund`:

```
ana@desk:~/desk$ python -c "from lab.evalkit import score_triage as s; c = {'label': 'refund'}; print(s('refund', c), s('Refund', c), s('refund.', c), s('order-status', c))"
(True, True) (False, True) (False, True) (False, False)
```

Each pair is (strict, loose). `refund` passes both. `Refund` and `refund.` fail strict and pass
loose: the model chose correctly and wrote it untidily. `order-status` fails both: the model chose
wrong.

**Both numbers matter, for different reasons.** Loose measures whether the model understood the
task. Strict measures whether the program can use the reply as it comes. A gap between them is a
fixable problem, either with a tidying step in the program (which then *is* the loose rule, so
write it once and use it in both places) or with an instruction or a structured-output feature
(lesson 4's `S` column) that makes the model write exactly the label.

## For extraction: does it parse

The extraction task asks for JSON. `score_extract` treats strict as **the whole reply parses as JSON
and the order is right**, and loose as **some `{...}` inside the reply parses and the order is
right**:

```
ana@desk:~/desk$ python -c "from lab.evalkit import score_extract as s; c = {'order': 'LB-20452'}; print(s('{\"order\": \"LB-20452\"}', c), s('Here is the JSON: {\"order\": \"LB-20452\"}', c))"
(True, True) (False, True)
```

The second reply has the right order number inside a sentence. A person would call it right. A
program calling `json.loads` on it crashes. Which of the two numbers decides depends on the program,
and ana's program calls `json.loads`.

## What not to score with

**Another model**, for these two tasks. A model asked "is this label right?" is slower, costs money,
and can be wrong in ways that correlate with the model being judged. When the answer can be checked
by a program, a program checks it. Judging by model earns its place for open-ended output such as
ana's drafts, where there is no single right answer, and even there its verdicts are checked against
a person's on a sample before anybody trusts them. That is `prompt-reliability`'s subject; this
lesson keeps to what a program can decide.
