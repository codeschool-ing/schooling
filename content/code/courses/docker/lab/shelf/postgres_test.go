//go:build integration

package main

import (
	"context"
	"os"
	"testing"
)

// Run against a real Postgres: DATABASE_URL names it, and the table is
// created and seeded by openPostgres exactly as it is in production.
func TestPostgresServesTheSeededCatalogue(t *testing.T) {
	url := os.Getenv("DATABASE_URL")
	if url == "" {
		t.Fatal("DATABASE_URL is not set: this test needs a database")
	}
	db, err := openPostgres(context.Background(), url)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	books, err := db.Books(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if len(books) < len(builtIn) {
		t.Fatalf("%d books, want at least %d", len(books), len(builtIn))
	}
}
