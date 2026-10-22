---
title: Migrations that travel with the binary
version: 1
---

The goose command is a tool on your laptop. A server in production does not have it, and should not
need a person to run it before every deployment. **The other way is to compile the migration files into
boxoffice itself and apply them when it starts.** Go's `embed` package, which `go-concurrency` lesson 24
introduced, puts files into the binary at build time:

```go
// boxoffice/migrate.go
package main

import (
	"context"
	"database/sql"
	"embed"
	"fmt"
	"io/fs"
	"log"

	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
	"github.com/pressly/goose/v3/lock"
)

//go:embed migrations/*.sql
var migrationFiles embed.FS

// migrate brings the database up to the newest migration compiled into this binary.
func migrate(ctx context.Context, url string) error {
	db, err := sql.Open("pgx", url)
	if err != nil {
		return err
	}
	defer db.Close()
	dir, err := fs.Sub(migrationFiles, "migrations")
	if err != nil {
		return err
	}
	locker, err := lock.NewPostgresSessionLocker()
	if err != nil {
		return err
	}
	provider, err := goose.NewProvider(goose.DialectPostgres, db, dir, goose.WithSessionLocker(locker))
	if err != nil {
		return err
	}
	results, err := provider.Up(ctx)
	if err != nil {
		return fmt.Errorf("migrating: %w", err)
	}
	for _, r := range results {
		log.Printf("migration %s applied in %s", r.Source.Path, r.Duration)
	}
	return nil
}
```

- **`//go:embed migrations/*.sql`** makes `migrationFiles` a read-only file system holding those files,
  compiled in. The binary needs no directory beside it, which lesson 16 depends on.
- **goose's library speaks `database/sql`**, so `migrate` opens a short-lived `sql.DB` through pgx's
  driver, lesson 6 section 05, and closes it when done.
- **The session locker** takes a PostgreSQL advisory lock for the duration. If three copies of
  boxoffice start at once, one applies the migrations and the other two wait for it, instead of all
  three trying to create the same table.
- `provider.Up` applies whatever is pending and returns what it did, which goes to the log.

`main` calls it before anything else touches the database, and also builds the pool with two settings of
its own, which section 07 explains:

```go
// boxoffice/main.go
package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	tokens := map[string]string{}
	for role, name := range map[string]string{
		"manager": "BOXOFFICE_MANAGER_TOKEN",
		"door":    "BOXOFFICE_DOOR_TOKEN",
	} {
		if t := os.Getenv(name); t != "" {
			tokens[t] = role
		}
	}
	if len(tokens) == 0 {
		log.Fatal("no staff tokens: set BOXOFFICE_MANAGER_TOKEN")
	}

	url := os.Getenv("DATABASE_URL")
	if url == "" {
		log.Fatal("no database: set DATABASE_URL")
	}
	ctx := context.Background()
	if err := migrate(ctx, url); err != nil {
		log.Fatalf("database: %v", err)
	}
	cfg, err := pgxpool.ParseConfig(url)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	cfg.MaxConns = 10
	cfg.MaxConnIdleTime = 5 * time.Minute
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	defer pool.Close()
	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("database: %v", err)
	}

	srv := &http.Server{
		Addr:              "localhost:8080",
		Handler:           routes(&pgStore{pool: pool}, tokens),
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("boxoffice listening on %s", srv.Addr)
	log.Fatal(srv.ListenAndServe())
}
```

Against an empty database, the server's first lines are the migrations:

```
ana@vm:~/boxoffice$ go vet ./...
ana@vm:~/boxoffice$ dropdb boxoffice && createdb boxoffice
ana@vm:~/boxoffice$ cat .server.log
2026/10/16 20:18:43 migration 00001_events.sql applied in 4.584833ms
2026/10/16 20:18:43 migration 00002_tickets.sql applied in 5.055343ms
2026/10/16 20:18:43 boxoffice listening on localhost:8080
```

**And started a second time, it applies nothing**, because the database already holds version 2:

```
ana@vm:~/boxoffice$ cat .server.log
2026/10/16 20:18:47 boxoffice listening on localhost:8080
```

## At start-up, or as a separate step

Migrating at start-up is simple and it fits boxoffice, with one instance and changes that take
milliseconds. It has two costs worth knowing:

- **A slow migration delays start-up.** Adding an index to a table of a hundred million rows can take
  minutes, and a server that will not answer health checks for minutes looks dead to whatever runs it.
- **The new code and the new schema arrive at the same moment.** If old copies of the program are still
  serving while new ones start, the old code meets the new schema. Changes that both versions can live
  with, adding a column before using it, dropping one only after nothing reads it, avoid that.

Larger services run migrations as a separate step of the deployment, with the same files and the goose
command or a dedicated job, before the new code starts. Because the files and the library are the same,
**moving from one to the other is a change to the deployment, not to the migrations.**
