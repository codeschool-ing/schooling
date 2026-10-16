---
title: Where sqlc gets awkward: optional filters
version: 1
---

sqlc's model is one fixed SQL statement per function. That fits most of what an API does, and it fits
badly one thing APIs do all the time: **a search where every filter is optional.** `GET
/events?available=10&name=jazz` might send either filter, both or neither, which is four different
`WHERE` clauses. An ORM builds the clause at run time, adding a condition for each filter present; sqlc
cannot, because the SQL must exist before the program does.

The usual answer is to write one statement that ignores the filters that were not given. Here is
`queries.sql` with a fifth query added for that search:

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
```

Each condition has the shape **`(filter IS NULL OR condition)`**: when the filter is `NULL`, the first
half is true and the condition does not matter. `sqlc.narg` is `sqlc.arg` for a parameter that may be
`NULL`, and the `::int` and `::text` casts tell PostgreSQL the parameter's type, which it cannot infer from
`IS NULL` alone. sqlc generates the parameters as types that can say "no value":

```
ana@vm:~/boxoffice$ sqlc generate
ana@vm:~/boxoffice$ sed -n "/^type SearchEventsParams/,/^}/p;/^func (q \*Queries) SearchEvents/,+1p" internal/db/queries.sql.go
type SearchEventsParams struct {
	MinAvailable pgtype.Int4
	NameLike     pgtype.Text
}
func (q *Queries) SearchEvents(ctx context.Context, arg SearchEventsParams) ([]Event, error) {
	rows, err := q.db.Query(ctx, searchEvents, arg.MinAvailable, arg.NameLike)
ana@vm:~/boxoffice$ go build ./... && echo builds
builds
```

**`pgtype.Int4` and `pgtype.Text`** are pgx's nullable types, met in lesson 6 section 08; a field left
at its zero value has `Valid: false` and is sent as `NULL`, so a call with an empty
`SearchEventsParams{}` would list every event. boxoffice does not route this query yet, and it builds and
generates cleanly beside the others.

## What it costs

It works, and it has two costs worth knowing. **The SQL is harder to read** than any of the four simple
queries it replaces, and it grows a clause per filter. And **PostgreSQL plans the statement once for all
combinations**, so an index that would serve one filter well may not be used when the plan has to cover
the case where that filter is absent. For a table of events that does not matter; for a search over
millions of rows, it is a reason to write the few common combinations as separate queries, or to build
that one statement at run time with a query builder and keep sqlc for the rest.

**This is the one place where sqlc's design works against you**, and it is worth knowing before choosing
it for a service whose main feature is a search screen.
