package notify_test

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"os"
	"strings"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/notify"
)

/* The suppression list, against a real database.

   IT IS NOT TESTED AGAINST A FAKE, because every one of the things worth
   checking here is a property of the statement rather than of the Go around
   it: the upsert that makes a retried webhook harmless, the CHECK that keeps a
   reason from being invented, and the fact that no row ever holds an address. A
   double would agree with whatever this file assumed. */

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

// address gives every test its own mailbox, so that a list which is deliberately
// never emptied does not make two tests each other's problem.
func address(t *testing.T) string {
	t.Helper()
	return "refused-" + uniq(t) + "@example.tld"
}

func uniq(t *testing.T) string {
	t.Helper()
	var b [8]byte
	if _, err := rand.Read(b[:]); err != nil {
		t.Fatalf("random: %v", err)
	}
	return hex.EncodeToString(b[:])
}

// THE PLAIN CASE: an address refuses us, and afterwards we know it.
func TestABarredAddressIsBarred(t *testing.T) {
	list := notify.NewSuppressions(testPool(t))
	ctx := context.Background()
	who := address(t)

	barred, err := list.Barred(ctx, who)
	if err != nil {
		t.Fatalf("asking: %v", err)
	}
	if barred {
		t.Fatal("an address nobody has heard from is already barred")
	}

	first, err := list.Bar(ctx, who, notify.HardBounce)
	if err != nil {
		t.Fatalf("barring: %v", err)
	}
	if !first {
		t.Error("the first refusal did not report itself as the first")
	}

	if barred, err = list.Barred(ctx, who); err != nil {
		t.Fatalf("asking again: %v", err)
	}
	if !barred {
		t.Error("the address is not barred after refusing us")
	}
}

/*
THE SAME EVENT TWICE IS THE NORMAL CASE, NOT THE ODD ONE.

	A provider retries a webhook it did not hear back from, so the second arrival
	of one refusal is expected traffic. It must not fail, must not make a second
	row, and must not claim to be the first — which is what the log line is
	branched on.
*/
func TestTheSameRefusalTwiceIsOneRow(t *testing.T) {
	pool := testPool(t)
	list := notify.NewSuppressions(pool)
	ctx := context.Background()
	who := address(t)

	if _, err := list.Bar(ctx, who, notify.Complaint); err != nil {
		t.Fatalf("the first: %v", err)
	}
	first, err := list.Bar(ctx, who, notify.HardBounce)
	if err != nil {
		t.Fatalf("the second: %v", err)
	}
	if first {
		t.Error("the second refusal reported itself as the first")
	}

	sum := sha256.Sum256([]byte(who))
	var reason string
	var times int
	if err := pool.QueryRow(ctx,
		`SELECT reason, times FROM mail_suppressions WHERE address_hash = $1`,
		sum[:]).Scan(&reason, &times); err != nil {
		t.Fatalf("reading the row: %v", err)
	}
	if times != 2 {
		t.Errorf("the row counts %d refusals, want 2", times)
	}
	// THE FIRST REASON IS KEPT. All three mean the same instruction, and which
	// one arrived first is the one fact a support conversation has to go on.
	if reason != string(notify.Complaint) {
		t.Errorf("the reason became %q, want the first one recorded", reason)
	}
}

/*
ONE MAILBOX IS ONE ROW, whatever case the provider sends it in.

	`Ana@Example.tld ` and `ana@example.tld` are the same person, and two rows
	would be one of them barred while the other is written to — which is the
	suppression list quietly not working for exactly the address it was told
	about.
*/
func TestCaseAndSpaceDoNotMakeASecondAddress(t *testing.T) {
	list := notify.NewSuppressions(testPool(t))
	ctx := context.Background()
	who := address(t)

	if _, err := list.Bar(ctx, "  "+strings.ToUpper(who)+"  ", notify.Blocked); err != nil {
		t.Fatalf("barring: %v", err)
	}

	barred, err := list.Barred(ctx, who)
	if err != nil {
		t.Fatalf("asking: %v", err)
	}
	if !barred {
		t.Error("the lowercase address is not barred, and it is the same mailbox")
	}
}

/*
A SOFT BOUNCE DOES NOT REACH THIS FAR, AND IF IT DID IT WOULD BE REFUSED.

	`Hook` filters the reason before calling; this is the second lock on the same
	door, because the cost of it being wrong is the whole platform suppressing an
	entire provider on the afternoon that provider has an outage — which is not a
	hypothetical, it is 27 August 2026.

	THE CHECK CONSTRAINT IS A THIRD, and it is the one that does not depend on
	anybody remembering: `0038` widened it by name to admit `invalid`, so a fifth
	value is refused by the database until somebody writes the argument down.
*/
func TestOnlyAPermanentReasonBars(t *testing.T) {
	list := notify.NewSuppressions(testPool(t))
	ctx := context.Background()
	who := address(t)

	for _, why := range []notify.Reason{"soft_bounce", "unsubscribed", "opened", "deferred", ""} {
		if _, err := list.Bar(ctx, who, why); !errors.Is(err, notify.ErrNotPermanent) {
			t.Errorf("barring for %q answered %v, want ErrNotPermanent", why, err)
		}
	}

	barred, err := list.Barred(ctx, who)
	if err != nil {
		t.Fatalf("asking: %v", err)
	}
	if barred {
		t.Error("a reason that is not permanent barred the address anyway")
	}
}

// AN EVENT ABOUT NOBODY IS A BUG IN THE CALLER AND READS LIKE ONE, rather than
// hashing the empty string and answering confidently about it forever after.
func TestAnEmptyAddressIsAnError(t *testing.T) {
	list := notify.NewSuppressions(testPool(t))
	ctx := context.Background()

	for _, empty := range []string{"", "   ", "\t"} {
		if _, err := list.Bar(ctx, empty, notify.HardBounce); !errors.Is(err, notify.ErrNoAddress) {
			t.Errorf("barring %q answered %v, want ErrNoAddress", empty, err)
		}
		if _, err := list.Barred(ctx, empty); !errors.Is(err, notify.ErrNoAddress) {
			t.Errorf("asking about %q answered %v, want ErrNoAddress", empty, err)
		}
	}
}

/*
THE TABLE HOLDS NO ADDRESS, AND THAT IS THE ENTIRE DESIGN.

	It is what lets one row outlive an erasure without holding anything that was
	erased. A column added later that carried the address — for support, for
	debugging, for a report — would quietly undo it, and this is the test that
	would go red.
*/
func TestTheTableHoldsNoAddress(t *testing.T) {
	pool := testPool(t)
	list := notify.NewSuppressions(pool)
	ctx := context.Background()
	who := address(t)

	if _, err := list.Bar(ctx, who, notify.HardBounce); err != nil {
		t.Fatalf("barring: %v", err)
	}

	rows, err := pool.Query(ctx, `
		SELECT column_name, data_type
		  FROM information_schema.columns
		 WHERE table_name = 'mail_suppressions'
	`)
	if err != nil {
		t.Fatalf("reading the schema: %v", err)
	}
	defer rows.Close()

	for rows.Next() {
		var name, kind string
		if err := rows.Scan(&name, &kind); err != nil {
			t.Fatalf("scanning: %v", err)
		}
		/* NOT "no column is called email" — a column called anything at all
		   could hold one. What is checked is that nothing in this table is a
		   string, which is a rule a new column has to break on purpose. */
		if kind == "text" && name != "reason" {
			t.Errorf("mail_suppressions.%s is text, and a text column in this table "+
				"is where an address ends up. If it has to exist, say here why it "+
				"cannot carry one", name)
		}
	}
	if err := rows.Err(); err != nil {
		t.Fatalf("reading the schema: %v", err)
	}
}

/*
`invalid` REACHES THE DATABASE, WHICH IS NOT THE SAME AS THE GO ACCEPTING IT.

	The reason is checked twice — once by a `switch` in `Bar` and once by a CHECK
	constraint that lists the values by name — and those two can disagree. They
	did, for as long as it took to write `0038`: a build that knew about
	`invalid` and a schema that did not would compile, pass every test with a
	fake, and fail on the first real one.
*/
func TestAnInvalidAddressIsBarredAndTheSchemaAgrees(t *testing.T) {
	pool := testPool(t)
	list := notify.NewSuppressions(pool)
	ctx := context.Background()
	who := address(t)

	if _, err := list.Bar(ctx, who, notify.Invalid); err != nil {
		t.Fatalf("barring an invalid address: %v", err)
	}

	var reason string
	sum := sha256.Sum256([]byte(who))
	if err := pool.QueryRow(ctx,
		`SELECT reason FROM mail_suppressions WHERE address_hash = $1`,
		sum[:]).Scan(&reason); err != nil {
		t.Fatalf("reading the row: %v", err)
	}
	if reason != string(notify.Invalid) {
		t.Errorf("the row says %q, want %q", reason, notify.Invalid)
	}

	barred, err := list.Barred(ctx, who)
	if err != nil {
		t.Fatalf("asking: %v", err)
	}
	if !barred {
		t.Error("an address the provider called invalid is not barred")
	}
}

/*
AND A FIFTH VALUE IS REFUSED BY THE DATABASE AND NOT ONLY BY THE GO.

	`Bar` would never send one — its `switch` is closed — so this goes around it
	deliberately. What is being held is the property that made `0038` a migration
	rather than a constant: a reason nobody decided about cannot be written by a
	deployment that merely believes in it.
*/
func TestTheSchemaRefusesAReasonNobodyDecidedAbout(t *testing.T) {
	pool := testPool(t)
	ctx := context.Background()

	sum := sha256.Sum256([]byte(address(t)))
	_, err := pool.Exec(ctx,
		`INSERT INTO mail_suppressions (address_hash, reason) VALUES ($1, $2)`,
		sum[:], "soft_bounce")
	if err == nil {
		t.Fatal("the database accepted a reason that is not permanent")
	}
	if !strings.Contains(err.Error(), "mail_suppressions_reason_check") {
		t.Errorf("it was refused by %v, want the reason CHECK — if the constraint "+
			"was renamed, rename it here too", err)
	}
}
