---
title: Case, collation, and a UNIQUE that is not the one you asked for
version: 1
---

The shop's `customers.email` is `NOT NULL UNIQUE`. Here is the same lookup on three engines, with
the address typed in capitals:

```
shop=# SELECT id, email FROM customers WHERE email = 'ANA@EXAMPLE.COM';
 id | email 
----+-------
(0 rows)
```

```
sqlite> SELECT id, email FROM customers WHERE email = 'ANA@EXAMPLE.COM';
```

```
mysql> SELECT id, email FROM customers WHERE email = 'ANA@EXAMPLE.COM';
+----+-----------------+
| id | email           |
+----+-----------------+
|  1 | ana@example.com |
+----+-----------------+
```

Two engines found nothing; one found Ana. Nobody wrote a `lower()` anywhere, and this is not a
setting somebody turned on — it is the default.

## Why

Every text column has a **collation**: the rule for comparing and sorting its values. MySQL and
MariaDB pick a case-insensitive one by default, and the name says so if you know where to look:

```
mysql> SELECT @@collation_database AS collation_database;
+--------------------+
| collation_database |
+--------------------+
| utf8mb4_0900_ai_ci |
+--------------------+
```

The suffix is the specification. `ai` is **accent-insensitive**; `ci` is **case-insensitive**.
`utf8mb4_0900_ai_ci` therefore says that `ana`, `ANA` and `Ána` are one string for every purpose
the engine has — comparison, `ORDER BY`, `GROUP BY`, `DISTINCT`, and the index behind a `UNIQUE`
constraint.

MariaDB's default collation differs in name and generation from MySQL's but is case-insensitive in
the same way and for the same reason: the two engines inherited the choice from the era when
`VARCHAR` mostly held names people typed.

PostgreSQL and SQLite compare text **byte for byte** unless told otherwise, which is why both
returned nothing.

## What it means, which is more than "case"

A case-insensitive collation reaches further than `WHERE`. It changes what `UNIQUE` promises.

On MySQL and MariaDB, `email VARCHAR(120) UNIQUE` refuses `ANA@EXAMPLE.COM` when
`ana@example.com` already exists, because to the index they are the same value. On PostgreSQL and
SQLite it accepts both, and you have two accounts for one person.

**Both behaviours are defensible and the wrong one is the one you did not expect.** An address is
case-insensitive in practice, so MySQL's default happens to be right there. A password hash, a
base64 token, an API key or a file path is not, and the same default silently makes `AbC` and `abc`
the same key.

## What to do about it

**On MySQL or MariaDB, declare the collation on columns where case matters.** `VARCHAR(64)
COLLATE utf8mb4_bin` on a token column is one clause and it makes the comparison byte-for-byte. To
force a single comparison rather than the column, put the clause on the operand:

```
mysql> SELECT id, email FROM customers WHERE email COLLATE utf8mb4_bin = 'ANA@EXAMPLE.COM';
mysql> SELECT id, email FROM customers WHERE email COLLATE utf8mb4_bin = 'ana@example.com';
+----+-----------------+
| id | email           |
+----+-----------------+
|  1 | ana@example.com |
+----+-----------------+
```

The first finds nothing and the second finds Ana, which is what the other two engines did all
along.

**On PostgreSQL, if you want case-insensitive, ask for it.** Either store the address lowercased
on the way in, or index the expression — `CREATE UNIQUE INDEX ON customers (lower(email))`, which
is lesson 9's expression index doing exactly the job it was introduced for. There is also a
`citext` extension, and a `nondeterministic` collation since PostgreSQL 12; the lowercase index is
the one that needs nothing installed and whose behaviour is visible in the schema.

**On SQLite, `COLLATE NOCASE`** on the column or the comparison. It folds ASCII only — `Á` and
`á` are still different — which is a real limit worth knowing before you rely on it for names.

## The rule under all of it

**Never let the engine's default decide something the application cares about.** If two strings
must be the same value, say so in the schema; if they must be different, say that. The default is
a reasonable guess about text in general, and an application always knows more than that.

This is the same shape as the last section. The engine has an opinion, it applies it silently, and
the first person to notice is usually a user with two accounts.
