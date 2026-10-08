---
title: Comparing two pipelines
version: 2
---

A measurement is most useful as a comparison: the pipeline as it is, against the pipeline with one
thing changed. `evaluate.py` takes the floor and k as options, so the two changes lessons 6 and 7
argued about can be tried on the dev split without touching any code.

## Lowering the floor

Lesson 6 offered a choice: a floor of 0.5, which refuses the instalments question along with the
unanswerable ones, or 0.44, which lets it through and lets the phone question reach the model too.

```
ana@vm:~/rag$ python evaluate.py --split dev --floor 0.44
dev: 20 questions, 18 answerable, floor 0.44, k 3
retrieval  recall@1 13/18  recall@3 18/18  recall@5 18/18  MRR 0.86
answers    correct 16/20  refused rightly 2/2  faithful 9/20
ana@vm:~/rag$ python evaluate.py --split dev --floor 0.44 --list | grep e14
e14  rank 2  answered  correct  UNFAITHFUL  Can I pay in instalments?
ana@vm:~/rag$ python -c "import answer; answer.FLOOR = 0.44; print(answer.answer(\"Can I pay in instalments?\", where=\"status = %s\", params=(\"current\",))[0])"
According to [1] 4.1, instalments are offered by your card issuer under its own terms, but it does not specify the maximum amount for instalments. However, [2] 1 states that a card payment can be split into up to three instalments with no interest on orders over 120. Since [2] is updated more recently than [1], I prefer [2] as the more up-to-date source. Therefore, yes, you can pay in instalments, but the maximum amount is 120.
```

**One more correct, 16 of 20, and both unanswerable questions still refused.** At 0.5, e14 was
refused. At 0.44 it was answered from the payments document, *a card payment can be split
into up to three instalments with no interest on orders over 120*, after a sentence about card
issuers from another source. And the phone question, now past the floor, reached the model, which refused
it, following lesson 7's instruction.

**A better total can still hide a worse system.** The floor that let e14 through lets every weakly
matched question reach the model, and whether the model then refuses is an instruction, followed most
of the time, where the floor was a rule followed every time. A wrong answer delivered with confidence
is worse for a customer than *I could not find that*, and the total counts them the same. This is why
`--list` exists and why a comparison should report what changed per question, not only the sums.

## Fewer sources

```
ana@vm:~/rag$ python evaluate.py --split dev --k 1
dev: 20 questions, 18 answerable, floor 0.5, k 1
retrieval  recall@1 13/18  recall@3 18/18  recall@5 18/18  MRR 0.86
answers    correct 10/20  refused rightly 2/2  faithful 11/20
```

With one source instead of three, **correctness fell from 15 to 10**. Recall@1 was 13 of 18, so for five
answerable questions the single source sent was not the one with the answer, and five is the drop.
Faithfulness rose, 11 of 20 against 9: with one source there is less to cite wrongly. Fewer tokens,
five more wrong answers: whether a smaller context is worth it is a question lesson 12 measures
properly, with packing rather than a blunt cut.

## Rules for a comparison you can trust

**Change one thing.** Two changes at once give one number and no way to say which change it belongs
to.

**Use the same test set, the same split and the same correctness check** on both sides. A comparison
across a changed test set measures the test set.

**Read the questions that changed**, not only the totals. Above, the floor's total moved by one
question, and what moved it was a reply worth reading.

**Prefer large differences.** On twenty questions one is five points. A difference of one question is
a reason to look, not a reason to decide.

**Keep the record.** The command line, the commit and the output, in a file beside the change that
was made because of them. In six months somebody will ask why the floor is 0.5, and the answer should
be a measurement, not a memory.
