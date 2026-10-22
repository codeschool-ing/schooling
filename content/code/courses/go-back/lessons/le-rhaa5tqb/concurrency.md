---
title: Two buyers at once
version: 1
---

A transaction makes a group of writes all or nothing. **It does not, by itself, stop two transactions
from interfering with each other**, and how much they may is a setting called the isolation level. The
classic way to lose money is this: two buyers read "one seat left" at the same moment, both decide there
is room, both write "sold one more", and the event is sold one seat too many, or one sale is forgotten.

This program measures it. A table `seats` with one row, and four ways to sell one seat, each run fifty
times at once from fifty goroutines:

```go
// race/main.go
package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"sync"
	"sync/atomic"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Each way of selling takes one seat of row 1 of the table seats.

func readThenWrite(ctx context.Context, pool *pgxpool.Pool, iso pgx.TxIsoLevel) error {
	tx, err := pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: iso})
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	var sold int
	if err := tx.QueryRow(ctx, "SELECT sold FROM seats WHERE id = 1").Scan(&sold); err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, "UPDATE seats SET sold = $1 WHERE id = 1", sold+1); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

func forUpdate(ctx context.Context, pool *pgxpool.Pool) error {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	var sold int
	if err := tx.QueryRow(ctx, "SELECT sold FROM seats WHERE id = 1 FOR UPDATE").Scan(&sold); err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, "UPDATE seats SET sold = $1 WHERE id = 1", sold+1); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

func oneUpdate(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := pool.Exec(ctx, "UPDATE seats SET sold = sold + 1 WHERE id = 1")
	return err
}

func main() {
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatal(err)
	}
	defer pool.Close()
	if _, err := pool.Exec(ctx, "CREATE TABLE IF NOT EXISTS seats (id int PRIMARY KEY, sold int NOT NULL)"); err != nil {
		log.Fatal(err)
	}

	ways := []struct {
		name string
		sell func(context.Context, *pgxpool.Pool) error
	}{
		{"read, then write", func(ctx context.Context, p *pgxpool.Pool) error { return readThenWrite(ctx, p, pgx.ReadCommitted) }},
		{"the same, REPEATABLE READ", func(ctx context.Context, p *pgxpool.Pool) error { return readThenWrite(ctx, p, pgx.RepeatableRead) }},
		{"SELECT ... FOR UPDATE", forUpdate},
		{"one UPDATE", oneUpdate},
	}
	for _, way := range ways {
		if _, err := pool.Exec(ctx, "DELETE FROM seats"); err != nil {
			log.Fatal(err)
		}
		if _, err := pool.Exec(ctx, "INSERT INTO seats VALUES (1, 0)"); err != nil {
			log.Fatal(err)
		}
		var failed atomic.Int32
		var wg sync.WaitGroup
		for range 50 {
			wg.Go(func() {
				if err := way.sell(ctx, pool); err != nil {
					var pgErr *pgconn.PgError
					if errors.As(err, &pgErr) && pgErr.Code == "40001" {
						failed.Add(1)
						return
					}
					log.Print(err)
				}
			})
		}
		wg.Wait()
		var sold int
		if err := pool.QueryRow(ctx, "SELECT sold FROM seats WHERE id = 1").Scan(&sold); err != nil {
			log.Fatal(err)
		}
		fmt.Printf("%-26s 50 sales: sold = %2d, refused with 40001: %2d\n", way.name, sold, failed.Load())
	}
}
```

- **read, then write**: a transaction reads `sold`, adds one in Go, and writes the new number back. This
  is the natural way to write it, and the wrong one.
- **the same at `REPEATABLE READ`**, a stricter isolation level than PostgreSQL's default, `READ
  COMMITTED`.
- **`SELECT ... FOR UPDATE`**: the read takes a lock on the row, so the next transaction that wants it
  waits until this one ends.
- **one `UPDATE`**: `sold = sold + 1`, the arithmetic done by the database inside a single statement.

It runs in a database of its own, `racelab`, twice:

```
ana@vm:~/race$ createdb racelab
ana@vm:~/race$ DATABASE_URL='postgres:///racelab?host=/var/run/postgresql' go run .
read, then write           50 sales: sold = 27, refused with 40001:  0
the same, REPEATABLE READ  50 sales: sold = 16, refused with 40001: 34
SELECT ... FOR UPDATE      50 sales: sold = 50, refused with 40001:  0
one UPDATE                 50 sales: sold = 50, refused with 40001:  0
ana@vm:~/race$ DATABASE_URL='postgres:///racelab?host=/var/run/postgresql' go run .
read, then write           50 sales: sold = 17, refused with 40001:  0
the same, REPEATABLE READ  50 sales: sold = 15, refused with 40001: 35
SELECT ... FOR UPDATE      50 sales: sold = 50, refused with 40001:  0
one UPDATE                 50 sales: sold = 50, refused with 40001:  0
```

**The first line is the bug, and it is different every run**: 27 and then 17 seats recorded for 50 sales.
Many transactions read the same value, each wrote that value plus one, and the later writes erased the
earlier ones. This is called a **lost update**. At `READ COMMITTED`, a transaction sees whatever was
committed before each of its statements, so nothing stops two of them reading the same number.

At `REPEATABLE READ`, PostgreSQL notices the conflict: a transaction that tries to update a row someone
else changed since it started is refused with **SQLSTATE `40001`, a serialization failure**. The counts add
up, 16 plus 34 and 15 plus 35, so no sale was silently lost; but **34 buyers were told no for no reason**,
and the program has to retry them. Code that uses `REPEATABLE READ` or `SERIALIZABLE` must catch `40001`
and run the whole transaction again, which is correct and a lot of machinery.

The last two are exact, every time. **`FOR UPDATE` makes the transactions queue** for the row. **One
`UPDATE` needs no transaction at all**: PostgreSQL locks the row for the statement and computes `sold + 1`
from the value it finds once it holds the lock.

## boxoffice does the fourth

Look at `SellSeats` again: `UPDATE events SET sold = sold + $1 WHERE id = $2 AND seats - sold >= $1`. **The
check and the change are one statement**, so two buyers of the last seat queue for the row, and the
second one finds `seats - sold` too small and changes nothing. That was true since lesson 6, before
transactions; the transaction of section 05 only adds the ticket to the same all-or-nothing.

To see it against the real service, this program sends twenty purchases of one ticket each, all at
once, with a five-second limit on each answer:

```go
// rush/main.go
package main

import (
	"fmt"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"
)

// rush sends 20 purchases of one ticket each, all at once, and counts the answers.
func main() {
	url := "http://localhost:8080/events/" + os.Args[1] + "/tickets"
	client := &http.Client{Timeout: 5 * time.Second}
	var mu sync.Mutex
	statuses := map[int]int{}
	var wg sync.WaitGroup
	for i := range 20 {
		wg.Go(func() {
			body := fmt.Sprintf(`{"quantity": 1, "email": "buyer%02d@example.com"}`, i)
			resp, err := client.Post(url, "application/json", strings.NewReader(body))
			if err != nil {
				mu.Lock()
				statuses[0]++
				mu.Unlock()
				return
			}
			resp.Body.Close()
			mu.Lock()
			statuses[resp.StatusCode]++
			mu.Unlock()
		})
	}
	wg.Wait()
	fmt.Println("201:", statuses[201], " 409:", statuses[409], " no answer in 5s:", statuses[0])
}
```

Section 07 runs it against an event with five seats, and finds the line the last section promised.
