---
title: N+1, the mistake that looks like ordinary code
version: 1
---

Here is a page that lists fifty customers with their orders, written the way every tutorial
writes it:

```
customers = Customer.order('id').limit(50)
for customer in customers:
    for order in customer.orders:
        print(customer.name, order.total)
```

Four lines, and nothing in them looks like a database problem. The first line runs one query.
`customer.orders` on the third line runs one query **per customer**, because the orders were not
loaded with the customers — the ORM fetches them the first time they are asked for, which is
inside the loop. Fifty customers, fifty queries, plus the one that fetched the customers: **N+1**.

The last section captured it from the server's side:

```
shop=# SELECT calls, left(query, 60) AS query FROM pg_stat_statements WHERE query LIKE 'SELECT id,%' ORDER BY calls DESC;
 calls |                            query                             
-------+--------------------------------------------------------------
    50 | SELECT id, placed_at, total FROM orders WHERE customer_id = 
     1 | SELECT id, name FROM customers ORDER BY id LIMIT $1
(2 rows)
```

One statement ran fifty times. Lesson 7 met this shape as a correlated subquery and said the two
are the same mistake at different altitudes. This is the higher one, and it is worse, because every
one of those fifty is a round trip across a network rather than a lookup inside the engine.

## Why it is invisible

Three reasons, and each is a reason the code review does not catch it.

**Each query is fast.** Fifty index lookups at a fraction of a millisecond each look fine in
`pg_stat_statements` sorted by mean, and in the log they are fifty unremarkable lines. The cost is
the count, and lesson 10 said which column shows the count.

**It scales with the data, not with the code.** Fifty customers on the developer's machine is
fifty-one queries and a page that renders in a moment. Five thousand on production is five
thousand and one, and the same four lines take seconds. Nothing changed but N.

**It is the ORM doing what it said it would.** Lazy loading — fetching a relationship when it is
first touched — is the default in nearly every mapper because it is the right behaviour for the
common case of touching nothing. The loop is the uncommon case, and the default does not know
it is in one.

## Where it hides

The literal loop above is the textbook form, and it is the one people learn to see. The others
are the same thing wearing a template or a serialiser:

- **A template** that writes `{{ order.customer.name }}` on each row of a list of orders. The
  loop is in the template engine, and the query per row is in the property access.
- **A serialiser** that turns a list of objects into JSON, and each object has a relationship
  that the serialiser walks.
- **A method on the model** — `customer.total_spent()` — that runs a query, called once per row
  of a report.
- **Nested relationships**: customers, each with orders, each with lines. N+1 inside N+1, which is
  N + N·M + 1, and the product is what makes a page time out.

None of these has a `for` in the code that the reviewer reads, which is why the count in
`pg_stat_statements` finds them and reading finds fewer.

## The fix is one of two shapes

Ask for the orders **with** the customers, in one statement, or in one statement per level rather
than per row. Both shapes are built into every ORM under a name of its own, and the next section
is the two shapes, their SQL, and when each is the right one.

What the fix is never: denormalising, caching, or a bigger server. Lesson 2 said so from the
other side: the N+1 is the most common cause of "the database is slow" and none of those touch
it. And lesson 10 said why a bigger server does not help a problem whose cost is round trips.
