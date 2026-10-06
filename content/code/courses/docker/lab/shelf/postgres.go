package main

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

type postgres struct{ pool *pgxpool.Pool }

// openPostgres connects, and creates and fills the one table on first use, so
// a fresh database container is a working catalogue with nothing run by hand.
func openPostgres(ctx context.Context, url string) (*postgres, error) {
	pool, err := pgxpool.New(ctx, url)
	if err != nil {
		return nil, err
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, err
	}
	_, err = pool.Exec(ctx, `CREATE TABLE IF NOT EXISTS books (
		id serial PRIMARY KEY, title text NOT NULL, author text NOT NULL)`)
	if err != nil {
		pool.Close()
		return nil, fmt.Errorf("creating the table: %w", err)
	}
	var n int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM books`).Scan(&n); err != nil {
		pool.Close()
		return nil, err
	}
	if n == 0 {
		for _, b := range builtIn {
			if _, err := pool.Exec(ctx, `INSERT INTO books (title, author) VALUES ($1, $2)`, b.Title, b.Author); err != nil {
				pool.Close()
				return nil, fmt.Errorf("seeding: %w", err)
			}
		}
	}
	return &postgres{pool}, nil
}

func (p *postgres) Books(ctx context.Context) ([]book, error) {
	rows, err := p.pool.Query(ctx, `SELECT id, title, author FROM books ORDER BY id`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var books []book
	for rows.Next() {
		var b book
		if err := rows.Scan(&b.ID, &b.Title, &b.Author); err != nil {
			return nil, err
		}
		books = append(books, b)
	}
	return books, rows.Err()
}

func (p *postgres) Close() { p.pool.Close() }
