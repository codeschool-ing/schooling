package billing_test

import (
	"context"
	"errors"
	"testing"

	"github.com/codeschool-ing/schooling/internal/billing"
	"github.com/jackc/pgx/v5/pgxpool"
)

/* Where a student writes, against a real Postgres.

   WHAT THIS FILE IS FOR AND `console/support_test.go` IS NOT. That one checks
   what the console decides — recorded before it happens, refused without a
   reason, refused below operator. This one checks the two things only a
   database can answer: that there is exactly one row however many times it is
   set, and that what `Set` returns is what was there BEFORE it.

   THE SECOND IS NOT DECORATION. The handler writes the audit entry from a read
   it made a moment earlier and then compares it against this answer; an answer
   that came back already-updated would make that comparison always agree, and
   the warning it exists to raise — somebody else moved this between the read
   and the write — would never fire again. */

/*
blank empties the one row before a test writes to it.

	NOTHING ELSE IN THIS SUITE NEEDS THIS, and the difference is the point.
	Every other test here seeds its own account and reads its own rows back, so
	two tests cannot see each other. This table is the PLATFORM's — one row,
	enforced by the primary key — so every test in the package shares it, and
	one that assumed it started empty would pass alone and fail in a suite.

	It is not a fixture the tests are built around. It is the cost of a
	singleton, paid once, in the one place that has one.
*/
func blank(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()
	if _, err := pool.Exec(context.Background(), `DELETE FROM support_contact`); err != nil {
		t.Fatalf("emptying the support contact: %v", err)
	}
}

func TestTheAddressIsOneRowHoweverOftenItIsSet(t *testing.T) {
	pool := testPool(t)
	blank(t, pool)
	support := billing.NewSupport(pool)
	ctx := context.Background()

	for _, one := range []string{"first@example.tld", "second@example.tld", "third@example.tld"} {
		if _, err := support.Set(ctx, one); err != nil {
			t.Fatalf("setting %s: %v", one, err)
		}
	}

	var rows int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM support_contact`).Scan(&rows); err != nil {
		t.Fatalf("counting: %v", err)
	}
	if rows != 1 {
		t.Errorf("three writes left %d rows, and there is one platform", rows)
	}

	now, err := support.Now(ctx)
	if err != nil {
		t.Fatalf("reading: %v", err)
	}
	if now.Email != "third@example.tld" {
		t.Errorf("the newest address is %q", now.Email)
	}
	if now.Since.IsZero() {
		t.Error("the row has no date, and the console says how long it has been the answer")
	}
}

// WHAT WAS THERE BEFORE, which is what the audit entry is compared against.
func TestSettingAnAddressAnswersTheOneItReplaced(t *testing.T) {
	pool := testPool(t)
	blank(t, pool)
	support := billing.NewSupport(pool)
	ctx := context.Background()

	// THE FIRST WRITE REPLACED NOTHING, and says so with a zero rather than by
	// failing: a platform that has never set one is the ordinary first state.
	was, err := support.Set(ctx, "first@example.tld")
	if err != nil {
		t.Fatalf("the first address: %v", err)
	}
	if was.Email != "" {
		t.Errorf("the first address claims to have replaced %q", was.Email)
	}

	was, err = support.Set(ctx, "second@example.tld")
	if err != nil {
		t.Fatalf("the second address: %v", err)
	}
	if was.Email != "first@example.tld" {
		t.Errorf("the second address says it replaced %q", was.Email)
	}
}

// NO ROW IS NOT AN ERROR. Every deployment starts here, and the caller falls
// back to what the environment configured — see `cmd`'s `whereToWrite`.
func TestAPlatformThatHasNeverSetOneReadsEmpty(t *testing.T) {
	pool := testPool(t)
	blank(t, pool)
	support := billing.NewSupport(pool)

	found, err := support.Now(context.Background())
	if err != nil {
		t.Fatalf("reading an unset address is not a failure, and it failed: %v", err)
	}
	if found.Email != "" {
		t.Errorf("an address was invented: %q", found.Email)
	}
}

/*
WHAT WILL NOT BE PUBLISHED.

The address is drawn into visible text on a page a student reads and into the
`mailto:` under it, so the two have to be the same thing. A display name makes
them differ; a list makes a link half of whose recipients nobody can see before
pressing send.

The empty case is the one that would be easy to allow by accident, and it must
not be: clearing the row here would leave the notice falling back to whatever
the deployment configured, which reads as "cleared" and is not.
*/
func TestWhatWillNotBePublished(t *testing.T) {
	pool := testPool(t)
	blank(t, pool)
	support := billing.NewSupport(pool)
	ctx := context.Background()

	for _, typed := range []string{
		"",
		"   ",
		"not an address",
		"Support <help@example.tld>",
		"help@example.tld, other@example.tld",
		"help@",
		"@example.tld",
	} {
		if _, err := support.Set(ctx, typed); !errors.Is(err, billing.ErrNotAnAddress) {
			t.Errorf("%q was accepted as an address to publish (%v)", typed, err)
		}
	}

	// AND IT IS STORED LOWERCASED, because it is compared by eye against what
	// a student was told and shown in two places.
	if _, err := support.Set(ctx, "  Help@Example.TLD  "); err != nil {
		t.Fatalf("a real address with room around it: %v", err)
	}
	found, err := support.Now(ctx)
	if err != nil {
		t.Fatalf("reading: %v", err)
	}
	if found.Email != "help@example.tld" {
		t.Errorf("it was stored as %q", found.Email)
	}
}
