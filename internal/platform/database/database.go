// Package database opens the pool, and the size of that pool is the whole
//
// reason it has opinions.
//
// THE POOL IS SMALL ON PURPOSE, AND IT IS NOT ONE NUMBER. The database accepts
// a fixed count of connections, and every process that can be alive at once
// takes its pool out of that count — so the size a process may hold is half
// of a sum, and the sum is what matters. `infra/README.md`, "Why the limit is
// 8", is that sum written out: every process that can hold a connection while
// another does, what each holds, and the total. `budget_test.go` holds it to
// the code, so a pool that grows here or an instance ceiling that grows in
// `infra/run.tf` fails a test rather than a request.
//
// It used to be one constant, four, shared by every command. That hid the
// only fact worth knowing about it: that the API is multiplied by its
// instances, twice over during a rollout, and a job is not.
package database

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// How many connections one process may hold, by the kind of process it is.
// Every caller of Open names one of these, so the size is read at the call
// site rather than inherited from here.
const (
	/* APIConnections is per INSTANCE of the service, and the instance count
	   multiplies it: by `max_instance_count` in `infra/run.tf`, and by two
	   again while a rollout has the old revision and the new one serving side
	   by side.

	   TWO AND NOT ONE, because one would serialise every query an instance
	   makes behind the slowest one in flight — `/readyz`'s ping included, so a
	   long report would read to the uptime check as a dead database. Two is
	   the smallest pool in which a slow query does not stop the service
	   answering.

	   IT IS SAFE THIS SMALL ONLY IF NO REQUEST HOLDS A CONNECTION WHILE ASKING
	   FOR A SECOND — two such requests in a pool of two wait on each other
	   until their deadlines. That was measured rather than argued, on the
	   commit that set these numbers: the whole suite, with every test pool
	   capped at ONE, where a nested acquisition cannot even finish alone.

	     SCHOOLING_TEST_DATABASE_URL="…&pool_max_conns=1" go test -count=1 ./...

	   It is not a standing check, and deliberately: capping every pool at one
	   would also serialise the tests that exist to make two writers race, and
	   they would go on passing having raced nobody. Run it again when a
	   store starts opening a transaction inside another call. */
	APIConnections = 2

	/* JobConnections is for every command that is not the service: migrate,
	   load, analyse, settle, and the ones a person runs — staff, seed, reset.
	   Each does one thing after another, and `load`'s whole write is ONE
	   transaction, which is one connection by definition. A job given more
	   would hold nothing extra; the pool opens a connection only when every
	   open one is busy. The number is the guarantee, not the forecast. */
	JobConnections = 1
)

const (
	minConns        = 0
	maxConnLifetime = 30 * time.Minute
	maxConnIdleTime = 5 * time.Minute
	connectTimeout  = 10 * time.Second
)

// Open parses the address, applies the pool settings and proves the database
// is reachable before returning. A pool that is only discovered to be broken
// on the first request turns a bad address into a mystery at 3am rather than a
// refusal to start.
//
// most is how many connections the pool may hold — APIConnections or
// JobConnections. Below one is refused here, by name, rather than further down
// by the pool library in a sentence about its own internals.
//
// THE ADDRESS CANNOT WIDEN IT. pgx reads `pool_max_conns` out of a connection
// string, and this overwrites whatever it read: a secret edited to carry a
// bigger pool would otherwise be a way round the sum that nothing in this
// repository could see.
func Open(ctx context.Context, url string, most int32) (*pgxpool.Pool, error) {
	if most < 1 {
		return nil, fmt.Errorf("database: a pool of %d connections is not a pool", most)
	}

	cfg, err := pgxpool.ParseConfig(url)
	if err != nil {
		// The address carries a password. Nothing here may print it, so the
		// error says what failed and not what it was parsing.
		return nil, fmt.Errorf("database: the address could not be parsed: %w", err)
	}

	cfg.MaxConns = most
	cfg.MinConns = minConns
	cfg.MaxConnLifetime = maxConnLifetime
	cfg.MaxConnIdleTime = maxConnIdleTime

	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		return nil, fmt.Errorf("database: the pool could not be created: %w", err)
	}

	pingCtx, cancel := context.WithTimeout(ctx, connectTimeout)
	defer cancel()
	if err := pool.Ping(pingCtx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("database: unreachable: %w", err)
	}

	return pool, nil
}
