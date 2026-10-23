---
title: Against a real PostgreSQL
version: 1
---

`pgStore` is code that only means something with a database behind it: its `Sell` is a transaction, a
conditional `UPDATE` and an `INSERT`, and its correctness is the database's behaviour under concurrency.
**Testing it against a fake would test the fake.** These tests make a real database of their own:

```go
// boxoffice/pgstore_test.go
package main

import (
	"context"
	"crypto/rand"
	"errors"
	"net/url"
	"os"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// testDB makes a database for one test, migrates it, and drops it when the
// test ends. BOXOFFICE_TEST_DATABASE_URL names the server to make it on.
func testDB(t *testing.T) *pgxpool.Pool {
	t.Helper()
	base := os.Getenv("BOXOFFICE_TEST_DATABASE_URL")
	if base == "" {
		t.Skip("BOXOFFICE_TEST_DATABASE_URL is not set")
	}
	ctx := context.Background()
	admin, err := pgx.Connect(ctx, base)
	if err != nil {
		t.Fatal(err)
	}
	name := "boxoffice_test_" + strings.ToLower(rand.Text()[:10])
	if _, err := admin.Exec(ctx, "CREATE DATABASE "+name); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		if _, err := admin.Exec(ctx, "DROP DATABASE "+name+" WITH (FORCE)"); err != nil {
			t.Errorf("dropping %s: %v", name, err)
		}
		admin.Close(ctx)
	})

	u, err := url.Parse(base)
	if err != nil {
		t.Fatal(err)
	}
	u.Path = "/" + name
	if err := migrate(ctx, u.String()); err != nil {
		t.Fatal(err)
	}
	pool, err := pgxpool.New(ctx, u.String())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func TestPgStoreSellsNoMoreThanItHas(t *testing.T) {
	pool := testDB(t)
	store := &pgStore{pool: pool}
	ctx := context.Background()
	e, err := store.Add(ctx, "Small Room", 10)
	if err != nil {
		t.Fatal(err)
	}

	var wg sync.WaitGroup
	var mu sync.Mutex
	results := map[string]int{}
	for range 30 {
		wg.Go(func() {
			_, err := store.Sell(ctx, e.ID, 1, "fan@example.com")
			mu.Lock()
			defer mu.Unlock()
			switch {
			case err == nil:
				results["sold"]++
			case errors.Is(err, ErrSoldOut):
				results["sold out"]++
			default:
				results[err.Error()]++
			}
		})
	}
	wg.Wait()

	if results["sold"] != 10 || results["sold out"] != 20 || len(results) != 2 {
		t.Errorf("results %v, want 10 sold and 20 sold out", results)
	}
	var sold, tickets int
	pool.QueryRow(ctx, "SELECT sold FROM events WHERE id = $1", e.ID).Scan(&sold)
	pool.QueryRow(ctx, "SELECT count(*) FROM tickets WHERE event_id = $1", e.ID).Scan(&tickets)
	if sold != 10 || tickets != 10 {
		t.Errorf("sold %d and %d tickets, want 10 and 10", sold, tickets)
	}
}

func TestASaleReachesTheHub(t *testing.T) {
	pool := testDB(t)
	store := &pgStore{pool: pool}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	h := newHub()
	ch, unsubscribe := h.subscribe(1)
	defer unsubscribe()
	go listen(ctx, pool, h)
	// A sale made before listen has run LISTEN would never be heard, so wait for it.
	for i := 0; ; i++ {
		var n int
		pool.QueryRow(ctx, `SELECT count(*) FROM pg_stat_activity
			WHERE datname = current_database() AND query = 'LISTEN availability'`).Scan(&n)
		if n > 0 {
			break
		}
		if i == 200 {
			t.Fatal("listen did not run LISTEN within 2s")
		}
		time.Sleep(10 * time.Millisecond)
	}

	if _, err := store.Sell(ctx, 1, 3, "fan@example.com"); err != nil {
		t.Fatal(err)
	}
	select {
	case n := <-ch:
		if n != 117 {
			t.Errorf("availability %d, want 117", n)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("no notification within 2s of the sale")
	}
}
```

## A database per test

`testDB` connects to the server named by `BOXOFFICE_TEST_DATABASE_URL`, creates a database with a random
name, runs lesson 9's `migrate` on it, and returns a pool. Its first `t.Cleanup` drops the database when
the test ends, `WITH (FORCE)` so connections still open do not block it, and the pool's cleanup, registered
after, runs before it, because cleanups run last-registered first. **Every test starts from the three
migrations and lesson 1's two events, and nothing one test does is visible to another**, which is also
what would let them run in parallel. A database takes a few dozen milliseconds to create, cheap enough to
have one per test.

The two tests are the two things only PostgreSQL can show:

- **`TestPgStoreSellsNoMoreThanItHas`** is lesson 9's concurrency check, kept: thirty goroutines buy one seat
  each of an event with ten. Exactly ten must succeed, the other twenty must be told it is sold out, and
  nothing else may happen; then the `sold` column and the count of tickets must both say ten. This time the
  results go into a map under a mutex, for section 06's reason.
- **`TestASaleReachesTheHub`** checks lesson 13's whole chain: a sale fires the trigger, the notification
  reaches `listen`, and the hub delivers 117, the seats left after three of 120. It waits until
  `pg_stat_activity` shows `listen`'s connection has run `LISTEN`, instead of sleeping and hoping: a sale
  made before that would never be heard, and the test would fail on a slow machine for a reason it did not
  test.

## Skipped is not passed

Without the variable, both tests skip:

```
ana@vm:~/boxoffice$ go test -run "TestPgStore|TestASale" -v .
=== RUN   TestPgStoreSellsNoMoreThanItHas
    pgstore_test.go:60: BOXOFFICE_TEST_DATABASE_URL is not set
--- SKIP: TestPgStoreSellsNoMoreThanItHas (0.00s)
=== RUN   TestASaleReachesTheHub
    pgstore_test.go:100: BOXOFFICE_TEST_DATABASE_URL is not set
--- SKIP: TestASaleReachesTheHub (0.00s)
PASS
ok  	example.com/boxoffice	0.006s
```

**The last line says `ok`.** Without `-v`, nothing would say that two tests did not run. That is
convenient on a laptop with no database and dangerous anywhere else, so the variable has to be set
wherever the results matter, CI first. Set it to your local server's `postgres` database, which the tests
only use to create and drop their own:

```sh
export BOXOFFICE_TEST_DATABASE_URL='postgres:///postgres?host=/var/run/postgresql'
```

```
ana@vm:~/boxoffice$ go test -run "TestPgStore|TestASale" -v .
=== RUN   TestPgStoreSellsNoMoreThanItHas
--- PASS: TestPgStoreSellsNoMoreThanItHas (0.14s)
=== RUN   TestASaleReachesTheHub
--- PASS: TestASaleReachesTheHub (0.09s)
PASS
ok  	example.com/boxoffice	0.236s
```

`pgstore_test.go:60` and `:100` in the skipped run are the lines of the tests that called `testDB`, not
lines inside it, which is `t.Helper()` at work.

## The cache

```
ana@vm:~/boxoffice$ go test -run "TestPgStore|TestASale" .
ok  	example.com/boxoffice	(cached)
ana@vm:~/boxoffice$ go test -run "TestPgStore|TestASale" .
ok  	example.com/boxoffice	(cached)
ana@vm:~/boxoffice$ go test -count=1 -run "TestPgStore|TestASale" .
ok  	example.com/boxoffice	0.292s
```

The second identical run says **`(cached)`**: `go test` keeps the result of a passing run and replays it
while the code, the flags and the environment variables the test read stay the same. The database's
contents are none of those, so a test that depends on them can be answered from the cache after the
database changed underneath it. **`-count=1` turns the cache off** for one run, and CI should always pass
it. The last command confirms the cleanup worked: no test database was left behind.
