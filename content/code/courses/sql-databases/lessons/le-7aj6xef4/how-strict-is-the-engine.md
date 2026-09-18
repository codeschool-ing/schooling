---
title: What each one refuses
version: 1
---

This is the largest difference between the four, and it is not close. Lesson 3 said a column's
type is a promise the database keeps on your behalf. **How hard it keeps it is an engine
decision**, and the same `INSERT` is an error on one engine and a stored row on another.

Start with the one that shows the gap in a single command. `order_lines.quantity` is
`INTEGER NOT NULL CHECK (quantity > 0)` on all three. Here is a quantity of `'three'`:

```
shop=# INSERT INTO order_lines VALUES (5, 2, 'three', 189.00);
ERROR:  invalid input syntax for type integer: "three"
LINE 1: INSERT INTO order_lines VALUES (5, 2, 'three', 189.00);
                                              ^
```

```
mysql> INSERT INTO order_lines VALUES (5, 2, 'three', 189.00);
ERROR 1366 (HY000) at line 1: Incorrect integer value: 'three' for column 'quantity' at row 1
```

```
sqlite> INSERT INTO order_lines VALUES (5, 2, 'three', 189.00);
sqlite> SELECT order_id, product_id, quantity, typeof(quantity) FROM order_lines WHERE order_id = 5;
order_id  product_id  quantity  typeof(quantity)
--------  ----------  --------  ----------------
5         2           three     text            
5         3           2         integer         
```

SQLite took it. The column says `INTEGER NOT NULL`, the row holds the string `three`, and the
`CHECK (quantity > 0)` passed — because in SQLite a text value compares as greater than any
number, so `'three' > 0` is true. Nothing was refused, nothing was logged, and the next report
that sums that column will be wrong.

## Why SQLite does that

Not a bug and not laziness. SQLite has **dynamic typing**: a value carries its own type, and a
column's declared type is an *affinity* — a preference applied when a value can be converted, and
ignored when it cannot. `INTEGER` means "store this as an integer if you reasonably can".

You can see the consequence without inserting anything odd. This is the shop's price column, which
lesson 3 was careful to declare `NUMERIC(10,2)` so that money would be exact:

```
sqlite> SELECT sku, price, typeof(price) FROM products;
sku     price  typeof(price)
------  -----  -------------
KB-101  349.9  real         
MS-204  189    integer      
MN-330  1499   integer      
CB-012  39.9   real         
```

Four rows of one column, two of them stored as `real` and two as `integer`, **decided per row**.
`349.90` became a floating-point number, and the trailing zero is not missing from the display —
it was never stored. The other three engines hold the same column as an exact decimal:

```
shop=# SELECT sku, price, pg_typeof(price) FROM products;
  sku   |  price  | pg_typeof 
--------+---------+-----------
 KB-101 |  349.90 | numeric
 MS-204 |  189.00 | numeric
 MN-330 | 1499.00 | numeric
 CB-012 |   39.90 | numeric
(4 rows)
```

Which is why the report in the last section came back as `2998.00` on three engines and `2998` on
the fourth. That was not a formatting difference. It was float arithmetic, and lesson 3 named the
failure it leads to:

```
shop=# SELECT 0.1 + 0.2 = 0.3 AS exact;
 exact 
-------
 t
(1 row)
```

```
mysql> SELECT 0.1 + 0.2 = 0.3 AS exact;
+-------+
| exact |
+-------+
|     1 |
+-------+
```

```
sqlite> SELECT 0.1 + 0.2 = 0.3 AS exact;
exact
-----
0
```

**SQLite has no decimal type.** If you keep money in SQLite, keep it as an integer number of cents
and divide when you print — which is good advice on every engine and the only correct answer on
this one.

## The fix inside SQLite: a STRICT table

Since version 3.37, released in 2021, a table may be declared `STRICT`, and then the declared type
is enforced:

```
sqlite> CREATE TABLE order_lines_strict (order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, quantity INTEGER NOT NULL CHECK (quantity > 0), unit_price TEXT NOT NULL, PRIMARY KEY (order_id, product_id)) STRICT;
sqlite> INSERT INTO order_lines_strict VALUES (5, 2, 'three', '189.00');
Error: stepping, cannot store TEXT value in INTEGER column order_lines_strict.quantity (19)
```

The same insert is now refused, with the column named. A `STRICT` table accepts only `INT`,
`INTEGER`, `REAL`, `TEXT`, `BLOB` and `ANY` as declared types — which is why `unit_price` above is
`TEXT` rather than `NUMERIC(10,2)`: there is no decimal to declare, and the honest options are
text or cents in an integer.

**Write `STRICT` on every new SQLite table.** It costs one word, it is not the default only
because thirty years of existing databases depend on the old behaviour, and the failure it
prevents is silent.

## MySQL, MariaDB, and the mode that used to be off

MySQL refused the string above, and it has not always. Until MySQL 5.7, the default allowed a
value that did not fit to be **coerced and stored with a warning** — `'three'` became `0`, an
over-long string was truncated, an invalid date became `0000-00-00`. That behaviour is the origin
of most of MySQL's reputation on this subject, and it is controlled by a variable rather than
being fixed in the engine:

```
mysql> SELECT @@sql_mode\G
*************************** 1. row ***************************
@@sql_mode: ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
```

```
MariaDB [shop]> SELECT @@sql_mode\G
*************************** 1. row ***************************
@@sql_mode: STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
```

Both ship with `STRICT_TRANS_TABLES`, so a fresh install of either refuses the string above — and
both can be turned back off, per session, per connection or in a configuration file. On a system
you did not set up, this variable is worth reading rather than assuming.

Put the two lists side by side and one word is in MySQL's and not MariaDB's: `ONLY_FULL_GROUP_BY`.
Lesson 6 said that every column in the `SELECT` list must be grouped or aggregated. That rule is
the engine's to enforce, and here the two disagree.
This query breaks the rule, and Recife has two customers:

```
shop=# SELECT city, name, count(*) FROM customers GROUP BY city;
ERROR:  column "customers.name" must appear in the GROUP BY clause or be used in an aggregate function
LINE 1: SELECT city, name, count(*) FROM customers GROUP BY city;
                     ^
```

```
mysql> SELECT city, name, count(*) FROM customers GROUP BY city;
ERROR 1055 (42000) at line 1: Expression #2 of SELECT list is not in GROUP BY clause and contains nonaggregated column 'shop.customers.name' which is not functionally dependent on columns in GROUP BY clause; this is incompatible with sql_mode=only_full_group_by
```

```
MariaDB [shop]> SELECT city, name, count(*) FROM customers GROUP BY city;
+-----------+--------------+----------+
| city      | name         | count(*) |
+-----------+--------------+----------+
| NULL      | Elisa Fontes |        1 |
| Curitiba  | Diego Alves  |        1 |
| Recife    | Ana Ribeiro  |        2 |
| Sao Paulo | Bruno Costa  |        1 |
+-----------+--------------+----------+
```

```
sqlite> SELECT city, name, count(*) FROM customers GROUP BY city;
city       name          count(*)
---------  ------------  --------
           Elisa Fontes  1       
Curitiba   Diego Alves   1       
Recife     Ana Ribeiro   2       
Sao Paulo  Bruno Costa   1       
```

Recife's row says `Ana Ribeiro` and `2`. There are two customers in Recife and the engine picked
one of them — not the first, not the largest, not documented; whichever row the scan happened to
hold. Carla Meneses has vanished from a report that looks complete.

That is the shape of this whole section. **The strict engine gives you an error message; the
lenient one gives you a plausible number.** Which of those you would rather debug at four in the
afternoon is the entire argument.

## The four, ranked

| | refuses a bad value | refuses a bare column in `GROUP BY` | exact decimals |
|---|---|---|---|
| PostgreSQL | always | always | yes |
| MySQL 8 | by default, `sql_mode` can disable | by default, `sql_mode` can disable | yes |
| MariaDB 10.11 | by default, `sql_mode` can disable | **no** | yes |
| SQLite | only in a `STRICT` table | no | **no** |

Two habits fall out of it, and they are worth carrying whatever you end up on. On MySQL or
MariaDB, **read `@@sql_mode` on a system you did not set up** — it is one query and it tells you
which of these two columns you are living in. On SQLite, **write `STRICT`, and keep money in
cents.**
