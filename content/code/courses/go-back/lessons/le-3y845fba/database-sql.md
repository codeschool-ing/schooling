---
title: database/sql, the standard interface
version: 1
---

Go's standard library has a package for SQL databases, `database/sql`, and like `net/http` it is an
interface more than an implementation. **It defines how a program asks a database for things; a
driver, imported separately, knows how to speak to one particular database.** For PostgreSQL the
driver used here comes from `pgx`, the most complete PostgreSQL library for Go, which section 06 uses
on its own.

```go
// dbsql/main.go
package main

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log"
	"os"

	_ "github.com/jackc/pgx/v5/stdlib"
)

func main() {
	db, err := sql.Open("pgx", os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()
	ctx := context.Background()

	rows, err := db.QueryContext(ctx, "SELECT id, name, seats - sold FROM events ORDER BY id")
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()
	for rows.Next() {
		var id, left int
		var name string
		if err := rows.Scan(&id, &name, &left); err != nil {
			log.Fatal(err)
		}
		fmt.Printf("%d %s: %d left\n", id, name, left)
	}
	if err := rows.Err(); err != nil {
		log.Fatal(err)
	}

	var name string
	err = db.QueryRowContext(ctx, "SELECT name FROM events WHERE id = $1", 9).Scan(&name)
	fmt.Println("event 9:", err, errors.Is(err, sql.ErrNoRows))

	stats := db.Stats()
	fmt.Println("open connections:", stats.OpenConnections, "idle:", stats.Idle)
}
```

The underscore import, `_ "github.com/jackc/pgx/v5/stdlib"`, imports the package only for what it does
when it loads: it registers a driver under the name `"pgx"`, and `sql.Open("pgx", url)` finds it by
that name. Then:

- **`QueryContext` returns `rows`**, a cursor over the result. `rows.Next` moves it, `rows.Scan`
  copies the current row's columns into variables, in order, and `rows.Close` gives the connection
  back. The `defer rows.Close()` matters: **a `rows` that is never closed holds its connection for
  ever**, and enough of those leave a pool with none.
- **`rows.Err()` after the loop** reports an error that ended the loop early. A loop that stops
  because the network failed looks exactly like a loop that reached the last row, and only this check
  tells them apart.
- **`QueryRowContext` is for one row**, and its `Scan` returns `sql.ErrNoRows` when there was none.
- Every call takes a `context.Context`, so that a query belongs to a request and can be cancelled
  with it, which is the use `go-concurrency` lesson 12 named for a database.

```
ana@vm:~/dbsql$ export DATABASE_URL='postgres:///boxoffice?host=/var/run/postgresql'
ana@vm:~/dbsql$ go mod init example.com/dbsql
go: creating new go.mod: module example.com/dbsql
go: to add module requirements and sums:
	go mod tidy
ana@vm:~/dbsql$ go mod tidy
go: finding module for package github.com/jackc/pgx/v5/stdlib
go: found github.com/jackc/pgx/v5/stdlib in github.com/jackc/pgx/v5 v5.11.0
ana@vm:~/dbsql$ DATABASE_URL='postgres:///boxoffice?host=/var/run/postgresql' go run .
1 Jazz at the Docks: 120 left
2 Chamber Choir: 0 left
event 9: sql: no rows in result set true
open connections: 1 idle: 1
```

`go mod tidy` found the driver from the import and downloaded what it needs. The program then listed
both events, got `sql.ErrNoRows` for event 9 and recognised it with `errors.Is`, and reported **one
open connection, idle**.

## `sql.DB` is a pool, not a connection

The name misleads everybody once. **`sql.Open` does not connect to anything**; it checks its arguments
and returns a `*sql.DB`, which is a pool of connections opened on demand and reused. The first query
opened one, and when `rows.Close` returned it, it went back to the pool as idle, which is what the last
line shows. A program opens one `sql.DB` at start and shares it everywhere, from every goroutine; it is
safe for that, and opening one per request is a classic way to run a database out of connections.
Lesson 9 sizes the pool.

## Why boxoffice does not use it

`database/sql` works with any database that has a driver, and that portability is its point. It costs
PostgreSQL-specific features and some speed: every value passes through the package's generic
conversions, and things like PostgreSQL's arrays, its `COPY` for bulk loading, or `LISTEN` for
notifications are out of reach or awkward. **A service that will only ever talk to PostgreSQL loses
nothing by using pgx's own interface**, and boxoffice does, from the next section on. Lesson 7's GORM
and lesson 8's sqlc can sit on either.
