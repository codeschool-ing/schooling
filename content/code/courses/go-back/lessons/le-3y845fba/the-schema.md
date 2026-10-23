---
title: The table boxoffice keeps its events in
version: 1
---

boxoffice's `Event` has four fields, and its table has four columns. **Everything the store in
lesson 3 enforced in Go, the table now enforces itself**, so that a bug in a handler, a script run
by hand or a second program sharing the database cannot write a row the rules forbid. Save this in
`~/boxoffice` as `schema.sql`:

```sql
-- boxoffice/schema.sql
CREATE TABLE events (
    id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name  text    NOT NULL UNIQUE CHECK (length(name) BETWEEN 1 AND 100),
    seats integer NOT NULL CHECK (seats > 0),
    sold  integer NOT NULL DEFAULT 0 CHECK (sold BETWEEN 0 AND seats)
);

INSERT INTO events (name, seats, sold) VALUES
    ('Jazz at the Docks', 120, 0),
    ('Chamber Choir', 80, 80);
```

Each constraint is one of lesson 3's rules, moved down a layer:

| column | constraint | the rule |
|---|---|---|
| `id` | `GENERATED ALWAYS AS IDENTITY PRIMARY KEY` | the database numbers events, and no two share a number |
| `name` | `NOT NULL UNIQUE`, length 1 to 100 | every event has a name, the same length limit as `newEvent.validate`, and no two events share one |
| `seats` | `CHECK (seats > 0)` | an event has seats |
| `sold` | `CHECK (sold BETWEEN 0 AND seats)` | **no event is ever sold beyond its seats**, whoever writes the row |

The last rule is the one that matters most. It was a line of Go in `Sell`; now it is a promise the
database keeps even against code that forgot it. `sql-databases` lesson 3 is the full treatment of
types and constraints, and nothing here goes beyond it.

`psql -f` runs the file:

```
ana@vm:~/boxoffice$ psql boxoffice -f schema.sql
CREATE TABLE
INSERT 0 2
ana@vm:~/boxoffice$ psql boxoffice -c "\d events"
                         Table "public.events"
 Column |  Type   | Collation | Nullable |           Default            
--------+---------+-----------+----------+------------------------------
 id     | integer |           | not null | generated always as identity
 name   | text    |           | not null | 
 seats  | integer |           | not null | 
 sold   | integer |           | not null | 0
Indexes:
    "events_pkey" PRIMARY KEY, btree (id)
    "events_name_key" UNIQUE CONSTRAINT, btree (name)
Check constraints:
    "events_check" CHECK (sold >= 0 AND sold <= seats)
    "events_name_check" CHECK (length(name) >= 1 AND length(name) <= 100)
    "events_seats_check" CHECK (seats > 0)

ana@vm:~/boxoffice$ psql boxoffice -c "SELECT * FROM events"
 id |       name        | seats | sold 
----+-------------------+-------+------
  1 | Jazz at the Docks |   120 |    0
  2 | Chamber Choir     |    80 |   80
(2 rows)
```

`\d events` describes the table back, and the constraints have names PostgreSQL chose:
**`events_name_key`** for the uniqueness and **`events_check`** for the rule on `sold`. Section 08
meets both names again, in error messages. The two rows are the same two events the in-memory store
started with, so every transcript of lessons 1 to 3 would read the same against this table.

Running `schema.sql` twice fails on `CREATE TABLE`, because the table exists. That is the problem lesson
9 solves with migrations; until then, the file is run once.
