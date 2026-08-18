// Package database opens the pool, and the size of that pool is the whole
//
// reason it has opinions.
//
// THE POOL IS SMALL ON PURPOSE. This service scales by running more instances,
// and every instance opens its own pool — so the number the database sees is
// the pool size multiplied by however many instances the platform decided to
// start. A pool of ten looks harmless on a laptop and becomes a thousand
// connections against a database that accepts a few hundred, at the exact
// moment traffic is highest and the failure is least welcome.
//
// Units, not tens. The ceiling is raised when a profile says the pool is the
// thing waiting, and not before.
package database

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

const (
	maxConns        = 4
	minConns        = 0
	maxConnLifetime = 30 * time.Minute
	maxConnIdleTime = 5 * time.Minute
	connectTimeout  = 10 * time.Second
)

// Open parses the address, applies the pool settings and proves the database
// is reachable before returning. A pool that is only discovered to be broken
// on the first request turns a bad address into a mystery at 3am rather than a
// refusal to start.
func Open(ctx context.Context, url string) (*pgxpool.Pool, error) {
	cfg, err := pgxpool.ParseConfig(url)
	if err != nil {
		// The address carries a password. Nothing here may print it, so the
		// error says what failed and not what it was parsing.
		return nil, fmt.Errorf("database: the address could not be parsed: %w", err)
	}

	cfg.MaxConns = maxConns
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
