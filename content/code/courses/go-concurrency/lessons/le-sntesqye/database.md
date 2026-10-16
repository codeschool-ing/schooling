---
title: A database query
version: 1
---

**This course has no database, and this section says so rather than pretending.** The standard
library defines how Go talks to one, in `database/sql`, and leaves the talking itself to a driver
somebody else writes. `go doc` says it in as many words:

```
ana@vm:~/cases$ go doc database/sql.DB.Query
package sql // import "database/sql"

func (db *DB) Query(query string, args ...any) (*Rows, error)
    Query executes a query that returns rows, typically a SELECT. The args are
    for any placeholder parameters in the query.

    Query uses context.Background internally; to specify the context, use
    DB.QueryContext.

ana@vm:~/cases$ go doc database/sql.Open | sed -n 8,11p
    Most users will open a database via a driver-specific connection helper
    function that returns a *DB. No database drivers are included in the
    Go standard library. See https://golang.org/s/sqldrivers for a list of
    third-party drivers.
```

The first answer is the one that matters here. **Every method of `database/sql` that can wait has
a twin that takes a context**: `QueryContext`, `ExecContext`, `PingContext`, `BeginTx`. The plain
`Query` is `QueryContext` with `context.Background()`, a context that never ends, so a query made
with it waits as long as the database takes, however long the request that asked for it was
willing to wait.

The shape is the same as every call in lesson 11. The program below is that shape whole, and it
compiles, passes `go vet` and runs; it is saved in `~/cases/nodb` as `nodb.go`:

```go
// Command nodb is the shape of a query with a deadline, on a machine with no database.
package main

import (
	"context"
	"database/sql"
	"fmt"
	"time"
)

func orders(ctx context.Context, db *sql.DB, customer string) ([]string, error) {
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	rows, err := db.QueryContext(ctx, "SELECT id FROM orders WHERE customer = $1", customer)
	if err != nil {
		return nil, fmt.Errorf("orders of %s: %w", customer, err)
	}
	defer rows.Close()
	var ids []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}

func main() {
	db, err := sql.Open("postgres", "postgres://ana@127.0.0.1/shop")
	if err != nil {
		fmt.Println("open:", err)
		return
	}
	defer db.Close()
	ids, err := orders(context.Background(), db, "ana")
	fmt.Println(ids, err)
}
```

```
ana@vm:~/cases$ go vet ./nodb && go run ./nodb
open: sql: unknown driver "postgres" (forgotten import?)
```

It failed where it had to: `sql.Open` looked for a driver registered under the name `postgres`,
found none, and said so. Everything after that line is unexercised on this machine, and the course
says so plainly. What the code still shows is where the context goes:

- **`orders` takes `ctx` first and derives a child** with a two-second limit of its own. A caller
  with less time left wins, by lesson 11's rule.
- **`QueryContext` receives the child.** If the context ends while the query runs, the call returns
  the context's error. The driver receives the same context, and what it does with it is the
  driver's business.
- **`rows.Close` is deferred and `rows.Err()` is returned.** A context that ends in the middle of
  reading the rows surfaces there, after `rows.Next()` returns false, so a function that skips
  `rows.Err()` can mistake half a result for all of it.

What a driver does when told to stop, how the database itself cancels the work, and what that
looks like on a real server are questions for a real database. **`go-back` connects to one**, and
this course leaves that to it.
