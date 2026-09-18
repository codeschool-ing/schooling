---
title: The three statements that change data
version: 1
---

Lessons 4 to 7 asked questions. These three tell the database something, and between them they are
the whole of changing data:

```sql
INSERT INTO customers (name, email, city) VALUES ('Duarte Alves', 'duarte@example.com', 'Sao Paulo');
UPDATE orders SET status = 'shipped' WHERE ordered_on < DATE '2026-03-05';
DELETE FROM order_lines WHERE order_id = 7;
```

**The `WHERE` is the same `WHERE`.** Every operator, every pattern, `IN`, `BETWEEN`, and `NULL`
refusing to equal itself — lesson 4 taught all of it and not one rule changes here. A row the
`SELECT` would have returned is a row the `UPDATE` changes.

What changes is what a mistake costs. That is why these arrive in this lesson and not in lesson 4:
the next section is about the mistake, and the rest of this one is about the statements.

## `INSERT`

```
shop=# INSERT INTO customers (name, email, city) VALUES ('Duarte Alves', 'duarte@example.com', 'Sao Paulo');
INSERT 0 1
```

One row. The zero is an object identifier PostgreSQL stopped using in 2005 and still prints.

**Write the column list.** It is optional, and leaving it out matches the values to the columns in
the order the table happens to declare them — starting with the first one, which here is the
identity key nobody meant to supply:

```
shop=# INSERT INTO customers VALUES ('Xico', 'xico@example.com', 'Porto');
ERROR:  invalid input syntax for type integer: "Xico"
LINE 1: INSERT INTO customers VALUES ('Xico', 'xico@example.com', 'P...
                                      ^
```

That one is loud because the types disagree. The quiet version is a table of text columns and a
statement that has been right for two years. PostgreSQL appends a new column, so the old `INSERT`
keeps working and stops filling it without saying anything. MySQL can add one **in the middle**,
where the values shift and every row written after the deploy is wrong by one column. The list
costs a line and removes the category.

Several rows go in one statement:

```
shop=# INSERT INTO products (sku, name, price) VALUES ('HD-500', 'Headset', 259.00), ('WC-020', 'Webcam', 179.90);
INSERT 0 2
```

That is not only shorter to read. Three thousand rows as three thousand statements is three thousand
round trips to the server, and lesson 11 is largely about what that costs.

The values can come from a query instead, in which case `VALUES` is replaced by the `SELECT` whole:

```sql
INSERT INTO cancelled_archive (id, customer_id, ordered_on)
SELECT id, customer_id, ordered_on FROM orders WHERE status = 'cancelled';
```

**What you leave out is what the table decides.** Lesson 3 declared `ordered_on` as
`DEFAULT current_date` and `status` as `DEFAULT 'placed'`, and this is the first time you watch them
fire:

```
shop=# INSERT INTO orders (customer_id) VALUES (3) RETURNING id, ordered_on, status;
 id | ordered_on | status 
----+------------+--------
  5 | 2026-09-18 | placed
(1 row)

INSERT 0 1
```

The date is the day the statement ran, which is what `DEFAULT current_date` means. And `RETURNING`
hands back the row as it ended up — defaults filled in and the generated key included, which is how
you learn the `id` the database chose without asking a second question and trusting that nothing
happened in between.

## `UPDATE`

```
shop=# UPDATE orders SET status = 'shipped' WHERE ordered_on < DATE '2026-03-05';
UPDATE 3
```

Three rows. **That number is the cheapest check in this lesson**, and the next section is mostly
about reading it.

The right-hand side of a `SET` is an expression, and it may read the column it is writing:

```
shop=# UPDATE products SET price = price * 1.10 WHERE sku = 'KB-101' RETURNING sku, price;
  sku   | price  
--------+--------
 KB-101 | 384.89
(1 row)

UPDATE 1
```

Every row is computed from its own current value, in one pass, with no loop and no statement per
row. A price rise across a catalogue is one line.

## `DELETE`

```sql
DELETE FROM order_lines WHERE order_id = 7;
```

Same shape and the same `WHERE`. `RETURNING` works here too, and it is the only way to see what you
removed — afterwards there is nothing left to select:

```
shop=# DELETE FROM order_lines WHERE quantity > 1 RETURNING order_id, product_id, quantity;
 order_id | product_id | quantity 
----------+------------+----------
        2 |          3 |        2
        3 |          4 |        2
(2 rows)

DELETE 2
```

**`DELETE FROM order_lines;` with no `WHERE` empties the table.** It is legal, and it is
occasionally what you meant.

## The constraints from lesson 3 are what enforce all of this

Everything the table declares applies to every one of these statements, and the refusal is the
feature rather than the friction:

```
shop=# UPDATE orders SET status = 'enviado' WHERE id = 1;
ERROR:  new row for relation "orders" violates check constraint "orders_status_check"
DETAIL:  Failing row contains (1, 1, 2026-03-02, enviado).
```

It refused a status no other code in the system knows how to read. Lesson 3 said a constraint is a
rule the database keeps whatever writes to it; this is the keeping, and the `DETAIL` line names the
row so you do not have to go looking.

The foreign keys are the same rule, and a `DELETE` is where the two words at the end of lesson 1's
schema finally do something:

```
shop=# DELETE FROM customers WHERE email = 'ana@example.com';
ERROR:  update or delete on table "customers" violates foreign key constraint "orders_customer_id_fkey" on table "orders"
DETAIL:  Key (id)=(1) is still referenced from table "orders".
```

`ON DELETE RESTRICT`: Ana has orders, so Ana stays. On the other side of the schema, `order_lines`
says `ON DELETE CASCADE`, and that one does not refuse — it follows:

```
shop=# SELECT count(*) FROM order_lines WHERE order_id = 3;
 count 
-------
     2
(1 row)

shop=# DELETE FROM orders WHERE id = 3;
DELETE 1

shop=# SELECT count(*) FROM order_lines WHERE order_id = 3;
 count 
-------
     0
(1 row)
```

**`DELETE 1`, and two rows nobody named are gone.** That is exactly what the schema asked for, and
it is worth knowing which of your foreign keys say `CASCADE` before you find out this way.
