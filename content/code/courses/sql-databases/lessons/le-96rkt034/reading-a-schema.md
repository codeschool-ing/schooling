---
title: Reading a schema, and drawing one
version: 1
---

Everything in this lesson so far has been one table at a time. A **schema** is all of them
together with the references between them, and being able to read one on a screen — somebody
else's, from a system you have just joined — is a practical skill that pays immediately.

Here is the shop, complete:

```sql
CREATE TABLE customers (
    id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name   text    NOT NULL,
    email  text    NOT NULL UNIQUE,
    city   text
);

CREATE TABLE products (
    id     integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sku    text          NOT NULL UNIQUE,
    name   text          NOT NULL,
    price  numeric(10,2) NOT NULL CHECK (price >= 0)
);

CREATE TABLE orders (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id integer NOT NULL REFERENCES customers (id) ON DELETE RESTRICT,
    ordered_on  date    NOT NULL DEFAULT current_date,
    status      text    NOT NULL DEFAULT 'placed'
                        CHECK (status IN ('placed', 'shipped', 'cancelled'))
);

CREATE TABLE order_lines (
    order_id   integer NOT NULL REFERENCES orders   (id) ON DELETE CASCADE,
    product_id integer NOT NULL REFERENCES products (id) ON DELETE RESTRICT,
    quantity   integer NOT NULL CHECK (quantity > 0),
    unit_price numeric(10,2) NOT NULL CHECK (unit_price >= 0),
    PRIMARY KEY (order_id, product_id)
);
```

Four tables. Read in this order they tell a story: who buys, what is sold, what was bought, and
what was on it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"An entity relationship diagram of four tables. Customers and products sit on the outside; orders sits between customers and order lines; order lines sits between orders and products. A crow's foot marks the many side of each relationship: one customer to many orders, one order to many order lines, one product to many order lines.\"><rect x=\"18\" y=\"40\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"18\" y=\"40\" width=\"150\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\"></rect><text x=\"28\" y=\"53\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">customers</text><text x=\"28\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">id</text><text x=\"28\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">name</text><text x=\"28\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">email</text><text x=\"28\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">city</text>\n<rect x=\"285\" y=\"40\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><rect x=\"285\" y=\"40\" width=\"150\" height=\"24\" rx=\"3\" fill=\"var(--phosphor-dim)\" fill-opacity=\".2\"></rect><text x=\"295\" y=\"53\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><text x=\"295\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">id</text><text x=\"295\" y=\"96\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">customer_id</text><text x=\"295\" y=\"114\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ordered_on</text><text x=\"295\" y=\"130\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">status</text>\n<rect x=\"285\" y=\"196\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"285\" y=\"196\" width=\"150\" height=\"24\" rx=\"3\" fill=\"var(--wire)\" fill-opacity=\".3\"></rect><text x=\"295\" y=\"209\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">order_lines</text><text x=\"295\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">order_id</text><text x=\"295\" y=\"252\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">product_id</text><text x=\"295\" y=\"270\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">quantity</text><text x=\"295\" y=\"286\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">unit_price</text>\n<rect x=\"552\" y=\"196\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"552\" y=\"196\" width=\"150\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\"></rect><text x=\"562\" y=\"209\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">products</text><text x=\"562\" y=\"234\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">id</text><text x=\"562\" y=\"252\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sku</text><text x=\"562\" y=\"270\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">name</text><text x=\"562\" y=\"286\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">price</text>\n<path d=\"M168 88 L285 88\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M285 78 L271 88 L285 98\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<text x=\"226\" y=\"78\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 → many</text>\n<path d=\"M360 136 L360 196\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M350 196 L360 182 L370 196\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<text x=\"370\" y=\"168\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 → many</text>\n<path d=\"M552 244 L435 244\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<path d=\"M435 234 L449 244 L435 254\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path>\n<text x=\"493\" y=\"234\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 → many</text>\n<text x=\"360\" y=\"318\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">order_lines is the many-to-many between orders and products. The fork is the &#34;many&#34; end.</text>\n</svg>", "caption": "The same four tables as a picture. Amber names are keys; the forked end of each line is the side that may have several."}
```

## How to read one you did not write

A diagram like that is the second thing to look at. The first is the schema text, and there is an
order that gets you oriented fastest.

**1. List the tables and say what one row of each is.** Out loud, with a singular noun. `orders`
— one row is one order. `order_lines` — one row is one product on one order. If you cannot finish
the sentence for a table, that is the table to ask somebody about; it is either badly named or it
is holding two things.

**2. Find the join tables.** A table whose primary key is two foreign keys is a relationship, not a
thing. Those are where the interesting questions live, and spotting them immediately tells you
which pairs of tables are many-to-many.

**3. Read the `NOT NULL`s as a description of what is required.** `orders.customer_id NOT NULL`
says this system has no anonymous orders. That is a product decision, visible in the schema, and
it often tells you more about how the business works than the documentation does.

**4. Read the `ON DELETE`s as a description of what is disposable.** `CASCADE` marks the parts;
`RESTRICT` marks the records. In one pass you learn what this system considers history.

**5. Look for the missing constraints.** A `text` column called `status` with no `CHECK`, a column
that is obviously an email with no `UNIQUE`, a money column typed `double precision`. These are
where the bugs are, and being able to spot them in five minutes is most of what makes somebody
useful in their first week on an unfamiliar system.

## Asking the database to tell you

You will not always be handed the `CREATE TABLE` statements. Every database can describe itself,
and in `psql` the commands are short:

```
ana@vm:~$ psql shop
psql (18.1)
Type "help" for help.

shop=# \dt
            List of relations
 Schema |    Name     | Type  | Owner
--------+-------------+-------+-------
 public | customers   | table | ana
 public | order_lines | table | ana
 public | orders      | table | ana
 public | products    | table | ana
(4 rows)

shop=# \d orders
                             Table "public.orders"
   Column    |  Type   | Nullable |           Default
-------------+---------+----------+------------------------------
 id          | integer | not null | generated always as identity
 customer_id | integer | not null |
 ordered_on  | date    | not null | CURRENT_DATE
 status      | text    | not null | 'placed'::text
Indexes:
    "orders_pkey" PRIMARY KEY, btree (id)
Check constraints:
    "orders_status_check" CHECK (status = ANY (ARRAY['placed'::text, 'shipped'::text, 'cancelled'::text]))
Foreign-key constraints:
    "orders_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT
Referenced by:
    TABLE "order_lines" CONSTRAINT "order_lines_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
```

**The `Referenced by:` section at the bottom is the one people miss**, and it is the most useful
part. It answers the question the `CREATE TABLE` cannot: *who points at me?* — which is what you
need before changing or deleting anything.

`\dt` and `\d` are PostgreSQL's. MySQL and MariaDB use `SHOW TABLES` and `DESCRIBE orders`; SQLite
uses `.tables` and `.schema orders`. Lesson 12 covers the differences properly.

## The design, in one page

Everything in this lesson, as the sequence you would actually follow to model something new:

1. **Name the things.** Nouns from how people talk about the work: customer, order, product. Each
   becomes a table, each with a surrogate primary key.
2. **Write down the facts about each thing**, one column each, with a type. Money is `numeric`.
3. **Find the relationships and ask "several?" in both directions.** One "no" means a foreign key
   on the "many" side. Two "yes"es mean a third table.
4. **Ask what belongs to the pairing** rather than to either end — quantity, price on the day, the
   date it started. Those columns go in the join table.
5. **Make every column `NOT NULL`** except those where you can say what empty means.
6. **Decide each `ON DELETE`** by asking whether the child is a part or a record.
7. **Add a `CHECK` wherever you would otherwise write a comment.**

Lesson 2 takes this from a procedure to a theory — normalisation is the name for what steps 1 to 4
are approximating, it has rules that say precisely when a design is finished, and it also says
when to deliberately break them.
