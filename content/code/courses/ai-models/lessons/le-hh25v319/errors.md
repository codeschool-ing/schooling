---
title: Reading the failures
version: 1
---

A score says how many. The failures say **what kind**, and what kind decides what to do next.
`evalkit errors` lists every reply that was not strictly right. The 1b's are left for the end; first
the other two models:

```
ana@desk:~/desk$ python evalkit.py errors runs/triage.jsonl | grep -v "^llama3.2:1b"
llama3.2:3b  c04 wrong     expected product-question got 'order-status, refund, address-change, product-question, other.'
llama3.2:3b  c05 loose ok  expected other           got 'other.'
llama3.2:3b  c07 wrong     expected refund          got 'order-status, refund'
llama3.2:3b  c09 wrong     expected product-question got 'order-status'
llama3.2:3b  c10 wrong     expected other           got 'order-status, refund'
llama3.2:3b  c13 wrong     expected address-change  got 'order-status'
llama3.2:3b  c14 wrong     expected product-question got 'order-status, product-question.'
llama3.2:3b  c15 wrong     expected other           got 'order-status, other.'
llama3.2:3b  c16 wrong     expected order-status    got 'product-question'
llama3.2:3b  c19 wrong     expected product-question got 'order-status'
llama3.2:3b  c21 wrong     expected refund          got 'order-status'
llama3.2:3b  c22 wrong     expected address-change  got 'order-status'
llama3.2:3b  c24 wrong     expected other           got 'order-status, other.'
llama3.2:3b  c26 wrong     expected refund          got 'order-status'
llama3.2:3b  c28 wrong     expected product-question got 'order-status, refund'
llama3.2:3b  c29 wrong     expected other           got 'order-status'
llama3.2:3b  c32 wrong     expected address-change  got 'order-status, refund, address-change, product-question, other.'
llama3.2:3b  c33 wrong     expected product-question got 'order-status'
llama3.2:3b  c34 wrong     expected other           got 'order-status, refund'
llama3.2:3b  c37 wrong     expected address-change  got 'order-status, address-change'
llama3.2:3b  c38 wrong     expected product-question got 'order-status, product-question'
llama3.2:3b  c39 wrong     expected other           got "I can't do that. If you're concerned about your account being deleted or your personal information being held, I can provide general information on data protection and account management. Would that help?"
qwen2.5:3b   c01 wrong     expected order-status    got 'product-question'
qwen2.5:3b   c06 wrong     expected order-status    got 'refund'
qwen2.5:3b   c10 wrong     expected other           got 'order-status'
qwen2.5:3b   c11 wrong     expected order-status    got 'product-question'
qwen2.5:3b   c24 wrong     expected other           got 'product-question'
qwen2.5:3b   c26 wrong     expected refund          got 'product-question'
qwen2.5:3b   c32 wrong     expected address-change  got 'order-status'
qwen2.5:3b   c34 wrong     expected other           got 'product-question'
qwen2.5:3b   c36 wrong     expected refund          got 'product-question'
qwen2.5:3b   c40 wrong     expected order-status    got 'refund'
```

Thirty-two lines, and they fall into four groups.

**Not one label.** llama3.2:3b's commonest failure is a format one: `order-status, refund`,
`order-status, product-question`, and twice the whole list of five. The prompt asks for exactly one
label and nothing else, and eleven times the model answered with a list, sometimes with the right
label somewhere inside it. Loose scoring cannot rescue that, because a list is not a label. Its one
`loose ok`, `other.` for c05, is the untidiness section 04 planned for. **The fix is in the prompt
or in a structured-output feature** (lesson 4's `S` column), not in the choice of model.

**Everything is an order.** Of llama3.2:3b's 21 wrong answers, 19 are `order-status` or start with
it, and `order-status` is the first label in the prompt's list. A model that reaches for the first
option when it is unsure has a bias, and a bias is measurable: put the labels in another order,
run the cases again, and see whether the wrong answers move with the list.

**A refusal.** c39 asks the shop to delete the customer's account and everything it holds, and
llama3.2:3b answered *I can't do that*. It read the e-mail as a request made to it, not as a message
to sort, and declined it. A refusal in place of a label is a failure
the program has to expect, because it will come back from any model on some e-mail.

**A boundary drawn somewhere else.** qwen2.5:3b's ten are all clean single labels, and every one is
a judgement it made differently from the shop. A parcel marked delivered that never came (c06) and
a parcel returned as undeliverable (c40) were `refund` to it and `order-status` to the shop; a
missing volume the customer wants refunded (c36) was a `product-question`. These are the cases
lesson 1 section 11 sends to **examples in the prompt**: the model understands the task and draws
the line in another place, and a few labelled borderline cases move the line.

## Every model wrong

Five cases are wrong for all three models: c10, c24, c26, c32 and c34. Two of them are the ones ana
hesitated over in section 03, the school discount and the refund of the difference. **When every
candidate disagrees with a label, suspect the label before the models.** Here they do not even
agree with each other: for c24, qwen2.5:3b says `product-question` and llama3.2:3b a list starting
with `order-status`, which is a sign of a hard case rather than of a wrong label.

And then the 1b, whose first six of thirty-six are typical:

```
ana@desk:~/desk$ python evalkit.py errors runs/triage.jsonl | grep "^llama3.2:1b" | head -6
llama3.2:1b  c02 wrong     expected refund          got 'order-status\nrefund\naddress-change\nproduct-question\nother'
llama3.2:1b  c03 wrong     expected address-change  got 'order-status, address-change.'
llama3.2:1b  c04 wrong     expected product-question got 'other'
llama3.2:1b  c05 wrong     expected other           got 'No.'
llama3.2:1b  c06 wrong     expected order-status    got 'order-status, refund, address-change, product-question, other.'
llama3.2:1b  c07 wrong     expected refund          got 'order-status\nrefund'
```

The whole list of labels, in a column or on one line, and `No.` to a question about visiting a
shop. **llama3.2:1b mostly does not sort at all**: it does not
follow the instruction to answer with one label. That is a finding too, and it costs a model one
line in a table rather than a month in production.

## What to do about a suspect label

Not change it quietly. Ana takes c24 and c26 back to the person who labelled with ana, and they
decide again, this time with the models' answers in front of them:

- c24, thirty copies for a school: a price for a quantity is answered by whoever negotiates, not
  from the product pages, so **`other` stays**, and they add a line to the labelling rules saying
  so.
- c26, the hardback that came as a paperback: the customer is asking for money back, so
  **`refund` stays**, whatever the edition.

Both decisions go into the project's history with the reason. **A label changed because a model
disagreed, without a reason a person would accept, is the evaluation grading itself.** And after
any change to the set, every candidate is run again, because scores on two versions of a set are
not comparable. Here both labels stood, the models were wrong, and the set did not change.
