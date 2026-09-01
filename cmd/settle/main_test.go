package main

import (
	"context"
	"io"
	"log/slog"
	"os"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/billing"
)

func testPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("SCHOOLING_TEST_DATABASE_URL")
	if url == "" {
		t.Skip("set SCHOOLING_TEST_DATABASE_URL to run the tests that need a database")
	}
	pool, err := pgxpool.New(context.Background(), url)
	if err != nil {
		t.Fatalf("opening the test database: %v", err)
	}
	t.Cleanup(pool.Close)
	return pool
}

/*
THE WHOLE POINT OF THIS COMMAND, END TO END.

	`internal/billing` holds that the sweep emits an ending; this holds that
	running THIS command does it — which is the half that was missing, because
	the sweeper had no caller at all and every test of it called it directly.

	IT WRITES INTO THE STREAM, WHICH CANNOT BE UNDONE, and that is fine here for
	the reason the seeder's tests are fine: the row is scoped to an account this
	test created, every assertion is about that account, and `events` is shared
	with every other package's tests so nothing may truncate it anyway.
*/
func TestRunningTheCommandPutsTheEndingInTheStream(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	log := slog.New(slog.NewTextHandler(io.Discard, nil))

	account, subscription := aLapsedSubscription(t, pool)

	said, err := settle(ctx, log, pool)
	if err != nil {
		t.Fatalf("settling: %v", err)
	}
	if !strings.Contains(said, "reached the end of what") {
		t.Errorf("the run said %q, and the row a screen shows is that sentence", said)
	}

	// THE TABLE AGREES WITH THE CLOCK NOW, which it did not before this command
	// existed: reading settles in memory, so the row stayed `active` for ever.
	var state string
	if err := pool.QueryRow(ctx,
		`SELECT state FROM subscriptions WHERE id = $1`, subscription).Scan(&state); err != nil {
		t.Fatalf("reading the subscription back: %v", err)
	}
	if state == "active" {
		t.Error("the subscription is still `active` after its term ran out, which is the " +
			"disagreement between the table and the clock this job exists to end")
	}

	// AND THE STREAM SAW SOMEBODY STOP.
	var endings int
	if err := pool.QueryRow(ctx, `
		SELECT count(*) FROM events
		WHERE name = 'subscription.ended' AND account_id = $1
		  AND payload->>'reason' = 'elapsed'
	`, account).Scan(&endings); err != nil {
		t.Fatalf("counting the endings: %v", err)
	}
	if endings != 1 {
		t.Errorf("the stream has %d elapsed endings for this account, want one — without "+
			"it a retention report describes a platform nobody ever leaves", endings)
	}

	// AND IT CARRIES NO SCHOOL, because one subscription covers every school
	// (N-02) and the funnel's second reader is the one that finds it.
	var tenants int
	if err := pool.QueryRow(ctx, `
		SELECT count(*) FROM events
		WHERE name = 'subscription.ended' AND account_id = $1 AND tenant_id IS NOT NULL
	`, account).Scan(&tenants); err != nil {
		t.Fatalf("checking the dimension: %v", err)
	}
	if tenants != 0 {
		t.Errorf("%d of the endings name a school, and a subscription belongs to none", tenants)
	}
}

// RUNNING IT TWICE CHANGES NOTHING, which is what makes a failed night simply
// run again tomorrow — and what stops an append-only stream collecting one
// ending per night for the rest of the platform's life.
func TestRunningItTwiceChangesNothing(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()
	log := slog.New(slog.NewTextHandler(io.Discard, nil))

	account, _ := aLapsedSubscription(t, pool)

	for i := 0; i < 2; i++ {
		if _, err := settle(ctx, log, pool); err != nil {
			t.Fatalf("settling, pass %d: %v", i+1, err)
		}
	}

	var endings int
	if err := pool.QueryRow(ctx, `
		SELECT count(*) FROM events WHERE name = 'subscription.ended' AND account_id = $1
	`, account).Scan(&endings); err != nil {
		t.Fatalf("counting the endings: %v", err)
	}
	if endings != 1 {
		t.Errorf("two runs wrote %d endings for one subscription that ended once", endings)
	}
}

/*
aLapsedSubscription is somebody whose term ended, written the way a payment
would have written it.

	THE ROWS ARE REAL AND THE DATES ARE IN THE PAST, which is the one thing this
	fixture needs: `Settle` selects on `paid_through <= now`, so a subscription
	that has not lapsed is a test that silently checks nothing.
*/
func aLapsedSubscription(t *testing.T, pool *pgxpool.Pool) (account, subscription uuid.UUID) {
	t.Helper()
	ctx := context.Background()

	address := "settle-" + strings.ReplaceAll(uuid.NewString(), "-", "")[:12] + "@example.tld"
	if err := pool.QueryRow(ctx,
		`INSERT INTO accounts (email) VALUES ($1) RETURNING id`,
		address).Scan(&account); err != nil {
		t.Fatalf("seeding an account: %v", err)
	}

	var price uuid.UUID
	if err := pool.QueryRow(ctx, `
		INSERT INTO plan_prices (scope, term_months, cents, currency)
		VALUES ($1, 12, 49000, 'BRL') RETURNING id
	`, billing.ScopeEverything).Scan(&price); err != nil {
		t.Fatalf("seeding a price: %v", err)
	}

	if err := pool.QueryRow(ctx, `
		INSERT INTO subscriptions (account_id, scope, model, state, paid_through, price_id)
		VALUES ($1, $2, 'instalments', 'active', now() - interval '30 days', $3)
		RETURNING id
	`, account, billing.ScopeEverything, price).Scan(&subscription); err != nil {
		t.Fatalf("seeding a subscription: %v", err)
	}
	return account, subscription
}
