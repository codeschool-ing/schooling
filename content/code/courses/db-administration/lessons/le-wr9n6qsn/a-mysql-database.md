---
title: A MySQL database to move
version: 1
---

To migrate something you need something to migrate, and the course's `shop` is already in
PostgreSQL. So this section builds a second server beside it: **MySQL 8.0, installed from Ubuntu's
own packages on the same virtual machine**, holding a small database with every habit from the
section before. It is two tables, written the way an old MySQL application writes them.

```sh
sudo apt install -y mysql-server-8.0
```

The package starts the server and enables it, like PostgreSQL's did in lesson 3. MySQL's
administrator account on Ubuntu is `root`, and it authenticates the way PostgreSQL's peer rule
does: the operating-system user `root` gets in as the database user `root`, with no password. That
is why every `mysql` command in this lesson starts with `sudo`.

```
ana@db:~$ mysql --version
mysql  Ver 8.0.46-0ubuntu0.24.04.4 for Linux on x86_64 ((Ubuntu))
ana@db:~$ sudo mysql -e "SELECT @@version, @@sql_mode, @@collation_server\G"
*************************** 1. row ***************************
         @@version: 8.0.46-0ubuntu0.24.04.4
        @@sql_mode: ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
@@collation_server: utf8mb4_0900_ai_ci
```

Two of those values matter later. The **`sql_mode` is strict**: `NO_ZERO_DATE` and
`STRICT_TRANS_TABLES` mean a new MySQL 8 refuses to store a zero date. And the **collation is
`utf8mb4_0900_ai_ci`**, the accent- and case-insensitive one.

## The database

Save this as `legacy.sql`. It is the whole database, and it makes the same rows every time it runs:

```sql
-- legacy.sql: an old MySQL shop. Run it with: sudo mysql < legacy.sql
-- The application that wrote it ran with a lax sql_mode, which is how the
-- zero dates got in; this session does the same, so they get in here too.
SET NAMES utf8mb4;
SET SESSION sql_mode = 'NO_ENGINE_SUBSTITUTION';

CREATE DATABASE legacy CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE legacy;

CREATE TABLE Customers (
  CustomerID INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  Email      VARCHAR(255) NOT NULL,
  FullName   VARCHAR(100) NOT NULL,
  IsActive   TINYINT(1) NOT NULL DEFAULT 1,
  BirthDate  DATE NOT NULL DEFAULT '0000-00-00',
  CreatedAt  DATETIME NOT NULL,
  UNIQUE KEY customers_email (Email)
) ENGINE=InnoDB;

CREATE TABLE Orders (
  OrderID    INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  CustomerID INT UNSIGNED NOT NULL,
  Status     ENUM('new', 'paid', 'shipped', 'cancelled') NOT NULL DEFAULT 'new',
  TotalCents INT UNSIGNED NOT NULL,
  ShippedAt  DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  Note       VARCHAR(200) NOT NULL DEFAULT '',
  KEY orders_customer (CustomerID),
  CONSTRAINT orders_customer_fk FOREIGN KEY (CustomerID) REFERENCES Customers (CustomerID)
) ENGINE=InnoDB;

-- 2,000 customers and 10,000 orders, by arithmetic, so every run makes the
-- same rows. One customer in seven never gave a birth date; an order that has
-- not shipped carries the zero date, as the application wrote it.
SET SESSION cte_max_recursion_depth = 10000;

INSERT INTO Customers (Email, FullName, IsActive, BirthDate, CreatedAt)
WITH RECURSIVE n (i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n WHERE i < 2000)
SELECT CONCAT('customer', i, '@example.com'),
       CONCAT(ELT(1 + i % 4, 'João', 'Zoë', 'Ana', 'Mário'), ' Customer ', i),
       IF(i % 10 = 0, 0, 1),
       IF(i % 7 = 0, '0000-00-00', DATE('1960-01-01') + INTERVAL (i * 37) % 15000 DAY),
       TIMESTAMP('2024-01-01 09:00:00') + INTERVAL i * 3 HOUR
FROM n;

INSERT INTO Orders (CustomerID, Status, TotalCents, ShippedAt, Note)
WITH RECURSIVE n (i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n WHERE i < 10000)
SELECT 1 + (i * 7919) % 2000,
       ELT(1 + i % 4, 'new', 'paid', 'shipped', 'cancelled'),
       500 + (i * 37) % 50000,
       IF(i % 4 = 2, TIMESTAMP('2025-06-01 12:00:00') + INTERVAL i MINUTE, '0000-00-00 00:00:00'),
       IF(i % 50 = 0, 'leave at the door', '')
FROM n;

-- One row the application's own rules never meant to allow: a flag of 2,
-- and a name with a character outside the first 65,536 (an emoji, U+1F600).
INSERT INTO Customers (Email, FullName, IsActive, BirthDate, CreatedAt)
VALUES ('flag@example.com', CONCAT('Ana ', CONVERT(0xF09F9880 USING utf8mb4)), 2,
        '0000-00-00', '2025-03-01 10:00:00');
```

**The `SET SESSION sql_mode` line is how the old data got in.** The server refuses zero dates by
default, so an application that stored them ran with a lax mode of its own; the file does the same,
for its own session only. Databases like this one are common precisely because MySQL defaulted to
the lax mode until version 5.7.

`SET NAMES utf8mb4` says which character set the client is sending. Leave it out on a terminal whose
locale is not UTF-8 and the client announces `latin1`, the server stores each `ã` as two wrong
characters, and the migration then copies the damage faithfully.

```
ana@db:~$ sudo mysql < legacy.sql
ana@db:~$ sudo mysql legacy
mysql> SHOW TABLES;
+------------------+
| Tables_in_legacy |
+------------------+
| Customers        |
| Orders           |
+------------------+
2 rows in set (0.00 sec)

mysql> SELECT COUNT(*) FROM Customers;
+----------+
| COUNT(*) |
+----------+
|     2001 |
+----------+
1 row in set (0.00 sec)

mysql> SELECT COUNT(*) FROM Orders;
+----------+
| COUNT(*) |
+----------+
|    10000 |
+----------+
1 row in set (0.00 sec)

mysql> SELECT * FROM Customers LIMIT 3;
+------------+-----------------------+-------------------+----------+------------+---------------------+
| CustomerID | Email                 | FullName          | IsActive | BirthDate  | CreatedAt           |
+------------+-----------------------+-------------------+----------+------------+---------------------+
|          1 | customer1@example.com | Zoë Customer 1    |        1 | 1960-02-07 | 2024-01-01 12:00:00 |
|          2 | customer2@example.com | Ana Customer 2    |        1 | 1960-03-15 | 2024-01-01 15:00:00 |
|          3 | customer3@example.com | Mário Customer 3  |        1 | 1960-04-21 | 2024-01-01 18:00:00 |
+------------+-----------------------+-------------------+----------+------------+---------------------+
3 rows in set (0.00 sec)
```

**2,001 customers, not 2,000**: the generated ones and the odd row at the end of the file. The ids
are not 1 to 2001 either: MySQL hands out `AUTO_INCREMENT` values to a multi-row insert in batches,
leaves the unused ones as a gap, and the last row got 2048. The last section of this lesson shows
why that matters.

## Values the server will not name

The zero dates are in there, and MySQL's own strict mode will not let you write one down to look
for them:

```
ana@db:~$ sudo mysql legacy
mysql> SELECT COUNT(*) FROM Customers WHERE BirthDate = '0000-00-00';
ERROR 1525 (HY000): Incorrect DATE value: '0000-00-00'

mysql> SELECT COUNT(*) FROM Customers WHERE BirthDate = 0;
+----------+
| COUNT(*) |
+----------+
|      286 |
+----------+
1 row in set (0.00 sec)

mysql> SELECT COUNT(*) FROM Orders WHERE ShippedAt = 0;
+----------+
| COUNT(*) |
+----------+
|     7500 |
+----------+
1 row in set (0.01 sec)

mysql> INSERT INTO Customers (Email, FullName, BirthDate, CreatedAt) VALUES ('CUSTOMER1@example.com', 'Ana Again', '1990-05-04', NOW());
ERROR 1062 (23000): Duplicate entry 'CUSTOMER1@example.com' for key 'Customers.customers_email'
```

**The table holds values the server's current rules refuse.** Comparing with the number `0` finds
them where the literal date fails, and the counts are the ones the comments in `legacy.sql`
promised: one customer in seven with no birth date, and every order that has not shipped.

The last line is the collation at work. `CUSTOMER1@example.com` differs from the existing
`customer1@example.com` only in case, and the `UNIQUE` key on `Email` refused it, because under
`utf8mb4_0900_ai_ci` those two strings are equal. Remember that refusal; the last section of this
lesson tries the same insert in PostgreSQL.
