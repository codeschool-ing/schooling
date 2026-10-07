---
title: Reading the failures
version: 1
---

A score says how many. The failures say **what kind**, and what kind decides what to do next.
`evalkit errors` lists every reply that was not strictly right:

```
ana@desk:~/desk$ python lab/evalkit.py errors runs/triage.jsonl
standin-large  c20 wrong     expected order-status    got 'address-change'
standin-large  c38 wrong     expected product-question got 'other'
standin-small  c02 loose ok  expected refund          got 'Refund'
standin-small  c12 loose ok  expected refund          got 'refund.'
standin-small  c20 wrong     expected order-status    got 'address-change'
standin-small  c22 wrong     expected address-change  got 'other'
standin-small  c26 wrong     expected refund          got 'product-question'
standin-small  c31 wrong     expected refund          got 'order-status'
standin-small  c37 wrong     expected address-change  got 'other'
standin-small  c38 wrong     expected product-question got 'other'
standin-local  c06 wrong     expected order-status    got 'refund'
standin-local  c20 wrong     expected order-status    got 'address-change'
standin-local  c22 wrong     expected address-change  got 'order-status'
standin-local  c26 wrong     expected refund          got 'product-question'
standin-local  c30 wrong     expected order-status    got 'refund'
standin-local  c31 wrong     expected refund          got 'order-status'
standin-local  c34 wrong     expected other           got 'order-status'
standin-local  c38 wrong     expected product-question got 'other'
```

Eighteen lines, and they fall into four groups.

**Untidy but right.** standin-small's `Refund` for c02 and `refund.` for c12, marked `loose ok`.
The fix is in the program or the prompt (section 04), not in the choice of model.

**A boundary the model draws differently.** c22 asks to collect an order from the warehouse; the
shop calls that `address-change`, standin-small calls it `other`, standin-local `order-status`. c26
wants a partial refund for a wrong edition, and two models read the edition and answer
`product-question`. These are the cases lesson 1 section 11 sends to **examples in the prompt**: the
model understands the task and draws a line in a different place, and a few labelled borderline
cases move the line.

**A plain mistake.** standin-local's `refund` for c06, a parcel marked delivered that never came,
and for c30, a parcel the courier says it never received. Neither e-mail asks for money. A model
that hears "problem with my order" and answers `refund` is not drawing a fine line; it is not
reading carefully. Mistakes of this kind are what a smaller or weaker model trades for its price.

**Every model wrong, the same way.** c20 and c38 are wrong for all three, and wrong identically:
`address-change` for the neighbour, `other` for Portugal. When every candidate disagrees with the
label in the same direction, **suspect the label before the models**. These are the two cases ana
hesitated over in section 03.

## What to do about a suspect label

Not change it quietly. Ana takes c20 and c38 back to the person who labelled with her, and they
decide again, this time with the models' answers in front of them:

- c20, the neighbour: the customer is asking where the parcel should go. They agree the shop's own
  queues would send it to whoever handles addresses, and **relabel it `address-change`**.
- c38, Portugal: shipping destinations are answered from the same page as product questions at
  Lantern Books, so **`product-question` stays**, and they add a line to the labelling rules saying
  so.

Both decisions go into the project's history with the reason. **A label changed because a model
disagreed, without a reason a person would accept, is the evaluation grading itself.** And after
any change to the set, every candidate is re-run on the new version, because scores on two
versions of a set are not comparable. The runs in the rest of this lesson were made before the
change, on the set as section 03 left it, so their numbers can be read against section 06's.
