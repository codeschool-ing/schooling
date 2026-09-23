---
title: One-to-many, and where the key goes
version: 2
---

The relationship between customers and orders has a shape, and the shape has a name. **One
customer has many orders. One order belongs to one customer.** That is a *one-to-many*
relationship, and it is by far the most common thing you will model.

The only decision it forces is a small one that people reliably get backwards:

> **The foreign key goes on the "many" side.**

An order carries its customer's id. A customer does **not** carry a list of order ids.

## Why it cannot be the other way round

Try it and the reason becomes obvious. To put the relationship on the customer, you would need a
column holding several orders:

| id | name | orders |
|---|---|---|
| 1 | Ana Lopes | 1001, 1003, 1004 |
| 2 | Bruno Sá | 1002 |

Everything is wrong with this and it is all the same thing: **a column may hold one value, and
"many" is not one value.**

- The list is text, so finding the customer who placed order 1003 means searching for `1003`
  inside a string — which also matches `11003` and `1003x`.
- Ana's fourth order means reading her row, appending to the string and writing it back. Two
  orders placed in the same second and one of them is lost.
- There is nothing stopping `1003` appearing on Bruno's row too. The order now has two customers,
  and no rule was broken.

Put the key on the many side and each of those disappears without being addressed. One order, one
`customer_id` column, one value. The database's uniqueness and reference rules do the rest.

The test, when you are unsure which way round a relationship goes:

> Ask "can this one have several of those?" in both directions. The side that answers **no** is
> where the foreign key lives.

A customer can have several orders — yes. An order can have several customers — no. So the key
goes on `orders`.

## One-to-one, which is the same rule with a tighter screw

Sometimes both directions answer "no". One employee has one contract; one contract belongs to one
employee. This is a **one-to-one** relationship, and it is the one-to-many shape with a `UNIQUE`
added:

```sql
CREATE TABLE contracts (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id integer NOT NULL UNIQUE REFERENCES employees (id),
    signed_on   date    NOT NULL,
    salary      numeric(10,2) NOT NULL
);
```

`UNIQUE` on the foreign key is what turns "many" into "one": a second contract for the same
employee is refused.

**And the honest question about one-to-one is why it is two tables at all.** If every employee has
exactly one contract, the columns could live on `employees`. Three reasons it is sometimes still
right to split:

- **The parts are read at very different times.** An employee's name is read constantly; their
  salary is read by two people a month. Splitting keeps the hot table narrow.
- **The parts have different access rules.** `salary` may be readable by payroll and nobody else,
  and permissions in SQL are granted per table.
- **The second half is optional.** Not every employee has signed yet, and a missing contract is
  then a missing row rather than a row full of `NULL`s.

If none of those applies, one table is simpler and simpler is correct.

## Optional, required, and which one you are choosing

There is a second decision hiding in the one-to-many shape, and it is made by one keyword:

```sql
customer_id integer NOT NULL REFERENCES customers (id)   -- every order has a customer
customer_id integer          REFERENCES customers (id)   -- an order may have none
```

`NOT NULL` says the relationship is **mandatory**: there is no such thing as an order without a
customer. Leaving it off says the relationship is **optional**: the column may be empty, and an
empty column means "no customer", not "customer zero".

Choose deliberately, because the two produce different systems. A shop where anybody may buy
without an account needs the second. A shop where checkout requires signing in needs the first,
and declaring it means an order without a customer can never be created — not by the website, not
by the import script, not by anybody at 2 a.m.

The default worth holding: **make it `NOT NULL` unless you can describe the row that has none.**
If you cannot say out loud what an order with no customer would mean, it should not be possible to
write one.

## What this shape buys you at the far end

It is worth seeing, once, what the whole arrangement is for — even though the query itself belongs
to lesson 5 and lesson 6.

With `customers` and `orders` shaped this way, none of these questions needed planning for:

- Every order Ana ever placed, in date order.
- How many customers ordered more than once in March.
- Customers with no orders at all — which is a question about *absence*, and is answerable
  precisely because an order that does not exist is a row that is not there rather than a blank in
  a string.
- The average number of orders per customer, per city.

Not one of those required a column to be added, and not one of them was anticipated when the
tables were created. That is the return on the small discomfort of putting Ana in a table of her
own.
