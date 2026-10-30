---
title: Two databases, one query
version: 1
---

**A three-part name, `database.schema.table`, is how a query in one database reads a table in
another**, and it is the habit Azure SQL Database breaks and Managed Instance keeps. Quitanda's
deliveries live in a database of their own, written by the couriers' app, and the support screen wants
an order and its delivery on one line. On an instance that is one `JOIN`.

Start SQL Server in `~/azure` and, in a new terminal, set up the function from lesson 8 again:

```sh
docker compose --profile sql up -d
sql() { docker compose exec -T sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P Quitanda-Lab-2026 -C -W -s '|' "$@"; }
```

**The container started empty, so build the orders again** from the `orders.sql` you saved in lesson
8, and then the deliveries. Save this as `~/azure/delivery.sql`: a second database, filled from the
first by a three-part name, with a delivery for every order of the first day:

`delivery.sql`:

```sql
CREATE DATABASE delivery;
GO
USE delivery;
CREATE TABLE dbo.deliveries (
  order_id     int PRIMARY KEY,
  courier      varchar(20) NOT NULL,
  delivered_at datetime2(0) NOT NULL
);
INSERT dbo.deliveries
SELECT order_id, CONCAT('courier-', order_id % 40), DATEADD(minute, 50, placed_at)
FROM quitanda.dbo.orders WHERE placed_at < '2026-01-02';
SELECT COUNT(*) AS deliveries FROM dbo.deliveries;
GO
```

```
ana@laptop:~/azure$ sql < orders.sql
Changed database context to 'quitanda'.

(100000 rows affected)
orders
------
100000

(1 rows affected)
ana@laptop:~/azure$ sql < delivery.sql
Changed database context to 'delivery'.

(287 rows affected)
deliveries
----------
287

(1 rows affected)
```

**The `INSERT` already crossed the boundary**: it ran in `delivery` and read `quitanda.dbo.orders`. The
support screen's query goes the other way, from `quitanda`, which `-d` makes the current database:

```
ana@laptop:~/azure$ sql -d quitanda -Q "SELECT TOP (3) o.order_id, o.total_cents, d.courier, d.delivered_at FROM dbo.orders o JOIN delivery.dbo.deliveries d ON d.order_id = o.order_id ORDER BY o.order_id"
order_id|total_cents|courier|delivered_at
--------|-----------|-------|------------
1|1537|courier-1|2026-01-01 00:55:00
2|1574|courier-2|2026-01-01 01:00:00
3|1611|courier-3|2026-01-01 01:05:00

(3 rows affected)
```

## What Azure SQL Database answers instead

**Azure SQL Database refuses that query**: a three-part name may only name the current database, and
`delivery.dbo.deliveries` names another. The documentation lists it among the differences from SQL
Server, and it was not run here, because there is no Azure SQL Database in this course; there is no
transcript of the refusal. The two databases may sit on the same logical server and it changes nothing,
since the logical server is a name and not an instance, as lesson 8 showed.

What a company does about it, on Azure SQL Database, is one of three things, each a piece of work:

- **put the two into one database**, as two schemas, `orders.orders` and `delivery.deliveries`, which
  is the clean answer when one team owns both;
- **query from the application**, reading each database with its own connection and joining in code,
  which moves the join out of the engine and usually makes it slower;
- **an elastic query**, an external table in one database that points at a table in the other, a
  feature of Azure SQL Database with limits of its own, to be read in the documentation before
  anything relies on it.

**On Managed Instance none of that is needed**, which is the point of this lesson in one query. The
`JOIN` above runs there unchanged, because the two databases are in one instance, exactly as they are
in this container.
