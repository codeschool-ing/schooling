---
title: Where the SQL itself differs
version: 1
---

The last two sections were about behaviour that looks identical and is not. This one is the
ordinary kind of difference: syntax that is simply spelled differently, which you look up once and
then know. It is a shorter list than people expect, and three items on it are traps rather than
lookups.

## The three that bite

**`||` is not concatenation on MySQL or MariaDB.** It is logical OR, and it does not fail:

```
shop=# SELECT 5 / 2 AS half, 'MN' || '-330' AS sku;
 half |  sku   
------+--------
    2 | MN-330
(1 row)
```

```
mysql> SELECT 5 / 2 AS half, 'MN' || '-330' AS sku;
+--------+-----+
| half   | sku |
+--------+-----+
| 2.5000 |   1 |
+--------+-----+
```

```
sqlite> SELECT 5 / 2 AS half, 'MN' || '-330' AS sku;
half  sku   
----  ------
2     MN-330
```

`'MN' || '-330'` came back as `1`. Both strings were read as numbers, `'-330'` is not zero, so the
OR is true. No error, no warning in the result — a `sku` column full of `1`. `CONCAT('MN','-330')`
is the portable spelling and works on all four.

**`5 / 2` is integer division on PostgreSQL and SQLite, and decimal on MySQL and MariaDB.** Two
against two point five, from the same expression. Where it matters — an average, a percentage, a
per-unit price — write the division so the answer does not depend on the engine: multiply by
`1.0`, or cast. `5 * 1.0 / 2` is 2.5 everywhere.

**A foreign key gets an index on MySQL and MariaDB, and does not on PostgreSQL.** `orders`
declares `customer_id` as a foreign key and nothing else. Here is what each engine built:

```
mysql> SHOW CREATE TABLE orders\G
*************************** 1. row ***************************
       Table: orders
Create Table: CREATE TABLE `orders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_id` int NOT NULL,
  `ordered_on` date NOT NULL DEFAULT (curdate()),
  `status` varchar(10) NOT NULL DEFAULT 'placed',
  PRIMARY KEY (`id`),
  KEY `customer_id` (`customer_id`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `orders_chk_1` CHECK ((`status` in (_latin1'placed',_latin1'shipped',_latin1'cancelled')))
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
```

```
shop=# \d orders
                            Table "public.orders"
   Column    |  Type   | Collation | Nullable |           Default            
-------------+---------+-----------+----------+------------------------------
 id          | integer |           | not null | generated always as identity
 customer_id | integer |           | not null | 
 ordered_on  | date    |           | not null | CURRENT_DATE
 status      | text    |           | not null | 'placed'::text
Indexes:
    "orders_pkey" PRIMARY KEY, btree (id)
Check constraints:
    "orders_status_check" CHECK (status = ANY (ARRAY['placed'::text, 'shipped'::text, 'cancelled'::text]))
Foreign-key constraints:
    "orders_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT
Referenced by:
    TABLE "order_lines" CONSTRAINT "order_lines_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
```

`KEY customer_id (customer_id)` on one; under `Indexes:` on the other, only the primary key.
MySQL and MariaDB create that index because InnoDB needs it to check the constraint;
PostgreSQL does not, and leaves it to you. This is the single most common missing index in a
PostgreSQL schema written by somebody who learned on MySQL — lesson 9's rule applies and nothing
is added for you, so `CREATE INDEX ON orders (customer_id)` is yours to write.

## The lookups

| | PostgreSQL | MySQL / MariaDB | SQLite |
|---|---|---|---|
| auto-numbered key | `GENERATED ALWAYS AS IDENTITY` | `AUTO_INCREMENT` | `INTEGER PRIMARY KEY` |
| concatenate | `\|\|` or `concat()` | `concat()` only | `\|\|` or `concat()` |
| quote an identifier | `"orders"` | `` `orders` `` | either |
| current date | `current_date` | `curdate()`, `current_date` | `date('now')` |
| limit rows | `LIMIT n OFFSET m` | `LIMIT m, n` or `LIMIT n OFFSET m` | `LIMIT n OFFSET m` |
| insert or update | `ON CONFLICT … DO UPDATE` | `ON DUPLICATE KEY UPDATE` | `ON CONFLICT … DO UPDATE` |
| case conversion | `lower()`, `upper()` | same | same |
| describe a table | `\d orders` | `DESCRIBE orders` | `.schema orders` |
| a boolean | `boolean`, `true`/`false` | `TINYINT(1)`, `1`/`0` | integer `1`/`0` |

The boolean row is worth a sentence. MySQL and MariaDB accept the words `TRUE` and `FALSE` and
store them as `1` and `0` in a one-byte integer; a driver hands you back a number, and code that
tests `=== true` in a language with strict equality will be wrong. SQLite is the same, without
even the alias in the column type. PostgreSQL has a real `boolean` and a real three-valued
`NULL`.

## `RETURNING`, which three of the four have

Lesson 11 used `RETURNING` to get a generated key back in the same round trip as the insert:

```
shop=# INSERT INTO customers (name, email, city) VALUES ('Felipe Nunes', 'felipe@example.com', 'Recife') RETURNING id;
 id 
----
  6
(1 row)

INSERT 0 1
```

```
sqlite> INSERT INTO customers (name, email, city) VALUES ('Felipe Nunes', 'felipe@example.com', 'Recife') RETURNING id;
id
--
6
```

```
MariaDB [shop]> INSERT INTO customers (name, email, city) VALUES ('Felipe Nunes', 'felipe@example.com', 'Recife') RETURNING id;
+----+
| id |
+----+
|  6 |
+----+
```

```
mysql> INSERT INTO customers (name, email, city) VALUES ('Felipe Nunes', 'felipe@example.com', 'Recife') RETURNING id;
ERROR 1064 (42000) at line 1: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'RETURNING id' at line 1
```

PostgreSQL has had it since 8.2, SQLite since 3.35 and MariaDB since 10.5. MySQL does not have it
at all, and the substitute is `LAST_INSERT_ID()` on the same connection — which works for one row
and has nothing to give you for a multi-row insert. This is a real MariaDB-against-MySQL
difference and the next section is about how many of those there are.

## Transactional DDL, which two of the four have

Lesson 8 said a transaction is all or nothing. Whether that covers `ALTER TABLE` is an engine
decision. Both of these ran `BEGIN`, added a `phone` column and then `ROLLBACK`:

```
shop=# SELECT column_name FROM information_schema.columns WHERE table_name = 'customers';
 column_name 
-------------
 id
 name
 email
 city
(4 rows)
```

```
mysql> DESCRIBE customers;
+-------+--------------+------+-----+---------+----------------+
| Field | Type         | Null | Key | Default | Extra          |
+-------+--------------+------+-----+---------+----------------+
| id    | int          | NO   | PRI | NULL    | auto_increment |
| name  | varchar(120) | NO   |     | NULL    |                |
| email | varchar(120) | NO   | UNI | NULL    |                |
| city  | varchar(120) | YES  |     | NULL    |                |
| phone | varchar(30)  | YES  |     | NULL    |                |
+-------+--------------+------+-----+---------+----------------+
```

`phone` is gone on PostgreSQL and present on MySQL. MySQL and MariaDB **commit implicitly** before
and after every DDL statement, so `ROLLBACK` had nothing left to undo. PostgreSQL and SQLite put
DDL inside the transaction like anything else.

That matters for lesson 11's migrations, and it is the reason the advice there differed by engine.
A PostgreSQL migration of six `ALTER TABLE`s either happens or does not. The same migration on
MySQL can stop after the third, leaving a schema that is neither version — so a migration for
MySQL is written one reversible step at a time, and the tool has to be able to resume.

## How to hold all of this

Not by memorising it. Two habits cover the whole section:

**Write the portable spelling when it costs nothing.** `concat()` over `||`, `LIMIT n OFFSET m`
over `LIMIT m, n`, an explicit `1.0` in a division. You lose nothing and the code stops caring.

**When it costs something, write the engine's own and say so.** `ON CONFLICT … DO UPDATE` is
clearer than anything portable, and a comment naming the engine is cheaper than an abstraction
that hides which one you are on. Lesson 11's query builders are where that lives in an
application.
