---
title: A table is a set of facts about one kind of thing
version: 1
---

A table looks like a spreadsheet and is not one, and the differences are the reason it can do what
the sheet could not.

```sql
CREATE TABLE customers (
    id     integer PRIMARY KEY,
    name   text    NOT NULL,
    email  text    NOT NULL,
    city   text
);
```

Four lines, and every one of them is a promise the database will keep on your behalf. Before the
promises, though, the shape.

## One table, one kind of thing

`customers` holds customers. Not customers and their orders; not customers and the products they
like. **One table is about one kind of thing**, and the test is whether you can finish the
sentence *"each row is one ______"* with a single noun.

That sounds like a stylistic preference. It is not — it is what makes the pointing work. If a row
were one customer *and* one order, there would be no single place that is "the customer", and
nothing could point at it.

## A row is a fact, and it is whole

Each row says one thing that is true:

> Customer 1 is called Ana Lopes, her email is ana@example.com, and she is in Porto.

A row is not a position in a list. **Rows have no order.** This surprises people coming from
spreadsheets, where row 4 is unambiguously below row 3 and you can drag it somewhere else. A table
is a *set* of rows, and a set has no first element. When you ask a database for rows without
saying how to sort them, you are allowed to get them in any order at all — and in real systems the
order changes over time, silently, as the data grows and the database changes its mind about how
to fetch them.

Two consequences follow immediately, and both catch beginners:

- **You may never rely on the order rows come back in unless you asked for an order.** A query
  that worked for a year can start returning rows differently after an unrelated change. Nothing
  is broken; you were relying on something nobody promised.
- **There is no "row number" to point at.** Whatever identifies a row has to be *in* the row. That
  is the next section, and it is the heart of this lesson.

## A column has a type, and the type is enforced

In a spreadsheet a cell holds whatever you type. A column in a table holds one kind of value, and
the database refuses anything else:

```sql
INSERT INTO customers (id, name, email, city)
VALUES ('banana', 'Ana Lopes', 'ana@example.com', 'Porto');
```

```
ERROR:  invalid input syntax for type integer: "banana"
LINE 2: VALUES ('banana', 'Ana Lopes', 'ana@example.com', 'Porto');
                ^
```

This is a small thing that compounds enormously. A column declared `date` cannot hold `"next
Tuesday"`, `"03/04/2026"` or an empty string, so every value in it is a real date and can be
compared with every other one. A spreadsheet column that *looks* like dates usually contains four
different formats and two pieces of prose, and you find out when you try to sort it.

The common types, and the ones worth knowing on day one:

| type | holds | the trap |
|---|---|---|
| `integer`, `bigint` | whole numbers | `integer` stops near 2.1 billion — small for row ids on a busy table |
| `numeric(10,2)` | exact decimals | **money goes here**, never in `real` or `double` |
| `real`, `double precision` | approximate decimals | `0.1 + 0.2` is not `0.3`; fine for measurements, wrong for money |
| `text`, `varchar(n)` | characters | in PostgreSQL `text` is not slower than `varchar(n)`; the length limit is a rule, not an optimisation |
| `boolean` | true / false | and `NULL`, which is neither — see later in this lesson |
| `date`, `timestamptz` | a day, a moment | `timestamptz` stores a real instant; `timestamp` stores digits with no timezone and is a bug waiting |

**Money in a floating-point column is the single most expensive type mistake in this table**, and
it is worth a line of its own. `real` and `double precision` store approximations in binary, and
tenths of a cent are not representable in binary any more than a third is in decimal. Add a
thousand invoices and the total is wrong by a few cents — small enough that nobody notices for a
year, and large enough that an accountant eventually does. Use `numeric`.

## Columns versus rows, and which one grows

This is the shape decision people get wrong most often, so meet it now.

Suppose customers can be tagged: `vip`, `wholesale`, `newsletter`. The spreadsheet instinct is a
column per tag, or one column holding `"vip, newsletter"`.

Both are wrong, and the reason is the same for each: **a new tag would change the shape of the
table.** Adding a fourth tag means adding a column, which means every query that named the columns
has to be revisited. And a column holding `"vip, newsletter"` is a list hiding inside a string —
to ask "how many VIPs" you would be searching for text inside text, which finds `"non-vip"` too.

The relational answer is that tags are *things*, so they get a table, and the connection between a
customer and a tag is also a thing, so it gets one too. That is the many-to-many section later in
this lesson. What matters here is the principle:

> **Data grows in rows. Structure grows in columns.** If adding one more of something would mean
> adding a column, the shape is wrong.

## What the table does not hold

A last thing, and it is about what is deliberately absent.

The `customers` table holds no orders, no totals and no count of how many times Ana has bought
something. The count is not stored because it is not a fact about Ana — it is a fact about her
orders, and it can be computed from them at the moment somebody asks.

Storing it would mean keeping it correct: every new order would have to remember to increase it,
every cancellation to decrease it, and the day one of them forgets, the number is wrong with
nothing to compare it against. That is the same defect as three copies of an email address,
wearing its third coat.

There are real reasons to store a computed value anyway — it is called denormalisation, it is a
performance decision, and it has a whole section in lesson 2. The default, though, and the thing to
reach for until you have measured a reason not to: **store what you were told, compute what
follows from it.**
