---
title: What sqlc catches, and when
version: 1
---

The promise of section 02 was that the Go cannot drift from the SQL. The SQL itself can still be wrong,
and the interesting question is **when you find out: at `sqlc generate`, at `go build`, or when a
customer presses Buy.** Here is a typo, `sould` for `sold`, typed into the `SellSeats` query with the
configuration of section 04:

```
ana@vm:~/boxoffice$ sed -i 's/seats - sold >= sqlc.arg(quantity)/seats - sould >= sqlc.arg(quantity)/' queries.sql && sqlc generate && go build ./... && echo built
built
```

**sqlc generated, Go built, and nothing complained.** The typo is inside the `WHERE`, in an expression,
and sqlc's own analysis of the query did not check every name used there. The program started, and the
first purchase found it:

```
ana@vm:~/boxoffice$ curl -s --json '{"quantity": 2, "email": "ana@example.com"}' localhost:8080/events/1/tickets
{"type":"about:blank","title":"Internal Server Error","status":500}
ana@vm:~/boxoffice$ tail -2 .server.log
2026/10/16 20:08:24 unexpected error: ERROR: column "sould" does not exist (SQLSTATE 42703)
2026/10/16 20:08:24 POST /events/1/tickets 500 68B 2.732ms
```

PostgreSQL refused the statement with SQLSTATE `42703`, undefined column, and the customer got a 500.
That is a better place than a silently wrong answer, and a worse one than your own terminal.

## Asking the database

sqlc can do better if it is allowed to **ask PostgreSQL itself**. Given a database to connect to, it
prepares every query against it during `generate`, and PostgreSQL checks every name, every type and every
parameter exactly as it would at run time. That is one block more in the configuration:

```yaml
# boxoffice/sqlc.yaml
version: "2"
sql:
  - engine: postgresql
    schema: schema.sql
    queries: queries.sql
    database:
      uri: ${DATABASE_URL}
    gen:
      go:
        package: db
        out: internal/db
        sql_package: pgx/v5
```

`${DATABASE_URL}` is read from the environment, the same variable lesson 6 section 02 had you put in
`~/.profile`, so no address is written into the file. With it:

```
ana@vm:~/boxoffice$ sqlc generate
# package db
queries.sql:15:12: column "sould" does not exist
ana@vm:~/boxoffice$ sed -i 's/seats - sould/seats - sold/' queries.sql && sqlc generate && echo clean
clean
ana@vm:~/boxoffice$ sed -i 's/VALUES ($1, $2)/VALUES ($1)/' queries.sql && sqlc generate
# package db
queries.sql:10:27: INSERT has more target columns than expressions
ana@vm:~/boxoffice$ sed -i 's/VALUES ($1)/VALUES ($1, $2)/' queries.sql && sqlc generate && echo clean
clean
ana@vm:~/boxoffice$ env -u DATABASE_URL sqlc generate 2>&1 | head -2
# package db
queries.sql:1:1: failed to connect to `user=ana database=`: /var/run/postgresql/.s.PGSQL.5432 (/var/run/postgresql): server error: FATAL: database "ana" does not exist (SQLSTATE 3D000)
```

**The typo is now a `generate` error with its line and column**, `queries.sql:15:12`, before any Go is
built. A missing value in an `INSERT` is caught the same way. The last command shows the cost: **without a
database to ask, `generate` cannot run at all**, so the database must exist and must already have the
tables. In lesson 9, migrations make sure of that before anything else runs, and in a continuous
integration pipeline it means a PostgreSQL running beside the build.

## What it does not catch

Neither analysis knows what the query is for. A `WHERE seats - sold >= $1` written as `<=` is valid SQL,
generates clean code, and sells seats that do not exist, until the table's `CHECK` from lesson 6 refuses
the row. **sqlc checks that the SQL means something; only tests check that it means the right thing**,
and lesson 15 writes them against a real database for exactly this reason.
