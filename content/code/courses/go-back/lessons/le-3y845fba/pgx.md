---
title: pgx, and boxoffice's store in PostgreSQL
version: 1
---

`pgx` has two faces. Through `database/sql` it is a driver like any other, as the last section used
it. On its own it is a full PostgreSQL client with an interface of its own, and that is how boxoffice
uses it. **The first step is a decision about shape, not about pgx**: the handlers must stop talking to
`*memStore` and talk to anything that can list, get, add and sell events. Section 09 writes that as an
interface, `Store`, and `pgStore` below is the second thing that satisfies it, after the in-memory store.

```schooling-example
{
  "language": "go",
  "file": "boxoffice/pgstore.go",
  "parts": [
    {
      "code": "// boxoffice/pgstore.go\npackage main\n\nimport (\n\t\"context\"\n\t\"errors\"\n\t\"fmt\"\n\n\t\"github.com/jackc/pgx/v5\"\n\t\"github.com/jackc/pgx/v5/pgconn\"\n\t\"github.com/jackc/pgx/v5/pgxpool\"\n)\n\n// pgStore keeps the events in PostgreSQL.\ntype pgStore struct {\n\tpool *pgxpool.Pool\n}\n\n",
      "note": "**A `pgxpool.Pool` is pgx's pool**, the same idea as `sql.DB` from the last section: many connections, opened on demand, safe to share from every goroutine. `pgStore` holds one, made once in `main`."
    },
    {
      "code": "func (s *pgStore) List(ctx context.Context) ([]Event, error) {\n\trows, err := s.pool.Query(ctx, `SELECT id, name, seats, sold FROM events ORDER BY id`)\n\tif err != nil {\n\t\treturn nil, fmt.Errorf(\"listing events: %w\", err)\n\t}\n\treturn pgx.CollectRows(rows, pgx.RowToStructByPos[Event])\n}\n\n",
      "note": "`Query` sends the SQL and returns rows; **`pgx.CollectRows` walks them, scans each with the function it is given and closes them**, so the `rows.Close` and `rows.Err` of the last section cannot be forgotten. `RowToStructByPos[Event]` fills the struct's fields from the columns in order, which is why the `SELECT` names its columns in the order `Event` declares them."
    },
    {
      "code": "func (s *pgStore) Get(ctx context.Context, id int) (Event, error) {\n\tvar e Event\n\terr := s.pool.QueryRow(ctx, `SELECT id, name, seats, sold FROM events WHERE id = $1`, id).\n\t\tScan(&e.ID, &e.Name, &e.Seats, &e.Sold)\n\tif errors.Is(err, pgx.ErrNoRows) {\n\t\treturn Event{}, fmt.Errorf(\"event %d: %w\", id, ErrNotFound)\n\t}\n\treturn e, err\n}\n\n",
      "note": "**`$1` is a placeholder**, and `id` travels separately from the SQL text; section 07 is about why that matters. No row comes back as `pgx.ErrNoRows`, which is pgx's, and the store turns it into its own `ErrNotFound`, wrapped with the id, so that lesson 3's `fail` still recognises it with `errors.Is`."
    },
    {
      "code": "func (s *pgStore) Add(ctx context.Context, name string, seats int) (Event, error) {\n\te := Event{Name: name, Seats: seats}\n\terr := s.pool.QueryRow(ctx,\n\t\t`INSERT INTO events (name, seats) VALUES ($1, $2) RETURNING id`, name, seats).Scan(&e.ID)\n\tvar pgErr *pgconn.PgError\n\tif errors.As(err, &pgErr) && pgErr.Code == \"23505\" {\n\t\treturn Event{}, fmt.Errorf(\"%q: %w\", name, ErrDuplicate)\n\t}\n\treturn e, err\n}\n\n",
      "note": "`RETURNING id` hands back the number the database chose, in the same round trip as the insert. A unique violation, **SQLSTATE `23505`**, becomes `ErrDuplicate`; section 08 shows the error it is read from."
    },
    {
      "code": "// Sell takes quantity seats in one statement, so two buyers cannot both get the last one.\nfunc (s *pgStore) Sell(ctx context.Context, id, quantity int) (Event, error) {\n\tvar e Event\n\terr := s.pool.QueryRow(ctx, `\n\t\tUPDATE events SET sold = sold + $2\n\t\tWHERE id = $1 AND seats - sold >= $2\n\t\tRETURNING id, name, seats, sold`, id, quantity).Scan(&e.ID, &e.Name, &e.Seats, &e.Sold)\n\tif errors.Is(err, pgx.ErrNoRows) {\n\t\tif _, err := s.Get(ctx, id); err != nil {\n\t\t\treturn Event{}, err\n\t\t}\n\t\treturn Event{}, fmt.Errorf(\"event %d: %w\", id, ErrSoldOut)\n\t}\n\treturn e, err\n}\n",
      "note": "**The whole sale is one statement.** The `WHERE` both finds the event and checks the seats, and PostgreSQL runs the check and the change on the row together, so two buyers of the last seat cannot both pass. No row back means one of two things, and a second query tells which: the event is missing, or it is sold out."
    }
  ]
}
```

Three habits in that file are worth keeping in every store you write:

- **Every method takes a `context.Context` and passes it to pgx.** When a client disconnects, the
  request's context is cancelled, and pgx cancels the query on the server rather than finishing work
  nobody will read.
- **Errors from pgx are wrapped with what was being done** (`listing events: %w`), and the store's own
  sentinel errors are used for what the handlers must tell apart. A handler never sees a pgx type.
- **Each SQL statement is a constant string with placeholders.** Nothing about the request is ever
  pasted into the SQL itself.

The number of round trips matters too. `List`, `Get` and `Add` are one each. `Sell` is one when it
succeeds, which is the common case, and two only when it fails. **A database call is the slowest thing
a handler does**: lesson 2's log measured tens of microseconds per request against the map, and section
09 will measure milliseconds against PostgreSQL.
