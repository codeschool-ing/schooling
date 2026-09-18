---
title: A snapshot is not a copy, and this is the distinction that matters most
version: 1
---

Lesson 1 put `unit_price` on the order line while `price` sat on the product, and promised the
argument would land here. This is it, and it is the most useful distinction in the whole lesson —
because it is the one that stops the previous section being used as an excuse.

```sql
CREATE TABLE products (
    id    integer PRIMARY KEY,
    price numeric(10,2) NOT NULL
);

CREATE TABLE order_lines (
    order_id   integer NOT NULL REFERENCES orders   (id),
    product_id integer NOT NULL REFERENCES products (id),
    unit_price numeric(10,2) NOT NULL,
    PRIMARY KEY (order_id, product_id)
);
```

Two money columns holding the same number. It looks exactly like the redundancy this lesson spent
five sections removing, and it is not redundancy at all.

## The question that separates them

> **If the source changes, should this change too?**

That is the whole test.

`teacher_room` on the `courses` table: if Reis moves office, every course she teaches is now in the
new room. **Yes, it should change too** — so it was a copy, and a copy that can be left behind is
an anomaly. Out it went.

`unit_price` on the order line: if the kettle's price rises tomorrow, was Ana charged more for the
one she bought last March? **No.** It must not change. So it is not a copy of the price — it is a
different fact that happened to equal the price on one day.

## Two facts that sound like one

Say them next to each other and the difference is obvious:

```
products.price        what this costs
order_lines.unit_price   what this cost, on the day it was bought
```

Those are independent facts about different things. One is about a product, now. The other is about
a sale, then. Nothing about the relational model says two independent facts may not hold the same
value at the same moment — what it says is that **one** fact may not be stored twice.

Storing only `products.price` does not save space; it **destroys information**. The price Ana paid
stops existing the moment somebody edits the product, and no amount of joining brings it back. The
invoice you printed in March stops matching the database in April, and nothing went wrong that
anybody can point at.

## Where else this comes up

Once you have the test, you see it everywhere, and it is always the same answer:

| stored | why it is a snapshot and not a copy |
|---|---|
| the delivery address on an order | the customer moved; the parcel still went to the old one |
| the tax rate on an invoice | the rate changed; what was charged did not |
| the student's name on a certificate | she married; the certificate says what it said |
| the exchange rate on a payment | rates move constantly and the payment happened once |
| the terms accepted, on the acceptance | the terms were rewritten; that person agreed to the old ones |

This repository does exactly this, which is worth knowing because it is a real system and not an
exercise. Its certificate migration says everything on the document is captured when it is issued —
the name, the title, the school — and none of it read live, because *"a course can be renamed or
removed from the catalogue entirely… and a certificate that read its title live would silently
start naming something else, or nothing."*

Same test, same answer: **should the certificate change when the course is renamed? No. So the
title on it is not a copy.**

## Why this matters more than it looks

Two reasons, and the second is the important one.

**It is a correctness bug, not a performance one.** Getting it wrong does not make anything slow —
it makes past records silently become false as the present moves. Nobody gets an error. The
numbers just stop being what they were, and the day somebody reconciles March's invoices against
March's database, they do not match and nobody can say why.

**And it is the honest half of the previous section.** Denormalisation is a trade with a real cost,
and people reach for it far too readily. Snapshots are not that trade at all — they cost nothing,
they are not a compromise, and they are simply the correct model of a fact that is about a moment.

So when somebody says *"we denormalised the price onto the order line"*, the right response is that
they did not. They modelled it correctly. Keeping the two straight is what lets you refuse a real
denormalisation on Monday and still store an invoice's total on Tuesday without contradicting
yourself.

## The three questions, together

The whole lesson, as the questions to ask of any column that appears in two places:

1. **Is it the same fact?** If it is a fact about a different thing, it is not duplication at all.
2. **If the source changes, should this change too?** No means snapshot: store it and be right.
   Yes means copy: remove it, or accept a measured cost and say how it stays true.
3. **If it is a copy you are keeping anyway, what keeps it correct?** A trigger, one code path, a
   rebuild. No answer means no.
