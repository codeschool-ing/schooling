---
title: Building the set
version: 1
---

The cases are the evaluation. A harness can be rewritten in an afternoon; a set of cases that
represents the work is what takes thought, and it is where most evaluations go wrong without anybody
noticing.

## Where cases come from

From the work itself. Ana took forty e-mails from the shop's inbox, removed names, addresses and
anything else that identified a customer, and kept the wording, typos and all. Invented examples
are cleaner than real ones, and that is exactly what is wrong with them: a model tested on tidy
e-mails is tested on a shop that does not exist.

Then she checked the spread:

```
ana@desk:~/desk$ python -c "import json, collections; print(collections.Counter(json.loads(l)['label'] for l in open('cases/triage.jsonl')))"
Counter({'order-status': 9, 'refund': 8, 'address-change': 8, 'product-question': 8, 'other': 7})
```

Eight or nine of each label, with `other` a little short. Real traffic is rarely that even, and
there is a choice to make: **mirror the traffic**, so the overall score predicts what the inbox will
see, or **balance the labels**, so the score for a rare label rests on more than two cases. Ana
balanced, and section 06 reports the result per model rather than claiming it predicts the
inbox. The second thing she checked was the cases with no order in them, which the extraction task
has to answer with `null`:

```
ana@desk:~/desk$ grep -c "\"order\": null" cases/triage.jsonl
15
```

Fifteen of forty. An extraction set where every e-mail names an order would never test the answer
"there is none", and it is the answer a sloppy model gets wrong.

## The cases that teach most

**Borderline cases** are worth more than easy ones, because easy ones are passed by every candidate
and separate none of them. Ana kept the e-mails she herself hesitated over. Two of them:

```
ana@desk:~/desk$ grep -E "\"c(20|38)\"" cases/triage.jsonl
{"id": "c20", "text": "Your courier left a card saying they will try again tomorrow, but I won't be home. Order LB-20466. Can they leave it with a neighbour?", "label": "order-status", "order": "LB-20466"}
{"id": "c38", "text": "Do you ship to Portugal, and how long does it take?", "label": "product-question", "order": null}
```

Is a courier's card and a request to leave the parcel with a neighbour about the order's status, or
about where it is delivered? Is shipping to Portugal a question about a product? **A person decided
both**, and the decision is the shop's policy as much as a fact about the e-mail. Section 07 shows
what happens to them.

## Labels need a second person

A label is a judgement, and one person's judgement drifts. The check is cheap: a second person
labels the same cases without seeing the first one's labels, and every disagreement is discussed
and settled before any model is run. Where two people cannot agree, **no model can be scored
fairly on that case**, and it is either rewritten, settled by a written rule, or removed.

## How many

Forty is enough to separate a bad model from a good one and too few to separate two good ones,
which section 06 measures rather than asserts. Start with what a person can label carefully in an
afternoon, and grow the set from the failures you see in use. A set that only ever grows from real
mistakes gets harder exactly where the work is hard.
