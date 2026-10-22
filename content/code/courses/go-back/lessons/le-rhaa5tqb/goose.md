---
title: goose: migrations as numbered SQL files
version: 1
---

goose is two things: a command-line tool that applies migrations to a database, and a Go library that
does the same from inside a program. **The command-line tool first**, installed like sqlc in lesson 8,
at a pinned release:

```
ana@vm:~$ go install github.com/pressly/goose/v3/cmd/goose@v3.29.0
ana@vm:~$ goose --version
goose version: v3.29.0
...
ana@vm:~$ go install github.com/pressly/goose/v3/cmd/goose@v3.29.0
ana@vm:~$ goose --version
goose version: v3.29.0
```

The `...` stands for fifty-odd more download lines, cut here and nothing else: **the goose command
supports a dozen databases, and `go install` fetched a driver for each**, ClickHouse, MySQL, SQL Server
and SQLite among them. None of that reaches boxoffice, which will import only goose's library and the pgx
it already has; it is the price of a general-purpose tool on your laptop.

## Two migrations

Lesson 6's `schema.sql` becomes the first migration, and the table this lesson needs becomes the
second. They live in `~/boxoffice/migrations`, and **the number at the front of each name is its
version**:

```sql
-- boxoffice/migrations/00001_events.sql
-- +goose Up
CREATE TABLE events (
    id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name  text    NOT NULL UNIQUE CHECK (length(name) BETWEEN 1 AND 100),
    seats integer NOT NULL CHECK (seats > 0),
    sold  integer NOT NULL DEFAULT 0 CHECK (sold BETWEEN 0 AND seats)
);

INSERT INTO events (name, seats, sold) VALUES
    ('Jazz at the Docks', 120, 0),
    ('Chamber Choir', 80, 80);

-- +goose Down
DROP TABLE events;
```

```sql
-- boxoffice/migrations/00002_tickets.sql
-- +goose Up
CREATE TABLE tickets (
    id         integer     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id   integer     NOT NULL REFERENCES events (id),
    email      text        NOT NULL,
    quantity   integer     NOT NULL CHECK (quantity BETWEEN 1 AND 10),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX tickets_event_id ON tickets (event_id);

-- +goose Down
DROP TABLE tickets;
```

`-- +goose Up` and `-- +goose Down` are goose's markers, read by goose and comments to everybody else. The
first migration also inserts the two events every lesson has started with, because a migration is just
SQL and the rows are part of the starting state; a real service would keep test data out of its
migrations and seed it separately.

`tickets` records each sale: which event, who, how many and when. `REFERENCES events (id)` is a foreign
key, so a ticket can only point at an event that exists, and the `CHECK` repeats the API's limit of 10
per purchase as a rule the table keeps.

## Starting from an empty database

The database lesson 6 built by hand has the `events` table and no record of how it got there, so goose
would try to create it again and fail. **On a development machine the simplest way out is to start
again**; on a production database you would instead tell the tool that the first migration is already
applied. `schema.sql` is now history, so delete it:

```
ana@vm:~/boxoffice$ rm -f schema.sql && ls migrations
00001_events.sql
00002_tickets.sql
ana@vm:~/boxoffice$ dropdb boxoffice && createdb boxoffice
```

## Up, status, down

goose takes the directory, the database driver and the address, here from lesson 6's `DATABASE_URL`:

```
ana@vm:~/boxoffice$ goose -dir migrations postgres "$DATABASE_URL" status
2026/10/16 20:18:42     Applied At                  Migration
2026/10/16 20:18:42     =======================================
2026/10/16 20:18:42     Pending                  -- 00001_events.sql
2026/10/16 20:18:42     Pending                  -- 00002_tickets.sql
ana@vm:~/boxoffice$ goose -dir migrations postgres "$DATABASE_URL" up
2026/10/16 20:18:42 OK   00001_events.sql (6.63ms)
2026/10/16 20:18:42 OK   00002_tickets.sql (6.12ms)
2026/10/16 20:18:42 goose: successfully migrated database to version: 2
ana@vm:~/boxoffice$ goose -dir migrations postgres "$DATABASE_URL" status
2026/10/16 20:18:42     Applied At                  Migration
2026/10/16 20:18:42     =======================================
2026/10/16 20:18:42     Fri Oct 16 23:18:42 2026 -- 00001_events.sql
2026/10/16 20:18:42     Fri Oct 16 23:18:42 2026 -- 00002_tickets.sql
ana@vm:~/boxoffice$ psql boxoffice -c "SELECT version_id, is_applied, tstamp FROM goose_db_version ORDER BY id"
 version_id | is_applied |           tstamp           
------------+------------+----------------------------
          0 | t          | 2026-10-16 23:18:42.204698
          1 | t          | 2026-10-16 23:18:42.238623
          2 | t          | 2026-10-16 23:18:42.245531
(3 rows)

ana@vm:~/boxoffice$ goose -dir migrations postgres "$DATABASE_URL" down
2026/10/16 20:18:42 OK   00002_tickets.sql (9.94ms)
ana@vm:~/boxoffice$ psql boxoffice -c "\dt"
             List of relations
 Schema |       Name       | Type  | Owner 
--------+------------------+-------+-------
 public | events           | table | ana
 public | goose_db_version | table | ana
(2 rows)

ana@vm:~/boxoffice$ goose -dir migrations postgres "$DATABASE_URL" up
2026/10/16 20:18:42 OK   00002_tickets.sql (6.56ms)
2026/10/16 20:18:42 goose: successfully migrated database to version: 2
```

**`status` lists every migration and whether this database has it**; `up` applied both, in order, and
reported the version the database is now at. The table `goose_db_version` is goose's memory: one row per
migration applied, plus a row for version 0 that goose writes the first time. `down` undid the last
migration only, running its `Down` section, and `\dt` shows `tickets` gone; the second `up` put it
back. **Every step is one file**, and the database always knows which files it has seen.

## sqlc reads the same files

`sqlc.yaml` can point at the migrations directory instead of a single schema file. sqlc understands
goose's markers, reads every `Up` section in order and ignores the `Down` ones, so **the migrations are
the one place the schema is written**:

```yaml
# boxoffice/sqlc.yaml
version: "2"
sql:
  - engine: postgresql
    schema: migrations
    queries: queries.sql
    database:
      uri: ${DATABASE_URL}
    gen:
      go:
        package: db
        out: internal/db
        sql_package: pgx/v5
```

The queries gain one for the new table:

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

-- name: SearchEvents :many
SELECT id, name, seats, sold FROM events
WHERE (sqlc.narg(min_available)::int IS NULL OR seats - sold >= sqlc.narg(min_available)::int)
  AND (sqlc.narg(name_like)::text IS NULL OR name ILIKE sqlc.narg(name_like)::text)
ORDER BY id;

-- name: InsertTicket :one
INSERT INTO tickets (event_id, email, quantity) VALUES ($1, $2, $3)
RETURNING id;
```

```
ana@vm:~/boxoffice$ sqlc generate && ls internal/db
db.go
models.go
queries.sql.go
```
