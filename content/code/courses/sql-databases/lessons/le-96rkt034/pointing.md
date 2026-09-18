---
title: The foreign key: a row that points at a row
version: 1
---

The primary key gives a row a name. The **foreign key** is how another row uses it.

```sql
CREATE TABLE orders (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id integer NOT NULL REFERENCES customers (id),
    ordered_on  date    NOT NULL,
    total       numeric(10,2) NOT NULL
);
```

`REFERENCES customers (id)` is the whole idea of this course in one clause. The order does not
hold Ana's name, email or city. It holds the number `1`, and the number `1` is Ana, once,
elsewhere.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two tables side by side. The customers table has three rows with ids 1, 2 and 3, each carrying a name and an email written once. The orders table has four rows, each holding a customer_id of 1, 2, 1 or 1 rather than a copy of the name. Three arrows run from the orders rows back to customer 1, and one to customer 2. A note at the foot reads: the name is written once; the orders hold a number.\"><rect x=\"14\" y=\"38\" width=\"296\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect><text x=\"26\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">customers</text><text x=\"120\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">id</text><text x=\"160\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">name</text><text x=\"232\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">email</text>\n<rect x=\"14\" y=\"62\" width=\"296\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"120\" y=\"75\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"160\" y=\"75\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Ana Lopes</text><text x=\"232\" y=\"75\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ana@…</text>\n<rect x=\"14\" y=\"88\" width=\"296\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"120\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">2</text><text x=\"160\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Bruno Sá</text><text x=\"232\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">bruno@…</text>\n<rect x=\"14\" y=\"114\" width=\"296\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"120\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">3</text><text x=\"160\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Célia Reis</text><text x=\"232\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">celia@…</text>\n<text x=\"26\" y=\"162\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">written once</text>\n<rect x=\"410\" y=\"38\" width=\"296\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" fill-opacity=\".18\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"422\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><text x=\"500\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">id</text><text x=\"540\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">customer_id</text><text x=\"648\" y=\"50\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">date</text>\n<rect x=\"410\" y=\"62\" width=\"296\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"500\" y=\"75\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1001</text><text x=\"576\" y=\"75\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"648\" y=\"75\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">03-02</text>\n<rect x=\"410\" y=\"88\" width=\"296\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"500\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1002</text><text x=\"576\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">2</text><text x=\"648\" y=\"101\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">03-02</text>\n<rect x=\"410\" y=\"114\" width=\"296\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"500\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1003</text><text x=\"576\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"648\" y=\"127\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">03-04</text>\n<rect x=\"410\" y=\"140\" width=\"296\" height=\"26\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"500\" y=\"153\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1004</text><text x=\"576\" y=\"153\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"648\" y=\"153\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">03-07</text>\n<text x=\"422\" y=\"188\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pointed at, four times</text>\n<path d=\"M404 75 C 372 75 348 75 316 75\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path>\n<path d=\"M404 101 C 372 101 348 101 316 101\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path>\n<path d=\"M404 127 C 372 127 348 84 316 78\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path>\n<path d=\"M404 153 C 372 153 348 88 316 82\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path>\n<text x=\"360\" y=\"238\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Ana&#39;s email exists in exactly one place.</text>\n<text x=\"360\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Correct it there and all four orders are correct, because none of them held a copy.</text>\n</svg>", "caption": "Three of the four orders are Ana's, and not one of them contains her name. They contain the number 1."}
```

## What the database now refuses

Declaring the reference buys something a comment could not:

```sql
INSERT INTO orders (customer_id, ordered_on, total) VALUES (77, '2026-03-09', 39.90);
```

```
ERROR:  insert or update on table "orders" violates foreign key constraint "orders_customer_id_fkey"
DETAIL:  Key (customer_id)=(77) is not present in table "customers".
```

There is no customer 77, so there cannot be an order belonging to customer 77. The database knows
this because you told it once, in the `CREATE TABLE`, and it will go on knowing it for every
insert from every program for the lifetime of the data.

This property has a name: **referential integrity**. Every pointer points at something that
exists. Not "usually", not "as long as the application is careful" — always, by construction.

Consider what that removes. An order whose customer is missing is not a rare event in systems
without this; it is the normal end state, because there are always more programs writing to a
database than anybody remembers. The nightly import, the migration script somebody ran once, the
admin tool, the colleague fixing something by hand at 2 a.m. **A rule in the application is a rule
that applies to the programs that remember it. A rule in the database applies to everybody.**

## And what happens when you delete

The interesting half is the other direction. Ana has three orders. What happens to them if Ana is
deleted?

The database will not guess. You say, when the table is made:

```sql
customer_id integer NOT NULL REFERENCES customers (id) ON DELETE RESTRICT
```

| clause | what a `DELETE FROM customers WHERE id = 1` does |
|---|---|
| `ON DELETE RESTRICT` | refuses, because orders point at that row. The default, and usually right |
| `ON DELETE NO ACTION` | the same refusal, but checked at the end of the transaction rather than immediately |
| `ON DELETE CASCADE` | deletes Ana **and her three orders**, silently |
| `ON DELETE SET NULL` | keeps the orders and empties their `customer_id` — only legal if the column allows `NULL` |

**`CASCADE` is the one to be careful with**, and the care is not about the clause, it is about
what the child rows mean. Deleting a shopping basket should certainly delete its lines: a basket
line has no meaning without its basket. Deleting a customer should almost certainly *not* delete
their orders, because an order is a financial record that happened, and it does not stop having
happened when somebody closes their account.

The rule of thumb that survives contact with real systems:

> `CASCADE` when the child cannot exist without the parent and nobody would ever ask about it
> again. `RESTRICT` when the child is a record of something that occurred.

And when `RESTRICT` blocks a deletion you genuinely want, that is usually the database telling you
that you did not want a deletion — you wanted to mark the customer as closed and keep the history.

## Reading a reference in both directions

A single line in `CREATE TABLE` gives you two questions for free, and this is where the model
starts paying:

- **Given an order, who is the customer?** Follow the number. Exactly one row, always, because the
  foreign key guarantees it exists and the primary key guarantees it is one.
- **Given a customer, what are their orders?** Look for every order row holding that number. Zero,
  one, or a thousand — you find out by asking, and you did not have to decide in advance that this
  question would matter.

That second question is the one the spreadsheet could not answer, and nothing was added to make it
possible. It was possible the moment the name stopped being copied.

Joining the two tables — actually writing the query that produces "Ana Lopes, three orders" — is
lesson 5. What this lesson is establishing is *why the tables are shaped so that the join is
possible at all*.
