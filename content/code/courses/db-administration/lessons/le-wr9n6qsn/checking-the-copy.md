---
title: Checking the copy
version: 1
---

## What arrived

Before checking the values, look at what pgloader built:

```
ana@db:~$ psql legacy
legacy=# \dt legacy.*
         List of relations
 Schema |   Name    | Type  | Owner 
--------+-----------+-------+-------
 legacy | customers | table | ana
 legacy | orders    | table | ana
(2 rows)

legacy=# \d customers
                                           Table "legacy.customers"
   Column   |           Type           | Collation | Nullable |                    Default                    
------------+--------------------------+-----------+----------+-----------------------------------------------
 customerid | bigint                   |           | not null | nextval('customers_customerid_seq'::regclass)
 email      | character varying(255)   |           | not null | 
 fullname   | character varying(100)   |           | not null | 
 isactive   | boolean                  |           | not null | true
 birthdate  | date                     |           |          | 
 createdat  | timestamp with time zone |           | not null | 
Indexes:
    "idx_16470_primary" PRIMARY KEY, btree (customerid)
    "idx_16470_customers_email" UNIQUE, btree (email)
Referenced by:
    TABLE "orders" CONSTRAINT "orders_customer_fk" FOREIGN KEY (customerid) REFERENCES customers(customerid)

legacy=# \d orders
                                         Table "legacy.orders"
   Column   |           Type           | Collation | Nullable |                 Default                 
------------+--------------------------+-----------+----------+-----------------------------------------
 orderid    | bigint                   |           | not null | nextval('orders_orderid_seq'::regclass)
 customerid | bigint                   |           | not null | 
 status     | orders_status            |           | not null | 'new'::orders_status
 totalcents | bigint                   |           | not null | 
 shippedat  | timestamp with time zone |           |          | 
 note       | character varying(200)   |           | not null | ''::character varying
Indexes:
    "idx_16476_primary" PRIMARY KEY, btree (orderid)
    "idx_16476_orders_customer" btree (customerid)
Foreign-key constraints:
    "orders_customer_fk" FOREIGN KEY (customerid) REFERENCES customers(customerid)

legacy=# SHOW search_path;
  search_path   
----------------
 public, legacy
(1 row)

legacy=# SELECT customerid, fullname, birthdate, createdat FROM customers ORDER BY customerid LIMIT 3;
 customerid |     fullname     | birthdate  |       createdat        
------------+------------------+------------+------------------------
          1 | Zoë Customer 1   | 1960-02-07 | 2024-01-01 12:00:00-03
          2 | Ana Customer 2   | 1960-03-15 | 2024-01-01 15:00:00-03
          3 | Mário Customer 3 | 1960-04-21 | 2024-01-01 18:00:00-03
(3 rows)
```

Most of the first section's list is visible in those two descriptions:

- **The tables are in a schema called `legacy`**, named after the MySQL database, and pgloader set
  the database's `search_path` to `public, legacy` so that unqualified names still find them. A
  role connecting with its own `search_path`, or code that writes `public.customers`, will not.
- `INT UNSIGNED` became `bigint`, the only signed type wide enough for every value it allowed.
- `TINYINT(1)` became `boolean`, `ENUM` became a type of its own, `orders_status`, and
  `AUTO_INCREMENT` became a sequence behind a default.
- `birthdate` is nullable now, and `shippedat` too: the zero dates had to go somewhere.
- The indexes are called `idx_`, a number taken from the table's internal id, and the MySQL name,
  so they are named differently every time the migration runs. Rename them in a script
  if anything refers to an index by name.
- **`createdat` became `timestamp with time zone`**, and `12:00:00` became `12:00:00-03`. A MySQL
  `DATETIME` has no zone, so it was read in this server's `TimeZone`, which is São Paulo's. If the
  application had written those values in UTC, every one of them is now three hours wrong, and
  nothing will ever say so. Which zone the old values were written in is a question for the
  application's owners, asked before the migration.

## Counting and hashing

A tool's summary says what the tool did. **A check says what the target holds**, and it is written
by you, in both engines, so that it does not share the tool's mistakes. Two numbers per table do
most of the work: how many rows, and a checksum over all of them.

The checksum is an `md5` of every row turned into one line of text, the lines joined in id order.
**The hard part is the text.** A MySQL row and its PostgreSQL copy print differently even when they
mean the same thing: `1` against `t` for a flag, a zero date against NULL, `2024-01-01 12:00:00`
against `2024-01-01 12:00:00-03`. So each side's query spells every column out in one agreed form,
and each of those spellings is a decision about what the migration was supposed to do.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 292\" role=\"img\" aria-label=\"The same customer as MySQL stores it and as PostgreSQL stores it, each rendered by its own query into one identical line of text, and the lines of a table hashed into one checksum.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"320\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">in MySQL</text><text x=\"34\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">IsActive</text><text x=\"130\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">1</text><text x=\"34\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">BirthDate</text><text x=\"130\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">0000-00-00</text><text x=\"34\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">CreatedAt</text><text x=\"130\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">2024-01-02 06:00:00</text><line x1=\"180\" y1=\"120\" x2=\"270.0\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><rect x=\"380\" y=\"16\" width=\"320\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"394\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">in PostgreSQL</text><text x=\"394\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">isactive</text><text x=\"490\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">t</text><text x=\"394\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">birthdate</text><text x=\"490\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">NULL</text><text x=\"394\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">createdat</text><text x=\"490\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">2024-01-02 06:00:00-03</text><line x1=\"540\" y1=\"120\" x2=\"450.0\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><rect x=\"20\" y=\"166\" width=\"680\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the agreed spelling: one line per row, the same on both sides</text><text x=\"360\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">7|customer7@example.com|Mário Customer 7|1|\\N|2024-01-02 06:00:00</text><line x1=\"360\" y1=\"226\" x2=\"360\" y2=\"256\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"360\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">md5 of every line, joined in id order: one checksum per table</text></svg>", "caption": "Two engines, two representations of row 7, one line of text. The checksum compares the lines, so each side has to spell the row the same way."}
```

Save this as `check-mysql.sql`:

```sql
-- check-mysql.sql: a count and a checksum per table, on the MySQL side.
-- Run it with: sudo mysql -t legacy < check-mysql.sql
SET SESSION group_concat_max_len = 1024 * 1024 * 64;

SELECT 'customers' AS tbl, COUNT(*) AS n_rows,
       MD5(GROUP_CONCAT(CONCAT_WS('|', CustomerID, Email, FullName, IsActive,
                                  IF(BirthDate = 0, '\\N', BirthDate),
                                  CreatedAt)
                        ORDER BY CustomerID SEPARATOR '\n')) AS checksum
FROM Customers
UNION ALL
SELECT 'orders', COUNT(*),
       MD5(GROUP_CONCAT(CONCAT_WS('|', OrderID, CustomerID, Status, TotalCents,
                                  IF(ShippedAt = 0, '\\N', ShippedAt), Note)
                        ORDER BY OrderID SEPARATOR '\n'))
FROM Orders;
```

and this as `check-pg.sql`:

```sql
-- check-pg.sql: the same count and checksum, on the PostgreSQL side.
-- Run it with: psql legacy -f check-pg.sql
SELECT 'customers' AS tbl, count(*) AS n_rows,
       md5(string_agg(concat_ws('|', customerid, email, fullname, isactive::int,
                                coalesce(birthdate::text, '\N'),
                                to_char(createdat, 'YYYY-MM-DD HH24:MI:SS')),
                      E'\n' ORDER BY customerid)) AS checksum
FROM customers
UNION ALL
SELECT 'orders', count(*),
       md5(string_agg(concat_ws('|', orderid, customerid, status, totalcents,
                                coalesce(to_char(shippedat, 'YYYY-MM-DD HH24:MI:SS'), '\N'),
                                note),
                      E'\n' ORDER BY orderid))
FROM orders;
```

Read the two side by side. `IF(BirthDate = 0, '\\N', BirthDate)` and `coalesce(birthdate::text,
'\N')` both say a missing date is written `\N`. `to_char(createdat, …)` drops the time zone
PostgreSQL added, because the MySQL value never had one. `isactive::int` writes the boolean as `1`
or `0`, the way MySQL stores it.

```
ana@db:~$ sudo mysql -t legacy < check-mysql.sql
+-----------+--------+----------------------------------+
| tbl       | n_rows | checksum                         |
+-----------+--------+----------------------------------+
| customers |   2001 | c370102af0b5fcd7c3901ba45dbe9440 |
| orders    |  10000 | fa25ee5b819306900b7daf3738251f51 |
+-----------+--------+----------------------------------+
ana@db:~$ psql legacy -f check-pg.sql
    tbl    | n_rows |             checksum             
-----------+--------+----------------------------------
 customers |   2001 | e5a659f63d17dfbe7278d837079c7365
 orders    |  10000 | fa25ee5b819306900b7daf3738251f51
(2 rows)
```

**The counts agree, and that proves less than it looks.** Every row arrived. `orders` agrees in its
checksum too, so every value in it says the same thing on both sides, zero dates included.
`customers` does not.

## Finding the row

A checksum over a whole table says that something differs and not where. **Narrow it by ranges**:
the same checksum, grouped by blocks of 500 ids, run on both sides. The first attempt at that on the
MySQL side went wrong in a way worth seeing, so it is kept here with the repair:

```
ana@db:~$ sudo mysql legacy
mysql> SELECT CustomerID DIV 500 AS block, MD5(GROUP_CONCAT(CONCAT_WS('|', CustomerID, Email, FullName, IsActive, IF(BirthDate = 0, '\\N', BirthDate), CreatedAt) ORDER BY CustomerID SEPARATOR '\n')) AS checksum FROM Customers GROUP BY block;
+-------+----------------------------------+
| block | checksum                         |
+-------+----------------------------------+
|     0 | da7f23b476ff2c082819017f7bfa4d6f |
|     1 | a414f7848affb5e5a5dc240197790cec |
|     2 | e4394d5a5cb083c89321d012c064dfb6 |
|     3 | de1d8f8d3a371aeb0dbbd86a2075706c |
|     4 | 42620e66e87e7bdae51f19cf6ea938b4 |
+-------+----------------------------------+
5 rows in set, 4 warnings (0.00 sec)

mysql> SHOW WARNINGS;
+---------+------+----------------------------------+
| Level   | Code | Message                          |
+---------+------+----------------------------------+
| Warning | 1260 | Row 14 was cut by GROUP_CONCAT() |
| Warning | 1260 | Row 28 was cut by GROUP_CONCAT() |
| Warning | 1260 | Row 41 was cut by GROUP_CONCAT() |
| Warning | 1260 | Row 54 was cut by GROUP_CONCAT() |
+---------+------+----------------------------------+
4 rows in set (0.00 sec)

mysql> SET SESSION group_concat_max_len = 1024 * 1024 * 64;
Query OK, 0 rows affected (0.00 sec)

mysql> SELECT CustomerID DIV 500 AS block, MD5(GROUP_CONCAT(CONCAT_WS('|', CustomerID, Email, FullName, IsActive, IF(BirthDate = 0, '\\N', BirthDate), CreatedAt) ORDER BY CustomerID SEPARATOR '\n')) AS checksum FROM Customers GROUP BY block;
+-------+----------------------------------+
| block | checksum                         |
+-------+----------------------------------+
|     0 | a8621aa8a5b2fec81b7569b3a5f93aee |
|     1 | 81e2673ee6df88cb7e782d1ebd407c22 |
|     2 | 5a0f84a30fd20aae3d7edb4268332fa8 |
|     3 | 3ec854b312efbc543e7fdd5767e095c1 |
|     4 | 42620e66e87e7bdae51f19cf6ea938b4 |
+-------+----------------------------------+
5 rows in set (0.00 sec)
```

**`GROUP_CONCAT` cut its result off at 1,024 bytes and said so only in a warning.** Four of the five
blocks got the checksum of a truncated string, and nothing on the screen looked wrong apart from
`4 warnings` in the line under the table. That is what the `SET SESSION group_concat_max_len` line
at the top of `check-mysql.sql` is for. After it, the same query gives different hashes for blocks
0 to 3, and those are the ones to compare with PostgreSQL's:

```
ana@db:~$ psql legacy
legacy=# SELECT customerid / 500 AS block, md5(string_agg(concat_ws('|', customerid, email, fullname, isactive::int, coalesce(birthdate::text, '\N'), to_char(createdat, 'YYYY-MM-DD HH24:MI:SS')), E'\n' ORDER BY customerid)) AS checksum FROM customers GROUP BY block ORDER BY block;
 block |             checksum             
-------+----------------------------------
     0 | a8621aa8a5b2fec81b7569b3a5f93aee
     1 | 81e2673ee6df88cb7e782d1ebd407c22
     2 | 5a0f84a30fd20aae3d7edb4268332fa8
     3 | 3ec854b312efbc543e7fdd5767e095c1
     4 | aa1ae73d2b751f85f0153771e2b38ba0
(5 rows)
```

Blocks 0 to 3 agree. Block 4, ids 2000 and up, does not, and it holds only two rows. Look
for what the PostgreSQL column cannot hold:

```
ana@db:~$ sudo mysql legacy
mysql> SELECT CustomerID, Email, IsActive FROM Customers WHERE CustomerID >= 2000 AND IsActive NOT IN (0, 1);
+------------+------------------+----------+
| CustomerID | Email            | IsActive |
+------------+------------------+----------+
|       2048 | flag@example.com |        2 |
+------------+------------------+----------+
1 row in set (0.00 sec)
```

**The flag of 2.** The application stored a 2 in a column it treated as yes or no, pgloader made it
`true`, and `true` is `1`. Nothing was lost that the application could see, because to it any
non-zero value meant active. So the copy is right, the check was wrong, and the fix is to write that
decision into the MySQL side: compare `IsActive <> 0`, which is 1 or 0, instead of the raw number.

```
ana@db:~$ sed -i 's/FullName, IsActive,/FullName, IsActive <> 0,/' check-mysql.sql
ana@db:~$ sudo mysql -t legacy < check-mysql.sql
+-----------+--------+----------------------------------+
| tbl       | n_rows | checksum                         |
+-----------+--------+----------------------------------+
| customers |   2001 | e5a659f63d17dfbe7278d837079c7365 |
| orders    |  10000 | fa25ee5b819306900b7daf3738251f51 |
+-----------+--------+----------------------------------+
```

Both checksums now agree with PostgreSQL's. The emoji in that same row came through byte for byte,
or the hash would still differ.

**That is the shape of every check on a real migration.** A difference is either damage, which you
fix in the migration, or a decision you had not written down, which you write into the check. Run
both files again after every rehearsal; on the night itself they are the evidence that the copy is
complete.
