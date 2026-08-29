package billing_test

import (
	"context"
	"errors"
	"testing"

	"github.com/codeschool-ing/schooling/internal/billing"
	"github.com/jackc/pgx/v5/pgxpool"
)

/* The discount series, against a real Postgres.

   IT IS THE PRICE'S TESTS ASKED ABOUT A DIFFERENT NUMBER, because it is the
   price's shape: appended, dated, answering what it replaced, and read as "the
   newest whose day has come". What differs is the one thing worth its own file
   — NO ROW IS NOT AN ERROR here, and it is on the price.

   A term nobody has priced cannot be bought, so `Prices.InForce` refuses it. A
   method nobody has discounted is sold at the price, which is an ordinary
   offer. Getting that backwards would make a deployment that never set a
   discount unable to sell anything at all. */

// scoped keeps each test's rows to itself. The series is keyed by scope, this
// database is not truncated between runs, and `0045` seeds 'all' — so a test
// that used the platform's own scope would be reading every other test's rows
// and the migration's besides.
func scoped(t *testing.T) string {
	t.Helper()
	return "scope-" + short()
}

func TestADiscountIsAppendedAndTheOldOneStays(t *testing.T) {
	pool := testPool(t)
	discounts := billing.NewDiscounts(pool)
	ctx, scope := context.Background(), scoped(t)

	if _, err := discounts.Set(ctx, scope, billing.MethodPix, 500); err != nil {
		t.Fatalf("the first rate: %v", err)
	}
	was, err := discounts.Set(ctx, scope, billing.MethodPix, 700)
	if err != nil {
		t.Fatalf("the second rate: %v", err)
	}
	if was.BasisPoints != 500 {
		t.Errorf("the second rate says it replaced %d", was.BasisPoints)
	}

	now, err := discounts.InForce(ctx, scope, billing.MethodPix)
	if err != nil {
		t.Fatal(err)
	}
	if now.BasisPoints != 700 {
		t.Errorf("the rate in force is %d", now.BasisPoints)
	}

	// AND THE ONE IT REPLACED IS STILL THERE, which is the whole of why this is
	// a table rather than a column.
	series, err := discounts.Series(ctx, scope)
	if err != nil {
		t.Fatal(err)
	}
	if len(series) != 2 {
		t.Fatalf("the series holds %d rows after two rates", len(series))
	}
	if series[0].BasisPoints != 700 || series[1].BasisPoints != 500 {
		t.Errorf("the series is %d then %d, and it is newest first",
			series[0].BasisPoints, series[1].BasisPoints)
	}
}

/*
A METHOD NOBODY HAS DISCOUNTED IS SOLD AT THE PRICE.

This is the one place this store differs from the price's, and getting it wrong
is not a subtle failure: a deployment that has never set a discount would be
unable to open any checkout at all, because the handler would treat "no row" as
a reason to refuse rather than as nothing off.
*/
/*
AND THE DATABASE REFUSES AN EDIT, which is what makes the sentence above a
guarantee rather than a habit.

	IT WAS A HABIT UNTIL THIS TEST. `0045` shipped without the trigger
	`plan_prices` carries — the header said the rate is APPENDED, `writes.go`
	said it, the screen said it, and nothing but the code that writes it made it
	true. A series that can be updated explains nothing, and the way that fails
	is not a console doing it: it is a hand at a psql prompt correcting a typo
	the honest way, which for this table is a new dated row.
*/
func TestARateCannotBeEditedOrDeleted(t *testing.T) {
	pool := testPool(t)
	discounts := billing.NewDiscounts(pool)
	ctx, scope := context.Background(), scoped(t)

	if _, err := discounts.Set(ctx, scope, billing.MethodPix, 500); err != nil {
		t.Fatal(err)
	}

	if _, err := pool.Exec(ctx,
		`UPDATE plan_discounts SET basis_points = 100 WHERE scope = $1`, scope); err == nil {
		t.Error("a rate was edited — the offer is then as forgeable as a column would be")
	}
	if _, err := pool.Exec(ctx,
		`DELETE FROM plan_discounts WHERE scope = $1`, scope); err == nil {
		t.Error("a rate was deleted")
	}

	// AND IT IS STILL THE ONE THAT WAS SET, which is the half a refused write
	// does not prove on its own.
	now, err := discounts.InForce(ctx, scope, billing.MethodPix)
	if err != nil {
		t.Fatal(err)
	}
	if now.BasisPoints != 500 {
		t.Errorf("after two refused writes the rate reads %d", now.BasisPoints)
	}
}

func TestAMethodNobodyHasDiscountedIsNotAnError(t *testing.T) {
	discounts := billing.NewDiscounts(testPool(t))

	one, err := discounts.InForce(context.Background(), scoped(t), billing.MethodCard)
	if err != nil {
		t.Fatalf("a method with no discount is an ordinary offer, and it failed: %v", err)
	}
	if one.BasisPoints != 0 {
		t.Errorf("a rate was invented: %d", one.BasisPoints)
	}
}

// A RATE DATED AHEAD IS NOT THE OFFER YET, which is the condition every read in
// this package uses. Without it, a rate written to start on Monday would apply
// on Friday — and the screen that let somebody schedule it would be the thing
// that charged the wrong amount for three days.
func TestARateDatedAheadIsNotInForceYet(t *testing.T) {
	pool := testPool(t)
	discounts := billing.NewDiscounts(pool)
	ctx, scope := context.Background(), scoped(t)

	if _, err := discounts.Set(ctx, scope, billing.MethodPix, 500); err != nil {
		t.Fatal(err)
	}
	ahead(t, pool, scope, 900)

	now, err := discounts.InForce(ctx, scope, billing.MethodPix)
	if err != nil {
		t.Fatal(err)
	}
	if now.BasisPoints != 500 {
		t.Errorf("the rate in force is %d, and the one dated ahead is not the offer yet",
			now.BasisPoints)
	}
}

// ahead writes a rate that starts tomorrow. There is no way to do it through
// the store, deliberately — `Set` dates from now, because a console that could
// backdate an offer could rewrite what somebody was charged.
func ahead(t *testing.T, pool *pgxpool.Pool, scope string, basisPoints int) {
	t.Helper()
	if _, err := pool.Exec(context.Background(), `
		INSERT INTO plan_discounts (scope, method, basis_points, effective_from)
		VALUES ($1, 'pix', $2, now() + interval '1 day')
	`, scope, basisPoints); err != nil {
		t.Fatalf("dating a rate ahead: %v", err)
	}
}

/*
WHAT WILL NOT BE WRITTEN, and each refusal is a different mistake.

Nothing off is not a discount — it is no row, and the two are different facts
that come to the same charge. More than half off is a digit too many rather than
an offer, and it is the mistake this value can least afford: 5000 where 500 was
meant turns every Pix into a half-price sale, silently, from that moment.
*/
func TestWhatIsNotADiscount(t *testing.T) {
	discounts := billing.NewDiscounts(testPool(t))
	ctx, scope := context.Background(), scoped(t)

	for _, one := range []struct {
		method billing.Method
		points int
		why    string
	}{
		{billing.MethodPix, 0, "nothing off"},
		{billing.MethodPix, -100, "a rate below nothing"},
		{billing.MethodPix, billing.MostBasisPoints + 1, "more than half off"},
		{billing.Method("boleto"), 500, "a way to pay this platform does not take"},
	} {
		if _, err := discounts.Set(ctx, scope, one.method, one.points); !errors.Is(
			err, billing.ErrNotADiscount) {

			t.Errorf("%s was accepted (%v)", one.why, err)
		}
	}
}

// AND THE SAME RATE SAVED TWICE IS TWO ROWS, for the price's reason: it records
// that this is still what we take off, as of today, and a series that dropped
// the repeats could not tell that from a rate nobody has touched since January.
func TestSavingTheSameRateAgainIsStillANewRow(t *testing.T) {
	pool := testPool(t)
	discounts := billing.NewDiscounts(pool)
	ctx, scope := context.Background(), scoped(t)

	for range 2 {
		if _, err := discounts.Set(ctx, scope, billing.MethodPix, 500); err != nil {
			t.Fatal(err)
		}
	}
	series, err := discounts.Series(ctx, scope)
	if err != nil {
		t.Fatal(err)
	}
	if len(series) != 2 {
		t.Errorf("the same rate saved twice wrote %d rows", len(series))
	}
}

// THE PLATFORM WAKES UP DISCOUNTING A PIX. `0045` seeds the rate the interface
// has been quoting since before the table existed — a deployment that migrated
// into charging full price would be changing an offer by migrating, and nobody
// would have decided it.
func TestTheMigrationLeavesThePlatformDiscountingAPix(t *testing.T) {
	discounts := billing.NewDiscounts(testPool(t))

	one, err := discounts.InForce(context.Background(),
		billing.ScopeEverything, billing.MethodPix)
	if err != nil {
		t.Fatal(err)
	}
	if one.BasisPoints <= 0 {
		t.Errorf("the platform's Pix discount is %d — the migration seeds the rate that "+
			"was in force, so this is either the seed having failed or somebody having "+
			"set it to nothing without saying so here", one.BasisPoints)
	}
}
