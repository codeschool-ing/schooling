---
title: NULL, missing rows and broken rules
version: 1
---

Three things come back from a database that a Go program has to be ready for: **a value that is not
there, a row that is not there, and a rule the database refused to break.** This program meets each on
purpose:

```go
// nulls/main.go
package main

import (
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func main() {
	ctx := context.Background()
	conn, err := pgx.Connect(ctx, os.Getenv("DATABASE_URL"))
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer conn.Close(ctx)

	var s string
	err = conn.QueryRow(ctx, "SELECT NULL::text").Scan(&s)
	fmt.Printf("string:      %q %v\n", s, err)

	var p *string
	err = conn.QueryRow(ctx, "SELECT NULL::text").Scan(&p)
	fmt.Printf("*string:     %v %v\n", p, err)

	var t pgtype.Text
	err = conn.QueryRow(ctx, "SELECT NULL::text").Scan(&t)
	fmt.Printf("pgtype.Text: %+v %v\n", t, err)

	_, err = conn.Exec(ctx, "INSERT INTO events (name, seats) VALUES ('Chamber Choir', 10)")
	fmt.Println("duplicate:  ", err)

	_, err = conn.Exec(ctx, "UPDATE events SET sold = 200 WHERE id = 1")
	fmt.Println("too many:   ", err)
}
```

```
ana@vm:~/nulls$ DATABASE_URL='postgres:///boxoffice?host=/var/run/postgresql' go run .
string:      "" can't scan into dest[0] (col: text): cannot scan NULL into *string
*string:     <nil> <nil>
pgtype.Text: {String: Valid:false} <nil>
duplicate:   ERROR: duplicate key value violates unique constraint "events_name_key" (SQLSTATE 23505)
too many:    ERROR: new row for relation "events" violates check constraint "events_check" (SQLSTATE 23514)
```

## A value that is not there

SQL's `NULL` means "no value", and a Go `string` cannot hold that: its zero value, `""`, is a value.
**pgx refuses to scan `NULL` into a `string`** rather than quietly turning it into an empty one, which
would make a missing phone number look like a phone number nobody typed. Two types can hold it:

- **a pointer, `*string`**, which stays `nil` for `NULL`. It is short, and the `nil` check is the
  ordinary Go one; it costs an allocation per value.
- **`pgtype.Text`**, a struct with the value and a `Valid` flag, `false` for `NULL`. `database/sql`
  has the same idea as `sql.NullString`.

boxoffice's columns are all `NOT NULL`, so none of this touches it yet. **The decision belongs in the
schema first**: a column that must have a value says `NOT NULL`, and then the Go side needs no special
type. Lesson 3 section 04 made the same point about JSON, where a missing field and a zero cannot be told
apart either.

## A row that is not there

`QueryRow` with no row is not a value of zero: it is `pgx.ErrNoRows`, as `sql.ErrNoRows` was for
`database/sql`. `pgStore.Get` turns it into `ErrNotFound`, and lesson 3's `fail` turns that into a 404.
**The error changes vocabulary at each layer**, from PostgreSQL's to boxoffice's to HTTP's, and no layer
needs to know the words of the one two steps away.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 230\" role=\"img\" aria-label=\"Three failures, each crossing three layers from left to right. A missing row: pgx.ErrNoRows in PostgreSQL's layer becomes ErrNotFound in the store and 404 in HTTP. A duplicate name: SQLSTATE 23505 becomes ErrDuplicate and 409. A broken check: SQLSTATE 23514 has no store word, stays a wrapped error, and becomes a 500 with a log line.\"><defs><marker id=\"gb-l6-words-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">PostgreSQL and pgx</text><text x=\"350\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the store</text><text x=\"590\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">HTTP</text><rect x=\"20\" y=\"38\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pgx.ErrNoRows</text><path d=\"M 200 58 L 258 58\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l6-words-ah)\"></path><rect x=\"260\" y=\"38\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ErrNotFound</text><path d=\"M 440 58 L 498 58\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l6-words-ah)\"></path><rect x=\"500\" y=\"38\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">404 Not Found</text><rect x=\"20\" y=\"100\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SQLSTATE 23505</text><path d=\"M 200 120 L 258 120\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l6-words-ah)\"></path><rect x=\"260\" y=\"100\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ErrDuplicate</text><path d=\"M 440 120 L 498 120\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l6-words-ah)\"></path><rect x=\"500\" y=\"100\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">409 Conflict</text><rect x=\"20\" y=\"162\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SQLSTATE 23514</text><path d=\"M 200 182 L 258 182\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l6-words-ah)\"></path><rect x=\"260\" y=\"162\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">wrapped, unnamed</text><path d=\"M 440 182 L 498 182\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l6-words-ah)\"></path><rect x=\"500\" y=\"162\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">500, and a log line</text><text x=\"229\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">pgStore</text><text x=\"469\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">fail</text></svg>", "caption": "Each layer speaks its own words. pgStore translates the database's, fail translates the store's, and nothing in a handler sees a pgx type."}
```

## A rule the database refused to break

The last two lines are the constraints of section 04 at work. The insert broke `events_name_key`, the
uniqueness of names, and the update broke `events_check`, the rule that `sold` stays within `seats`.
Each error carries its **SQLSTATE**, five characters that identify the kind of failure across every
PostgreSQL release and every language's driver:

| SQLSTATE | name | what boxoffice does |
|---|---|---|
| `23505` | `unique_violation` | `ErrDuplicate`, answered with 409 |
| `23514` | `check_violation` | nothing special: it means a bug, and becomes a 500 |
| `42601` | `syntax_error` | nothing special: the bug of section 07 |
| `3D000` | `invalid_catalog_name` | the missing database of section 03, at start-up |

**Matching on the code and not the message** is what `pgStore.Add` does with `pgconn.PgError`: the
message is English text that can change between releases; the code is a contract. And boxoffice turns
only the duplicate into an answer for the client, because it is the only one a client can cause with a
valid request. A check violation means boxoffice's own code tried to oversell, which no client should be
told about and every operator should hear about, through the log's `unexpected error` line.

`problem.go` gains the new error in its `fail`, in section 09.
