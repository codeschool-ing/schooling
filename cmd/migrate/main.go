// Command migrate applies the schema, and is a job rather than something the
//
// server does on the way up.
//
// WHY IT IS SEPARATE. Migrating at start-up looks simpler and is a race: the
// platform starts several instances of a new revision at once, and they all
// reach for the schema together. As a job it runs once, has to finish before
// traffic is released, and when it fails the deploy stops with the previous
// revision still serving — nobody studying notices.
//
// THE ADVISORY LOCK IS BELT AND BRACES for the same race, because "runs once"
// is an arrangement and this is a guarantee. A second migrate waits rather
// than applying the same file twice.
package main

import (
	"context"
	"fmt"
	"io/fs"
	"log/slog"
	"os"
	"os/signal"
	"path"
	"sort"
	"strconv"
	"strings"
	"syscall"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/platform/build"
	"github.com/codeschool-ing/schooling/internal/platform/config"
	"github.com/codeschool-ing/schooling/internal/platform/database"
	"github.com/codeschool-ing/schooling/internal/platform/logs"
	"github.com/codeschool-ing/schooling/migrations"
)

// The lock id is arbitrary and only has to be the same in every process. It is
// written here rather than generated so that it stays the same across builds.
const lockID int64 = 6_012_025_001

func main() {
	log := logs.New(os.Stdout)

	if err := run(log); err != nil {
		log.Error("migration failed", "error", err)
		os.Exit(1)
	}
}

func run(log *slog.Logger) error {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	cfg, err := config.Load()
	if err != nil {
		return err
	}

	// Which build changed the schema. The migration job leaves the ledger
	// behind but nothing that says who applied it, and "which release did this"
	// is the first question asked about a schema nobody expected.
	info := build.Current()
	log.Info("migrating", "version", info.Version, "commit", info.Commit)

	pool, err := database.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()

	steps, err := load()
	if err != nil {
		return err
	}

	return apply(ctx, log, pool, steps)
}

type step struct {
	version int
	name    string
	up      string
}

// load reads the embedded files and splits each on the goose markers.
//
// The format is goose's because the predecessor used it and because a plain
// `-- +goose Up` is readable by a person opening the file with no tool.
func load() ([]step, error) {
	entries, err := fs.Glob(migrations.Files, "*.sql")
	if err != nil {
		return nil, fmt.Errorf("migrate: listing the migrations: %w", err)
	}

	steps := make([]step, 0, len(entries))
	for _, name := range entries {
		base := path.Base(name)
		version, err := strconv.Atoi(strings.SplitN(base, "_", 2)[0])
		if err != nil {
			return nil, fmt.Errorf("migrate: %s does not start with a version number", base)
		}

		body, err := fs.ReadFile(migrations.Files, name)
		if err != nil {
			return nil, fmt.Errorf("migrate: reading %s: %w", base, err)
		}

		_, after, found := strings.Cut(string(body), "-- +goose Up")
		if !found {
			return nil, fmt.Errorf("migrate: %s has no `-- +goose Up` marker", base)
		}
		up, _, _ := strings.Cut(after, "-- +goose Down")

		up = strings.TrimSpace(up)
		if up == "" {
			return nil, fmt.Errorf("migrate: %s has an empty Up section", base)
		}

		steps = append(steps, step{version: version, name: base, up: up})
	}

	sort.Slice(steps, func(i, j int) bool { return steps[i].version < steps[j].version })

	// Two files claiming one version is a merge that went wrong, and applying
	// either one silently would leave two databases with different schemas.
	for i := 1; i < len(steps); i++ {
		if steps[i].version == steps[i-1].version {
			return nil, fmt.Errorf("migrate: %s and %s share version %d",
				steps[i-1].name, steps[i].name, steps[i].version)
		}
	}

	return steps, nil
}

func apply(ctx context.Context, log *slog.Logger, pool *pgxpool.Pool, steps []step) error {
	conn, err := pool.Acquire(ctx)
	if err != nil {
		return fmt.Errorf("migrate: acquiring a connection: %w", err)
	}
	defer conn.Release()

	if _, err := conn.Exec(ctx, `SELECT pg_advisory_lock($1)`, lockID); err != nil {
		return fmt.Errorf("migrate: taking the lock: %w", err)
	}
	defer func() {
		// Best effort: the lock is released when the connection closes anyway.
		_, _ = conn.Exec(context.WithoutCancel(ctx), `SELECT pg_advisory_unlock($1)`, lockID)
	}()

	if _, err := conn.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS schema_migrations (
			version    int PRIMARY KEY,
			name       text NOT NULL,
			applied_at timestamptz NOT NULL DEFAULT now()
		)`); err != nil {
		return fmt.Errorf("migrate: creating the ledger: %w", err)
	}

	applied := 0
	for _, s := range steps {
		var exists bool
		if err := conn.QueryRow(ctx,
			`SELECT EXISTS (SELECT 1 FROM schema_migrations WHERE version = $1)`, s.version,
		).Scan(&exists); err != nil {
			return fmt.Errorf("migrate: reading the ledger: %w", err)
		}
		if exists {
			continue
		}

		/* One transaction per step, so a failure leaves the schema at the last
		   whole migration rather than halfway through one. */
		err := pgx.BeginFunc(ctx, conn, func(tx pgx.Tx) error {
			if _, err := tx.Exec(ctx, s.up); err != nil {
				return err
			}
			_, err := tx.Exec(ctx,
				`INSERT INTO schema_migrations (version, name) VALUES ($1, $2)`, s.version, s.name)
			return err
		})
		if err != nil {
			return fmt.Errorf("migrate: applying %s: %w", s.name, err)
		}

		log.Info("applied", "version", s.version, "name", s.name)
		applied++
	}

	if applied == 0 {
		log.Info("schema is up to date", "migrations", len(steps))
	} else {
		log.Info("schema updated", "applied", applied, "migrations", len(steps))
	}
	return nil
}
