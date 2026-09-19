---
title: Many-to-many, and the table nobody thinks to create
version: 1
---

Now the shape where both directions answer "yes".

An order contains several products. A product appears on several orders. Neither side is the
"one", so there is no side to put the foreign key on — and this is where the previous section's
rule runs out.

The answer is that **the relationship itself is a thing, and things get tables.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 192\" role=\"img\" aria-label=\"Two panels. On the left, headed nowhere to put the key: an orders table and a products table, each with a question-marked column pointing at the other, and a note that a column holds one value where this needs many. On the right, headed the relationship is a thing and things get tables: the same two tables with a third between them, order_lines, holding order_id and product_id, an arrow to each side, and a note that the pair is the key — one row per order and product.\"><text x=\"14\" y=\"18\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">An order holds several products and a product is on several orders. Neither side is the \"one\".</text><rect x=\"14\" y=\"44\" width=\"300\" height=\"116\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"164\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--amber)\">nowhere to put the key</text><rect x=\"34\" y=\"80\" width=\"110\" height=\"60\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"89\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">orders</text><text x=\"89\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">product_id?</text><rect x=\"184\" y=\"80\" width=\"110\" height=\"60\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"239\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">products</text><text x=\"239\" y=\"118\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">order_id?</text><text x=\"164\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">a column on either side holds one value, and this needs many</text><rect x=\"346\" y=\"44\" width=\"360\" height=\"116\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"526\" y=\"62\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--phosphor)\">the relationship is a thing, and things get tables</text><rect x=\"366\" y=\"86\" width=\"96\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"414\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">orders</text><rect x=\"590\" y=\"86\" width=\"96\" height=\"48\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"638\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">products</text><rect x=\"486\" y=\"80\" width=\"78\" height=\"60\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"525\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">order_lines</text><text x=\"525\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">order_id</text><text x=\"525\" y=\"126\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">product_id</text><path d=\"M484 110 L466 110\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></path><path d=\"M466 110 L474.0 106.0 L474.0 114.0 Z\" fill=\"var(--phosphor)\"></path><path d=\"M566 110 L588 110\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></path><path d=\"M588 110 L580.0 114.0 L580.0 106.0 Z\" fill=\"var(--phosphor)\"></path><text x=\"526\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" text-anchor=\"middle\" fill=\"var(--paper-dim)\">the pair is the key: one row per order-and-product</text><text x=\"14\" y=\"180\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Every many-to-many in every relational database that has ever existed is a third table. There is no other arrangement.</text></svg>", "caption": "The third table is not a workaround for a missing feature. It is the relationship, written down as what it is."}
```

```sql
CREATE TABLE order_lines (
    order_id   integer NOT NULL REFERENCES orders   (id) ON DELETE CASCADE,
    product_id integer NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    quantity   integer NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (order_id, product_id)
);
```

A third table, holding two foreign keys. It goes by several names — **join table**, junction
table, link table, associative table — and they all mean this. Every many-to-many relationship in
every relational database that has ever existed is a third table. There is no other way, and once
you have seen it you will recognise the shape everywhere: students and courses, actors and films,
tags and articles, users and roles.

## Reading the three tables

One row of `order_lines` says: *this order contains this product, this many times.*

| order_id | product_id | quantity |
|---|---|---|
| 1001 | 7 | 1 |
| 1002 | 7 | 2 |
| 1002 | 12 | 1 |
| 1003 | 12 | 1 |

Order 1002 contains two products, product 7 is on two orders, and the composite primary key
`(order_id, product_id)` says the same product cannot be listed twice on one order. If somebody
adds another kettle, the `quantity` goes from 2 to 3; a second row for the same pair is refused.

Both directions are now answerable, and by the same method — look for rows holding the number you
have:

- **What is on order 1002?** The rows with `order_id = 1002`, then follow each `product_id`.
- **Which orders contain product 7?** The rows with `product_id = 7`, then follow each `order_id`.

## The two cascades point different ways, on purpose

Look again at the two `ON DELETE` clauses, because they disagree and the disagreement is the
lesson:

```sql
order_id   integer NOT NULL REFERENCES orders   (id) ON DELETE CASCADE
product_id integer NOT NULL REFERENCES products (id) ON DELETE RESTRICT
```

**Deleting an order deletes its lines.** A line that says "one kettle" with no order around it is
not a record of anything — it has no meaning on its own, and nobody will ever ask about it.
`CASCADE`.

**Deleting a product must not delete the lines that mention it.** Those lines are the history of
what people bought. `RESTRICT` refuses the deletion, which is the database pointing out that you
cannot un-sell something — and the right answer is almost always to mark the product as
discontinued rather than to remove it.

This is the same judgement as the previous section, applied twice in one table, and it is worth
sitting with: the two sides of a join table are usually not symmetrical, even though the table
looks like it treats them the same.

## When the relationship has facts of its own

`quantity` is the reason this section has a heading beyond "make a third table".

A pure join table would hold only the two keys. The moment you ask "how many?", "at what price?",
"since when?", "what grade?" — those facts belong to the *pairing*, not to either side. The
quantity is not a property of the order (which has several products) and not a property of the
product (which is on several orders). It is a property of *this product on this order*.

```sql
CREATE TABLE order_lines (
    order_id     integer NOT NULL REFERENCES orders   (id) ON DELETE CASCADE,
    product_id   integer NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    quantity     integer NOT NULL CHECK (quantity > 0),
    unit_price   numeric(10,2) NOT NULL,
    PRIMARY KEY (order_id, product_id)
);
```

**`unit_price` on the line, and not read from the product, is deliberate and it is a rule worth
carrying out of this course.** The product's current price is what it costs today. What this
customer was charged is what it cost on the day they bought it, and those are two different facts.
Put the price only on `products` and every past order silently re-prices itself the next time
somebody changes a price — the invoice you printed in March stops matching the database in April,
and nothing went wrong that anybody could point at.

This looks like the duplication the whole model is against, and it is not, for a precise reason:
**it is not a copy of the same fact, it is a different fact that happens to have had the same value
once.** "What this costs" and "what this cost that day" are independent, and independent facts are
stored independently.

Recognising that difference — a copy versus a snapshot — is one of the genuinely hard parts of
modelling, and it is the reason lesson 2 spends time on when *not* to normalise.

## The shape, once, so you recognise it

Three tables. The two ends hold the things; the middle holds the pairing and anything true of the
pairing.

```
products          order_lines               orders
---------         --------------------      ---------
id  <------------ product_id                id
name              order_id ----------->     ordered_on
price             quantity                  customer_id
                  unit_price
```

The arrows point from the foreign key to the primary key it references, which is the direction the
database enforces: every `product_id` in the middle must exist on the left.

**And a last warning that saves an afternoon.** When you query across a join table you are
combining rows, and the number of rows coming back is not the number of orders — order 1002
appears twice above, once per line. Counting orders by counting rows after a join is the single
most common wrong answer in SQL, and lesson 6 is where it gets its proper treatment. For now:
notice that the middle table multiplies, and be suspicious of any total that got larger than you
expected.
