---
title: Comparing two pipelines
version: 1
---

A measurement is most useful as a comparison: the pipeline as it is, against the pipeline with one
thing changed. `evaluate.py` takes the floor and k as options, so the two changes lessons 6 and 7
argued about can be tried on the dev split without touching any code.

## Lowering the floor

Lesson 6 offered a choice: a floor of 0.5, which refuses the instalments question along with the
unanswerable ones, or 0.44, which lets it through and lets the phone question reach the model too.

```
ana@lab:~/rag$ python evaluate.py --split dev --floor 0.44
dev: 20 questions, 18 answerable, floor 0.44, k 3
retrieval  recall@1 13/18  recall@3 18/18  recall@5 18/18  MRR 0.86
answers    correct 15/20  refused rightly 2/2  faithful 20/20
ana@lab:~/rag$ python evaluate.py --split dev --floor 0.44 --list | grep e14
e14  rank 2  answered  WRONG    faithful  Can I pay in instalments?
ana@lab:~/rag$ python -c "import answer; answer.FLOOR = 0.44; print(answer.answer(\"Can I pay in instalments?\", where=\"status = %s\", params=(\"current\",))[0])"
Instalments are offered by your card issuer under its own terms. [1]
```

**The totals did not move: 15 of 20 correct, both unanswerable questions still refused.** But e14
changed underneath them. At 0.5 it was refused; at 0.44 it was answered, with *Instalments are
offered by your card issuer under its own terms*, which is true, cited and not the answer: the answer
is *up to three instalments with no interest on orders over 120*. A refusal became a wrong answer. And
the phone question, now past the floor, was refused anyway, by extract-1's own threshold; a real model
might not have been so careful.

**The same total can hide a worse system.** A wrong answer delivered with confidence is worse for a
customer than *I could not find that*, and the total counts them the same. This is why `--list` exists
and why a comparison should report what changed per question, not only the sums.

## Fewer sources

```
ana@lab:~/rag$ python evaluate.py --split dev --k 1
dev: 20 questions, 18 answerable, floor 0.5, k 1
retrieval  recall@1 13/18  recall@3 18/18  recall@5 18/18  MRR 0.86
answers    correct 14/20  refused rightly 2/2  faithful 20/20
```

With one source instead of three, correctness fell from 15 to 14. Recall@1 was 13 of 18, so for five
answerable questions the single source sent was not the one with the answer; one of those had been
answered correctly from the second source when there were three. Fewer tokens, one more wrong answer:
whether that trade is worth it is a question lesson 12 measures properly, with packing rather than a
blunt cut.

## Rules for a comparison you can trust

**Change one thing.** Two changes at once give one number and no way to say which change it belongs
to.

**Use the same test set, the same split and the same correctness check** on both sides. A comparison
across a changed test set measures the test set.

**Read the questions that changed**, not only the totals. Above, the totals were identical and one
question got worse.

**Prefer large differences.** On twenty questions one is five points. A difference of one question is
a reason to look, not a reason to decide.

**Keep the record.** The command line, the commit and the output, in a file beside the change that
was made because of them. In six months somebody will ask why the floor is 0.5, and the answer should
be a measurement, not a memory.
