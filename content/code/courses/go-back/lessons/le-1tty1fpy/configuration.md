---
title: The configuration and the queries
version: 1
---

Two files in `~/boxoffice` tell sqlc what to do. The configuration first:

```yaml
# boxoffice/sqlc.yaml
version: "2"
sql:
  - engine: postgresql
    schema: schema.sql
    queries: queries.sql
    gen:
      go:
        package: db
        out: internal/db
        sql_package: pgx/v5
```

Read it from the top: **one SQL "package" for PostgreSQL**, its tables in lesson 6's `schema.sql`, its
queries in `queries.sql`, and Go to be generated as a package called `db` in `internal/db`, using pgx
version 5 rather than `database/sql`. `internal/` is a directory name the go command treats specially:
code under it can only be imported from inside the module, so the generated package stays boxoffice's
own.

Then the queries, which are the four that lesson 6's `pgStore` sends, moved out of Go strings into a
file of their own:

```sql
-- boxoffice/queries.sql

-- name: ListEvents :many
SELECT id, name, seats, sold FROM events ORDER BY id;

-- name: GetEvent :one
SELECT id, name, seats, sold FROM events WHERE id = $1;

-- name: AddEvent :one
INSERT INTO events (name, seats) VALUES ($1, $2)
RETURNING id, name, seats, sold;

-- name: SellSeats :one
UPDATE events SET sold = sold + sqlc.arg(quantity)
WHERE id = sqlc.arg(id) AND seats - sold >= sqlc.arg(quantity)
RETURNING id, name, seats, sold;
```

**The comment above each query is not a comment to sqlc.** `-- name: SellSeats :one` gives the Go
function its name and says what it returns:

| annotation | the generated function returns |
|---|---|
| `:one` | one row as a struct, or `pgx.ErrNoRows` |
| `:many` | a slice of structs, empty when there are no rows |
| `:exec` | only an error |
| `:execrows` | the number of rows affected, and an error |

Parameters are `$1`, `$2` as in lesson 6, and sqlc names each one after the column it is compared with
or inserted into: `$1` in `GetEvent` becomes an argument called `id`. Where that would be unclear, as in
`SellSeats`, where the quantity is used twice and compared with an expression rather than a column,
**`sqlc.arg(quantity)` names it explicitly**, and the same name used twice is one parameter.

Nothing else is needed. `schema.sql` is the file lesson 6 ran with `psql`, unchanged; sqlc reads its
`CREATE TABLE` to learn the columns and their types, and ignores the `INSERT`.
