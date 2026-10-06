---
title: An answer has to stand on its source
version: 1
---

The assistant answers clients' questions from Tarefa's help centre. **An answer is grounded when what
it says can be found in the sources it was given**, and the cheapest defence against an invented
answer is to require it to name its sources and then check that they say what it says. The help
centre in the lab is three short pages, written by the course:

```
ana@lab:~/guard$ ls data/helpdesk
hc-fees.md
hc-payouts.md
hc-refunds.md
ana@lab:~/guard$ cat data/helpdesk/hc-refunds.md
# Refunds

A client may ask for a refund of a job up to 14 days after its due date.
If the freelancer delivered nothing, the refund is the full amount paid.
If part of the work was delivered, a person on the support team decides the amount.
Refunds reach the client's card or Pix account in up to 5 business days.
```

`data/answers.jsonl` holds six answers, **written by the course in place of what a model would
reply**, each with the documents it cites. `guard ground` applies three rules: an answer cites at
least one document or says it does not know; every cited document exists; every number in the answer
appears in a cited document.

```
ana@lab:~/guard$ head -2 data/answers.jsonl
{"id": "a1", "question": "How long do I have to ask for a refund?", "text": "You can ask for a refund up to 14 days after the job's due date.", "cites": ["hc-refunds"]}
{"id": "a2", "question": "How long do I have to ask for a refund?", "text": "You can ask for a refund up to 30 days after the job's due date.", "cites": ["hc-refunds"]}
ana@lab:~/guard$ guard ground data/answers.jsonl; echo "exit $?"
a1  ok    grounded in hc-refunds
a2  FLAG  the number 30 is in no cited document
a3  FLAG  cites hc-guarantee, which does not exist
a4  FLAG  cites nothing
a5  ok    abstains
a6  ok    grounded in hc-payouts
3 of 6 answers flagged
exit 1
```

- `a2` cites the right page and says 30 days where the page says 14. The number is the invention, and
  the number is what a client acts on.
- `a3` cites `hc-guarantee`, a page that does not exist, for a guarantee that does not exist either.
  An invented source is the most common shape of an invented answer, and the easiest to catch.
- `a4` cites nothing and states a 15% fee, against the 10% the fee page gives.
- `a5` says it does not know and passes the question to a person. **Abstaining is a correct answer**,
  and a system that punishes it teaches the model, through the prompt and the evaluation, to guess.

What happens to a flagged answer follows lesson 19: it is not shown, and the question goes back to the
model once with the problem, or to a person.

## What this check cannot see

`a6` passed. Read it against its source:

```
ana@lab:~/guard$ grep a6 data/answers.jsonl
{"id": "a6", "question": "When are freelancers paid?", "text": "Freelancers are paid by Pix 2 business days after the job is posted.", "cites": ["hc-payouts"]}
ana@lab:~/guard$ cat data/helpdesk/hc-payouts.md
# Payouts

Freelancers are paid by Pix 2 business days after the client approves the work.
A payout key can only be changed on the Payouts page.
```

The answer cites the right page and every number in it is on that page. It is still wrong: payment
follows the client's approval, not the posting of the job. The check compares numbers and names,
**and it does not understand a sentence**, so a wrong conclusion drawn from the right page passes.

Stronger checks exist and cost more: comparing each claim with the passage it came from using a
second model, or showing the client the passage beside the answer so that they can see it. Each one
catches some of what the cheap check misses, and none catches everything, which is why the documents
the assistant answers from are kept short, current and unambiguous. A help centre that contradicts
itself produces grounded answers that contradict each other.
