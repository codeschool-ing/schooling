package billing_test

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/billing"
	"github.com/jackc/pgx/v5/pgxpool"
)

/* What the platform charges, against a real Postgres.

   THESE TESTS MOVED WITH THE FEATURE, from `tenant`, where they were about what
   a SCHOOL charged. `0041` moved the table to the platform because one
   subscription opens every school (N-02) and two prices for one thing is an
   arbitrage. The rules did not change; the key did, and there is a term now.

   The trigger tests are here rather than in a migration test for the reason
   they were there before: what makes "a price is never edited" a guarantee
   rather than a habit is the database refusing, and that has to be asked of a
   database. */

func prices(t *testing.T) (*billing.Prices, *pgxpool.Pool) {
	t.Helper()
	pool := testPool(t)
	return billing.NewPrices(pool), pool
}

/*
THE OLD PRICE SURVIVES THE NEW ONE, and that is the whole of K-14.

A column would answer "what does it cost" and nothing else. The series answers
"what did it cost in March", which is the question an invoice raises in November
— and it is the question the previous shape could not be asked, because setting
the new price destroyed the old one.
*/
func TestTheOldPriceSurvivesTheNewOne(t *testing.T) {
	store, _ := prices(t)
	ctx := context.Background()
	scope := aScope(t)

	if _, err := store.Set(ctx, scope, billing.TermAnnual, 49000, "BRL"); err != nil {
		t.Fatalf("setting the first price: %v", err)
	}
	was, err := store.Set(ctx, scope, billing.TermAnnual, 59000, "BRL")
	if err != nil {
		t.Fatalf("raising the price: %v", err)
	}
	if was.Cents != 49000 || was.Currency != "BRL" {
		t.Errorf("the raise answered %d %q as what it replaced", was.Cents, was.Currency)
	}

	series, err := store.Series(ctx, scope)
	if err != nil {
		t.Fatal(err)
	}
	if len(series) != 2 {
		t.Fatalf("two prices were set and the series holds %d", len(series))
	}
	if series[0].Cents != 59000 {
		t.Errorf("the newest row is %d and should be the one in force", series[0].Cents)
	}
	if series[1].Cents != 49000 {
		t.Errorf("the price that was replaced is gone: %+v", series)
	}
}

// AND THE DATABASE REFUSES AN EDIT, which is what makes the sentence above a
// guarantee rather than a habit. Every other append-only table here carries the
// same trigger, and a price that could be updated would explain nothing.
func TestAPriceCannotBeEditedOrDeleted(t *testing.T) {
	store, pool := prices(t)
	ctx := context.Background()
	scope := aScope(t)

	if _, err := store.Set(ctx, scope, billing.TermAnnual, 49000, "BRL"); err != nil {
		t.Fatal(err)
	}

	if _, err := pool.Exec(ctx,
		`UPDATE plan_prices SET cents = 100 WHERE scope = $1`, scope); err == nil {
		t.Error("a price was edited — the offer is then as forgeable as the column was")
	}
	if _, err := pool.Exec(ctx,
		`DELETE FROM plan_prices WHERE scope = $1`, scope); err == nil {
		t.Error("a price was deleted")
	}
}

// NOTHING PRICED IS NOT A PRICE OF ZERO. The column that preceded this table
// used zero for both, which made a free plan and an undecided one the same
// number — and one of those is a decision somebody made.
func TestATermNobodyHasPricedHasNoOffer(t *testing.T) {
	store, _ := prices(t)
	ctx := context.Background()
	scope := aScope(t)

	series, err := store.Series(ctx, scope)
	if err != nil {
		t.Fatal(err)
	}
	if len(series) != 0 {
		t.Errorf("a plan nobody has priced has %d prices", len(series))
	}
	if _, err := store.InForce(ctx, scope, billing.TermAnnual); !errors.Is(err, billing.ErrNoOffer) {
		t.Errorf("an unpriced term answered %v, want ErrNoOffer", err)
	}
}

/*
THE PRICE IN FORCE, AND ITS ROW'S IDENTITY.

	Every other read of the series answers a number. This one answers WHICH ROW,
	because a subscription has to point at it — a rise must not raise the price
	for everybody who already paid, and `plan_prices` is append-only precisely so
	that pointing is possible.

	A ROW DATED AHEAD IS REPRESENTABLE AND IS NOT THE OFFER. That is what
	`effective_from` is for, and selling at it before its day would be charging
	somebody a number that is not on the page yet.
*/
func TestTheRowInForceIsTheLatestOneWhoseDayHasCome(t *testing.T) {
	store, pool := prices(t)
	ctx := context.Background()
	scope := aScope(t)

	rows := map[string]string{}
	for _, r := range []struct {
		name  string
		cents int
		from  string
	}{
		{"old", 39000, "now() - interval '90 days'"},
		{"now", 49000, "now() - interval '1 day'"},
		{"soon", 59000, "now() + interval '30 days'"},
	} {
		var row string
		if err := pool.QueryRow(ctx, `
			INSERT INTO plan_prices (scope, term_months, cents, currency, effective_from)
			VALUES ($1, $2, $3, 'BRL', `+r.from+`) RETURNING id
		`, scope, billing.TermAnnual, r.cents).Scan(&row); err != nil {
			t.Fatalf("seeding the %s price: %v", r.name, err)
		}
		rows[r.name] = row
	}

	got, err := store.InForce(ctx, scope, billing.TermAnnual)
	if err != nil {
		t.Fatalf("reading: %v", err)
	}
	if got.ID.String() != rows["now"] {
		t.Errorf("the row in force is %s; the current one is %s", got.ID, rows["now"])
	}
	if got.Cents != 49000 || got.Currency != "BRL" {
		t.Errorf("it came back as %d %s", got.Cents, got.Currency)
	}
	if got.ID.String() == rows["soon"] {
		t.Error("a price dated ahead was sold as the one in force")
	}

	// AND `Set` ANSWERS THE SAME ROW, because what it replaces is what is in
	// force and not what is newest — a rise announced for next month must not
	// be recorded as the value a change today replaced.
	was, err := store.Set(ctx, scope, billing.TermAnnual, 51000, "BRL")
	if err != nil {
		t.Fatal(err)
	}
	if was.Cents != 49000 {
		t.Errorf("the price in force answered %d — a row dated ahead was applied early", was.Cents)
	}
}

/*
A TERM IS PRICED ON ITS OWN, and this is the test the old shape could not have.

	There was one price per school and now there are three products under one
	scope: the year, the two years, and the month abroad. They share a table and
	they are not the same offer — pricing one must not move another, and
	`InForce` must answer the term it was asked about rather than the newest row
	in the table.
*/
func TestEachTermIsItsOwnSeries(t *testing.T) {
	store, _ := prices(t)
	ctx := context.Background()
	scope := aScope(t)

	for _, one := range []struct {
		term  int
		cents int
	}{
		{billing.TermAnnual, 59000},
		{billing.TermBiennial, 99000},
		{billing.TermMonthly, 4900},
	} {
		if _, err := store.Set(ctx, scope, one.term, one.cents, "BRL"); err != nil {
			t.Fatalf("pricing a term of %d months: %v", one.term, err)
		}
	}

	// Raising the year, which must leave the other two exactly where they are.
	if _, err := store.Set(ctx, scope, billing.TermAnnual, 69000, "BRL"); err != nil {
		t.Fatal(err)
	}

	for _, want := range []struct {
		term  int
		cents int
	}{
		{billing.TermAnnual, 69000},
		{billing.TermBiennial, 99000},
		{billing.TermMonthly, 4900},
	} {
		got, err := store.InForce(ctx, scope, want.term)
		if err != nil {
			t.Fatalf("reading a term of %d months: %v", want.term, err)
		}
		if got.Cents != want.cents {
			t.Errorf("a term of %d months is priced at %d, want %d",
				want.term, got.Cents, want.cents)
		}
		if got.TermMonths != want.term {
			t.Errorf("the row for %d months says %d", want.term, got.TermMonths)
		}
	}
}

// AND THE SERIES SHOWS THEM TOGETHER, because the question it answers is "what
// moved and when" and that is a comparison across terms — three tables cannot
// be asked it.
func TestTheSeriesCarriesEveryTerm(t *testing.T) {
	store, _ := prices(t)
	ctx := context.Background()
	scope := aScope(t)

	for _, one := range []struct{ term, cents int }{
		{billing.TermAnnual, 59000},
		{billing.TermBiennial, 99000},
	} {
		if _, err := store.Set(ctx, scope, one.term, one.cents, "BRL"); err != nil {
			t.Fatal(err)
		}
	}

	series, err := store.Series(ctx, scope)
	if err != nil {
		t.Fatal(err)
	}
	if len(series) != 2 {
		t.Fatalf("two terms were priced and the series holds %d rows", len(series))
	}
	seen := map[int]bool{}
	for _, one := range series {
		seen[one.TermMonths] = true
	}
	if !seen[billing.TermAnnual] || !seen[billing.TermBiennial] {
		t.Errorf("the series lost a term: %+v", series)
	}
}

// NEITHER HALF OF A PRICE IS ACCEPTED ALONE, and neither is a term that is not
// a number of months. All three refusals are the caller's to fix and all three
// say which one was wrong, because a constraint violation is true and is not a
// sentence a console can show anybody.
func TestAPriceIsATermANumberAndACurrency(t *testing.T) {
	store, _ := prices(t)
	ctx := context.Background()
	scope := aScope(t)

	for _, bad := range []struct {
		term     int
		cents    int
		currency string
	}{
		{12, 0, "BRL"}, {12, -1, "BRL"}, {12, 49000, ""},
		{12, 49000, "brl"}, {12, 49000, "REAIS"},
		{0, 49000, "BRL"}, {-12, 49000, "BRL"},
	} {
		if _, err := store.Set(ctx, scope, bad.term, bad.cents, bad.currency); !errors.Is(
			err, billing.ErrNotAPrice) {
			t.Errorf("%d months at %d %q answered %v", bad.term, bad.cents, bad.currency, err)
		}
	}
}

/*
THE SCOPE IS 'all' WHEN NOBODY SAYS OTHERWISE, which is N-02 written as a
default rather than as a rule somebody has to remember.

	It is not a convenience. Every caller today sells the platform-wide
	subscription, so an empty scope reaching the table would be a price for a
	product that does not exist — invisible, because it would simply never be
	the answer to any read.
*/
func TestAnUnsaidScopeIsEverything(t *testing.T) {
	store, _ := prices(t)
	ctx := context.Background()

	if _, err := store.Set(ctx, "", billing.TermAnnual, 59000, "BRL"); err != nil {
		t.Fatal(err)
	}
	got, err := store.InForce(ctx, billing.ScopeEverything, billing.TermAnnual)
	if err != nil {
		t.Fatalf("reading what was written with no scope: %v", err)
	}
	if got.Cents != 59000 {
		t.Errorf("it came back as %d", got.Cents)
	}
	if got.Scope != billing.ScopeEverything {
		t.Errorf("the row's scope is %q", got.Scope)
	}
}

/*
aScope is a scope of this test's own, so that runs do not read each other's
rows.

	THE TABLE IS APPEND-ONLY AND THAT IS THE POINT OF IT: nothing can clean up
	after a test, here or in production. Every other suite against this database
	seeds a fresh school for the same reason; a price has no school to hang off
	any more, so it gets a scope instead — a string this test invented, which
	`plan_prices` is happy to hold because 'all' is not a foreign key either.

	IT CARRIES A FRESH UUID AND NOT ONLY THE TEST'S NAME. The name alone was
	written first and passed once: the second run against the same database read
	the first run's rows and saw a price it had not set. Nothing here can delete
	them, so the scope has to be new every time.
*/
func aScope(t *testing.T) string {
	t.Helper()
	return "test-" + strings.ReplaceAll(uuid.NewString(), "-", "")[:16]
}
