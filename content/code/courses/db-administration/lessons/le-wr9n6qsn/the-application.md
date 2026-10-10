---
title: The application's SQL
version: 1
---

The data is across and checked. **The application is still speaking MySQL**, and every query it
sends was written by people testing against MySQL's answers. Some of those queries now fail loudly,
which is the good case. The others run and return something different, which is the case that
reaches customers.

## The same questions, two answers

```
ana@db:~$ sudo mysql legacy
mysql> SELECT 5 / 2, 'abc' = 'ABC', IFNULL(NULL, 'none'), CONCAT('a', NULL);
+--------+---------------+----------------------+-------------------+
| 5 / 2  | 'abc' = 'ABC' | IFNULL(NULL, 'none') | CONCAT('a', NULL) |
+--------+---------------+----------------------+-------------------+
| 2.5000 |             1 | none                 | NULL              |
+--------+---------------+----------------------+-------------------+
1 row in set (0.00 sec)

mysql> SELECT CustomerID FROM Customers WHERE Email = 'CUSTOMER1@EXAMPLE.COM';
+------------+
| CustomerID |
+------------+
|          1 |
+------------+
1 row in set (0.00 sec)

mysql> SELECT `Email` FROM Customers ORDER BY CustomerID LIMIT 2, 1;
+-----------------------+
| Email                 |
+-----------------------+
| customer3@example.com |
+-----------------------+
1 row in set (0.00 sec)
```

```
ana@db:~$ psql legacy
legacy=# SELECT 5 / 2, 'abc' = 'ABC', coalesce(NULL, 'none'), concat('a', NULL), 'a' || NULL;
 ?column? | ?column? | coalesce | concat | ?column? 
----------+----------+----------+--------+----------
        2 | f        | none     | a      | 
(1 row)

legacy=# SELECT IFNULL(NULL, 'none');
ERROR:  function ifnull(unknown, unknown) does not exist
LINE 1: SELECT IFNULL(NULL, 'none');
               ^
HINT:  No function matches the given name and argument types. You might need to add explicit type casts.

legacy=# SELECT customerid FROM customers WHERE email = 'CUSTOMER1@EXAMPLE.COM';
 customerid 
------------
(0 rows)

legacy=# SELECT `email` FROM customers;
ERROR:  syntax error at or near "FROM"
LINE 1: SELECT `email` FROM customers;
                       ^

legacy=# SELECT email FROM customers ORDER BY customerid LIMIT 2, 1;
ERROR:  LIMIT #,# syntax is not supported
LINE 1: SELECT email FROM customers ORDER BY customerid LIMIT 2, 1;
                                                        ^
HINT:  Use separate LIMIT and OFFSET clauses.

legacy=# SELECT email FROM customers ORDER BY customerid LIMIT 1 OFFSET 2;
         email         
-----------------------
 customer3@example.com
(1 row)

legacy=# SELECT "CustomerID" FROM customers LIMIT 1;
ERROR:  column "CustomerID" does not exist
LINE 1: SELECT "CustomerID" FROM customers LIMIT 1;
               ^
HINT:  Perhaps you meant to reference the column "customers.customerid".

legacy=# SELECT CustomerID FROM Customers LIMIT 1;
 customerid 
------------
          1
(1 row)

legacy=# \q
```

Go through them in order, because **the quiet ones are at the top**:

- `5 / 2` is `2.5000` in MySQL and `2` in PostgreSQL, which divides integers as integers. An average
  computed that way loses its fraction with no error anywhere.
- `'abc' = 'ABC'` is `1` and `f`: the collation from the first section. The lookup by e-mail found
  customer 1 in MySQL and finds nobody in PostgreSQL.
- `CONCAT('a', NULL)` is NULL in MySQL. PostgreSQL's `concat` skips the NULL and returns `a`, and its
  `||` returns NULL. Same name, different function.
- `IFNULL` does not exist in PostgreSQL; `coalesce` exists in both and is the one to write.
- Backticks are MySQL's quotes for names. PostgreSQL uses double quotes for names, and a
  backtick is a syntax error.
- `LIMIT 2, 1` is MySQL's own form for "skip two, take one". `LIMIT 1 OFFSET 2` works in both.
- `"CustomerID"` in double quotes asks for a column with capitals, and there is none: pgloader
  folded every name. **The unquoted `CustomerID` works**, because PostgreSQL folds it to
  `customerid` before looking. An application that never quoted its names survives the folding;
  an ORM that quotes every name it generates does not, and its mapping has to change.

## The unique key that got weaker

In MySQL the `UNIQUE` key on `Email` refused `CUSTOMER1@example.com`, because the collation made it
equal to `customer1@example.com`. pgloader copied the key, and PostgreSQL compares exactly:

```
ana@db:~$ psql legacy
legacy=# INSERT INTO customers (email, fullname, createdat) VALUES ('CUSTOMER1@example.com', 'Ana Again', now()) RETURNING customerid;
 customerid 
------------
       2049
(1 row)

INSERT 0 1

legacy=# DELETE FROM customers WHERE email = 'CUSTOMER1@example.com';
DELETE 1

legacy=# CREATE UNIQUE INDEX customers_email_lower ON customers (lower(email));
CREATE INDEX

legacy=# INSERT INTO customers (email, fullname, createdat) VALUES ('CUSTOMER1@example.com', 'Ana Again', now());
ERROR:  duplicate key value violates unique constraint "customers_email_lower"
DETAIL:  Key (lower(email::text))=(customer1@example.com) already exists.

legacy=# \q
```

**The key had the same name and a weaker meaning**, and the first insert proved it by succeeding.
The index on `lower(email)` puts the old rule back, and the application's lookups have to ask for
`lower(email) = lower($1)` to use it. The `citext` extension, a case-insensitive text type, is the
other way to get the same rule. Either one is a decision somebody makes during the migration, or
it is a duplicate account somebody finds a month later.

The id the insert got back is also a check. It is 2049: not 2002, one past the row count, but one
past the highest id in the table, 2048, the odd row MySQL numbered after a gap. pgloader's `reset
sequences` did its job. A sequence left at 1 would have failed on the primary key instead.

## What the rest of the application needs

None of these is visible until the application runs against the new server:

| MySQL | PostgreSQL |
| --- | --- |
| `INSERT … ON DUPLICATE KEY UPDATE` | `INSERT … ON CONFLICT (…) DO UPDATE` |
| `GROUP_CONCAT(x)` | `string_agg(x, ',')` |
| `DATE_FORMAT(d, '%Y-%m')` | `to_char(d, 'YYYY-MM')` |
| `LAST_INSERT_ID()` | `INSERT … RETURNING id` |
| a `TINYINT(1)` compared with `= 1` | a `boolean`, compared with `= true` or used bare |

**So the migration is rehearsed with the application, not only with the data.** Run its test suite
against a migrated copy, then replay a day of its real queries if you can capture them, and fix
what fails before the night. Oracle's PL/SQL and SQL Server's T-SQL make this part larger: stored
procedures are a program in the source engine's language, and ora2pg converts some of it and leaves
the rest marked for a person.

## Tidying up

The `legacy` database can stay; nothing later in the course reads it. MySQL is a second server
using memory on a machine that the lessons after this one measure, so stop it and keep it from starting at
boot:

```
ana@db:~$ sudo systemctl disable --now mysql
Synchronizing state of mysql.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install disable mysql
Removed "/etc/systemd/system/multi-user.target.wants/mysql.service".
```

`sudo systemctl enable --now mysql` brings it back if you want to repeat any of this.
