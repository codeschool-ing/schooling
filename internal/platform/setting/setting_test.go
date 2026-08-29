package setting_test

import (
	"context"
	"errors"
	"os"
	"testing"

	"github.com/codeschool-ing/schooling/internal/platform/setting"
	"github.com/jackc/pgx/v5/pgxpool"
)

/* The mechanism K-13's fence moved onto.

   WHAT THIS SUITE IS WATCHING is not that a number round-trips. It is the four
   places where this package can quietly stop being a fence:

     - a name declared twice, which is two modules believing they own one
       decision and a screen that moves whichever one won the map;
     - a row whose name nothing declares, or whose value is outside what the
       declaration allows — both of which can only arrive by hand or by a
       rollback, and both of which must decide nothing;
     - `was`, which the console writes into an audit entry as the value it
       replaced, so an answer that came back already-updated would make every
       entry say a number changed to itself;
     - and the fallback being the SHIPPED value rather than a blank, because
       everything above resolves to it. */

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
blank empties the table before a test writes to it.

	THE PARAMETERS ARE THE PLATFORM'S — one row per name, shared by every test
	in this package the way `support_contact` is shared in `billing`. A test
	that assumed it started empty would pass alone and fail in a suite.
*/
func blank(t *testing.T, pool *pgxpool.Pool) {
	t.Helper()
	if _, err := pool.Exec(context.Background(), `DELETE FROM settings`); err != nil {
		t.Fatalf("emptying the parameters: %v", err)
	}
}

// aPassMark is a declaration shaped like the ones the modules make, used
// wherever a test needs one and does not care which.
var aPassMark = setting.Declared{
	Name:     "test.passmark",
	Unit:     setting.Percent,
	Least:    50,
	Most:     90,
	Fallback: 70,
	Why:      "how strict this platform is, which is a judgement and not a fact",
}

func TestARegistryRefusesANameDeclaredTwice(t *testing.T) {
	other := aPassMark
	other.Why = "somebody else who thinks they own the pass mark"

	if _, err := setting.NewRegistry(aPassMark, other); err == nil {
		t.Fatal("two declarations of one name were accepted, so one of them " +
			"silently decides nothing")
	}
}

func TestARegistryRefusesADeclarationThatCannotBeSatisfied(t *testing.T) {
	for _, one := range []struct {
		what string
		bad  setting.Declared
	}{
		{"no name", setting.Declared{Unit: setting.Count, Least: 1, Most: 9, Fallback: 3}},
		{"no room", setting.Declared{
			Name: "test.impossible", Unit: setting.Count, Least: 9, Most: 1, Fallback: 3,
		}},
		{"a fallback it would refuse", setting.Declared{
			Name: "test.contradictory", Unit: setting.Count, Least: 1, Most: 9, Fallback: 40,
		}},
	} {
		t.Run(one.what, func(t *testing.T) {
			if _, err := setting.NewRegistry(one.bad); err == nil {
				t.Fatalf("%s was accepted", one.what)
			}
		})
	}
}

func TestAParameterNobodyHasSetIsWhatTheCodeShippedWith(t *testing.T) {
	pool := testPool(t)
	blank(t, pool)
	store := setting.NewStore(pool, setting.MustRegistry(aPassMark))

	if got := store.Int(context.Background(), aPassMark.Name); got != aPassMark.Fallback {
		t.Fatalf("an unset parameter answered %d, not the %d the code shipped with",
			got, aPassMark.Fallback)
	}
}

func TestAnUndeclaredNameIsRefusedOnTheWayInAndAnsweredWithZero(t *testing.T) {
	pool := testPool(t)
	blank(t, pool)
	store := setting.NewStore(pool, setting.MustRegistry(aPassMark))
	ctx := context.Background()

	if _, err := store.Set(ctx, "test.nothingdeclaresthis", 5); !errors.Is(err, setting.ErrUnknown) {
		t.Fatalf("writing a name nothing declares gave %v, wanted ErrUnknown", err)
	}
	if got := store.Int(ctx, "test.nothingdeclaresthis"); got != 0 {
		t.Fatalf("a name nothing declares answered %d", got)
	}
}

func TestAValueOutsideTheFenceIsRefused(t *testing.T) {
	pool := testPool(t)
	blank(t, pool)
	store := setting.NewStore(pool, setting.MustRegistry(aPassMark))
	ctx := context.Background()

	for _, value := range []int{aPassMark.Least - 1, aPassMark.Most + 1} {
		if _, err := store.Set(ctx, aPassMark.Name, value); !errors.Is(err, setting.ErrOutOfBounds) {
			t.Fatalf("writing %d gave %v, wanted ErrOutOfBounds", value, err)
		}
	}

	if got := store.Int(ctx, aPassMark.Name); got != aPassMark.Fallback {
		t.Fatalf("a refused write moved the value to %d", got)
	}
}

/*
TestWhatSetAnswersIsWhatWasInForceBeforeIt is the audit entry's truth.

	THE FIRST WRITE IS THE INTERESTING ONE. There is no row, so the honest
	answer is the fallback — the number the platform was actually behaving by —
	rather than a zero standing for the absence of a row. An entry reading "70
	→ 80" says what changed; "0 → 80" says a row appeared.
*/
func TestWhatSetAnswersIsWhatWasInForceBeforeIt(t *testing.T) {
	pool := testPool(t)
	blank(t, pool)
	store := setting.NewStore(pool, setting.MustRegistry(aPassMark))
	ctx := context.Background()

	was, err := store.Set(ctx, aPassMark.Name, 80)
	if err != nil {
		t.Fatalf("setting the pass mark: %v", err)
	}
	if was != aPassMark.Fallback {
		t.Fatalf("the first write replaced %d, wanted the %d the code shipped with",
			was, aPassMark.Fallback)
	}

	was, err = store.Set(ctx, aPassMark.Name, 85)
	if err != nil {
		t.Fatalf("setting the pass mark again: %v", err)
	}
	if was != 80 {
		t.Fatalf("the second write replaced %d, wanted 80", was)
	}

	if got := store.Int(ctx, aPassMark.Name); got != 85 {
		t.Fatalf("after two writes the value reads %d, wanted 85", got)
	}
}

/*
TestOneNameIsOneRowHoweverOftenItIsSet is the primary key doing its job.

	A parameter is not a series — the header of `0046` says why, and it comes
	down to the values that needed dating already having their own tables. So
	the table holds one row per name and the history is the audit's.
*/
func TestOneNameIsOneRowHoweverOftenItIsSet(t *testing.T) {
	pool := testPool(t)
	blank(t, pool)
	store := setting.NewStore(pool, setting.MustRegistry(aPassMark))
	ctx := context.Background()

	for _, value := range []int{60, 65, 75} {
		if _, err := store.Set(ctx, aPassMark.Name, value); err != nil {
			t.Fatalf("setting %d: %v", value, err)
		}
	}

	var rows int
	if err := pool.QueryRow(ctx,
		`SELECT count(*) FROM settings WHERE name = $1`, aPassMark.Name).Scan(&rows); err != nil {

		t.Fatalf("counting: %v", err)
	}
	if rows != 1 {
		t.Fatalf("three writes left %d rows", rows)
	}
}

/*
TestARowNothingDeclaresAnyMoreDecidesNothing is the rollback case.

	A deployment that removes a declaration leaves the row behind — deleting
	somebody's setting because a release went backwards would be worse than
	ignoring it — and the same is true of a row written by hand with a value
	the declaration refuses. Both must resolve to the fallback rather than to
	whatever is in the column.
*/
func TestARowNothingDeclaresAnyMoreDecidesNothing(t *testing.T) {
	pool := testPool(t)
	blank(t, pool)
	ctx := context.Background()

	for _, one := range []struct{ name, value string }{
		{"test.retired", "42"},            // nothing declares it
		{aPassMark.Name, "500"},           // outside the fence
		{"test.nonsense", "not-a-number"}, // never came from a write
	} {
		if _, err := pool.Exec(ctx,
			`INSERT INTO settings (name, value) VALUES ($1, $2)`, one.name, one.value); err != nil {

			t.Fatalf("planting %s: %v", one.name, err)
		}
	}

	store := setting.NewStore(pool, setting.MustRegistry(aPassMark))
	if got := store.Int(ctx, aPassMark.Name); got != aPassMark.Fallback {
		t.Fatalf("a row outside the fence answered %d, wanted the fallback %d",
			got, aPassMark.Fallback)
	}
	if got := store.Int(ctx, "test.retired"); got != 0 {
		t.Fatalf("a row nothing declares answered %d", got)
	}
}

func TestNowSaysWhetherAnybodyHasEverDecidedThisOne(t *testing.T) {
	pool := testPool(t)
	blank(t, pool)

	untouched := setting.Declared{
		Name: "test.untouched", Unit: setting.Days, Least: 1, Most: 30, Fallback: 7,
		Why: "a parameter nobody has had an opinion about yet",
	}
	store := setting.NewStore(pool, setting.MustRegistry(aPassMark, untouched))
	ctx := context.Background()

	if _, err := store.Set(ctx, aPassMark.Name, 75); err != nil {
		t.Fatalf("setting the pass mark: %v", err)
	}

	now, err := store.Now(ctx)
	if err != nil {
		t.Fatalf("reading the parameters: %v", err)
	}
	if len(now) != 2 {
		t.Fatalf("%d parameters listed, wanted every declaration", len(now))
	}

	by := map[string]setting.Current{}
	for _, one := range now {
		by[one.Name] = one
	}

	if set := by[aPassMark.Name]; !set.Set || set.Value != 75 || set.Since.IsZero() {
		t.Fatalf("the one that was set reads %+v", set)
	}
	if never := by[untouched.Name]; never.Set || never.Value != untouched.Fallback {
		t.Fatalf("the one nobody touched reads %+v, wanted the fallback and Set false", never)
	}
}
