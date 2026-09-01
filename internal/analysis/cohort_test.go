package analysis_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/analysis"
)

/* Cohorts, over activity handed to the store, so what is under test is the
   arithmetic and not the reading. The stream's own tests cover the query.

   EVERY FAILURE THIS FILE DESCRIBES LOOKS LIKE A WORKING TABLE. A retention
   report is numbers in a grid: put somebody in the wrong column, count them
   twice, pad a row with zeroes, and it still renders, still trends downward, and
   still gets read out in a meeting. There is nothing on the screen that says it
   is wrong, which is why these are asserted rather than eyeballed. */

func month(y int, m time.Month) time.Time {
	return time.Date(y, m, 1, 0, 0, 0, 0, time.UTC)
}

/* EVERY TEST NAMES THE MONTH ITS TABLE IS DRAWN IN, rather than reading a clock.

   How wide a row is depends on how much time has passed since that intake, so a
   test on `time.Now()` would assert a different shape every month — passing in
   August and failing in September, which is the kind of test somebody eventually
   deletes instead of reading. Naming it also puts the calendar beside the data
   it is being compared against, which is where the reader needs it. */

func active(at time.Time, account *uuid.UUID) analysis.Active {
	return analysis.Active{Month: at, AccountID: account}
}

/*
NO DATABASE, ON PURPOSE, AND THIS FILE IS THE ONLY ONE HERE THAT NEEDS NONE.

	`Cohorts` never touches the pool: it asks the two readers for months and folds
	them. Handing it a real Postgres would mean these tests SKIP on any machine
	without one — and the folding is the part most likely to be quietly wrong, so
	it is the part that should be checked everywhere rather than only in CI.

	The nil pool is deliberate and is its own assertion: if this ever starts
	reading a table, it panics here instead of passing. A loud failure on a
	changed assumption beats a silent one.
*/
func cohortsOver(t *testing.T, signups, studied []analysis.Active,
	links map[uuid.UUID]uuid.UUID) *analysis.Store {

	t.Helper()
	return cohortsAlso(t, signups, studied, nil, links)
}

// cohortsAlso is the same with the platform reader filled in, for the tests
// about grouping by when somebody started paying.
//
// THE TWO READERS RETURN DISJOINT SETS, the way the real ones do: a
// subscription carries no tenant, so `monthly` cannot see it and only
// `monthlyAnywhere` can. A harness that handed the same rows to both would let
// a fold that read the wrong one pass.
func cohortsAlso(t *testing.T, signups, studied, paid []analysis.Active,
	links map[uuid.UUID]uuid.UUID) *analysis.Store {

	t.Helper()
	return analysis.NewStore(nil, nil, nil).WithStream(
		func(context.Context, uuid.UUID, []string, time.Time,
			analysis.Counting) ([]analysis.Reach, error) {
			return nil, nil
		},
		nil, // a cohort reads no platform step; `funnel_test.go` covers that one
		func(_ context.Context, _ uuid.UUID, names []string, _ time.Time,
			_ analysis.Counting) ([]analysis.Active, error) {
			if len(names) == 1 && names[0] == analysis.SignupEvent {
				return signups, nil
			}
			return studied, nil
		},
		func(_ context.Context, names []string, _ time.Time,
			_ analysis.Counting) ([]analysis.Active, error) {
			if len(names) == 1 && names[0] == analysis.SubscribedEvent {
				return paid, nil
			}
			return nil, nil
		},
		nil, // a cohort does not read where anybody was; `countries_test.go` does
		func(context.Context) (map[uuid.UUID]uuid.UUID, error) { return links, nil },
	)
}

func cohortOf(t *testing.T, all []analysis.Cohort, at time.Time) analysis.Cohort {
	t.Helper()
	for _, c := range all {
		if c.Month.Equal(at) {
			return c
		}
	}
	t.Fatalf("there is no cohort for %s", at.Format("2006-01"))
	return analysis.Cohort{}
}

// THE SHAPE THE WHOLE REPORT EXISTS FOR: one intake, followed forward, thinning.
func TestAnIntakeIsFollowedForwardAndThins(t *testing.T) {
	a, b, c := id(), id(), id()

	signups := []analysis.Active{
		active(month(2026, time.March), a),
		active(month(2026, time.March), b),
		active(month(2026, time.March), c),
	}
	studied := []analysis.Active{
		// All three studied in the month they joined.
		active(month(2026, time.March), a),
		active(month(2026, time.March), b),
		active(month(2026, time.March), c),
		// Two came back the month after, one the month after that.
		active(month(2026, time.April), a),
		active(month(2026, time.April), b),
		active(month(2026, time.May), a),
	}

	all, err := cohortsOver(t, signups, studied, nil).
		Cohorts(context.Background(), uuid.New(), 12, month(2026, time.May), analysis.CountingReal, analysis.BySignup)
	if err != nil {
		t.Fatal(err)
	}
	if len(all) != 1 {
		t.Fatalf("one intake produced %d cohorts", len(all))
	}

	march := all[0]
	if march.People != 3 {
		t.Errorf("three people signed up in March and the cohort holds %d", march.People)
	}
	if want := []int{3, 2, 1}; len(march.Active) != len(want) {
		t.Fatalf("March is three months old and carries %d months: %v",
			len(march.Active), march.Active)
	} else {
		for i, n := range want {
			if march.Active[i] != n {
				t.Errorf("month %d of March counted %d, want %d — %v",
					i, march.Active[i], n, march.Active)
			}
		}
	}
}

// STUDYING TWICE IN A MONTH IS STUDYING ONCE. A cohort cell is people, not
// events — counting rows would let one enthusiastic student make a month look
// like retention.
func TestStudyingRepeatedlyInAMonthCountsThePersonOnce(t *testing.T) {
	a := id()

	studied := []analysis.Active{
		active(month(2026, time.March), a),
		active(month(2026, time.March), a),
		active(month(2026, time.March), a),
	}
	all, err := cohortsOver(t, []analysis.Active{active(month(2026, time.March), a)},
		studied, nil).Cohorts(context.Background(), uuid.New(), 12,
		month(2026, time.March), analysis.CountingReal, analysis.BySignup)
	if err != nil {
		t.Fatal(err)
	}
	if got := cohortOf(t, all, month(2026, time.March)).Active[0]; got != 1 {
		t.Errorf("one person studying three times counted as %d", got)
	}
}

// THE TABLE IS TRIANGULAR, AND THAT IS THE POINT.
//
// A cohort is followed as far as it is old and no further. Padding every row to
// the same width would put zeroes where nothing has happened YET, and a zero in
// a retention table reads as everybody having left — the same mistake the
// funnel's unmeasured steps exist to avoid.
func TestANewCohortIsNotPaddedWithZeroes(t *testing.T) {
	old, recent := id(), id()

	signups := []analysis.Active{
		active(month(2026, time.January), old),
		active(month(2026, time.June), recent),
	}
	all, err := cohortsOver(t, signups, nil, nil).
		Cohorts(context.Background(), uuid.New(), 24, month(2026, time.June), analysis.CountingReal, analysis.BySignup)
	if err != nil {
		t.Fatal(err)
	}

	january := cohortOf(t, all, month(2026, time.January))
	june := cohortOf(t, all, month(2026, time.June))

	if len(january.Active) != 6 {
		t.Errorf("January is six months old and carries %d months", len(january.Active))
	}
	if len(june.Active) != 1 {
		t.Errorf("June is the newest intake and carries %d months — every one after the "+
			"first is a zero for a month that has not happened", len(june.Active))
	}
}

// COHORTS COME BACK OLDEST FIRST, because that is the order the table is read
// in and an order decided by a map is an order that changes between runs.
func TestCohortsAreOrderedOldestFirst(t *testing.T) {

	var signups []analysis.Active
	for _, m := range []time.Month{time.May, time.January, time.March} {
		signups = append(signups, active(month(2026, m), id()))
	}
	all, err := cohortsOver(t, signups, nil, nil).
		Cohorts(context.Background(), uuid.New(), 24, month(2026, time.May), analysis.CountingReal, analysis.BySignup)
	if err != nil {
		t.Fatal(err)
	}
	if len(all) != 3 {
		t.Fatalf("three intakes produced %d cohorts", len(all))
	}
	for i := 1; i < len(all); i++ {
		if !all[i-1].Month.Before(all[i].Month) {
			t.Errorf("cohort %d (%s) is not before cohort %d (%s)",
				i-1, all[i-1].Month.Format("2006-01"), i, all[i].Month.Format("2006-01"))
		}
	}
}

// SOMEBODY WHO STUDIED HERE WITHOUT SIGNING UP HERE IS IN NO COHORT.
//
// Not in the newest, not in the oldest, not in one of their own. Every cell is a
// share of an intake, so a numerator with nobody under it is a percentage of
// nothing — and it would land in whichever cohort the code happened to reach for.
func TestStudyingWithoutSigningUpBelongsToNoCohort(t *testing.T) {
	member, stranger := id(), id()

	all, err := cohortsOver(t,
		[]analysis.Active{active(month(2026, time.March), member)},
		[]analysis.Active{
			active(month(2026, time.March), member),
			active(month(2026, time.March), stranger),
		}, nil).Cohorts(context.Background(), uuid.New(), 12,
		month(2026, time.March), analysis.CountingReal, analysis.BySignup)
	if err != nil {
		t.Fatal(err)
	}

	march := cohortOf(t, all, month(2026, time.March))
	if march.People != 1 {
		t.Errorf("one person signed up and the cohort holds %d", march.People)
	}
	if march.Active[0] != 1 {
		t.Errorf("one member studied and the cell says %d — the stranger was counted "+
			"into an intake they are not part of", march.Active[0])
	}
}

// A BROWSER AND AN ACCOUNT ARE ONE PERSON, exactly as in the funnel. Somebody
// who signed up and whose studying was recorded against their visitor id has
// studied, and a cohort that lost that would report a retention of zero for
// people who never left.
func TestActivityUnderAVisitorCountsForTheirAccount(t *testing.T) {
	browser, account := id(), id()

	all, err := cohortsOver(t,
		[]analysis.Active{active(month(2026, time.March), account)},
		[]analysis.Active{{Month: month(2026, time.April), VisitorID: browser}},
		map[uuid.UUID]uuid.UUID{*browser: *account},
	).Cohorts(context.Background(), uuid.New(), 12, month(2026, time.April), analysis.CountingReal, analysis.BySignup)
	if err != nil {
		t.Fatal(err)
	}

	march := cohortOf(t, all, month(2026, time.March))
	if len(march.Active) < 2 || march.Active[1] != 1 {
		t.Errorf("studying under a linked visitor did not count for the account: %v",
			march.Active)
	}
}

// THE AGE IS COUNTED IN MONTHS AND NOT IN THIRTY-DAY BLOCKS.
//
// Dividing a duration drifts — months are not the same length — and the drift
// puts a person in the column beside the right one, which nothing about the
// output would reveal. February is where it shows first.
func TestTheAgeOfACohortIsWholeMonths(t *testing.T) {
	a := id()

	all, err := cohortsOver(t,
		[]analysis.Active{active(month(2026, time.January), a)},
		[]analysis.Active{
			active(month(2026, time.February), a), // one month later, 28 days
			active(month(2027, time.January), a),  // a year later exactly
		}, nil).Cohorts(context.Background(), uuid.New(), 24,
		month(2027, time.January), analysis.CountingReal, analysis.BySignup)
	if err != nil {
		t.Fatal(err)
	}

	january := cohortOf(t, all, month(2026, time.January))
	if january.Active[1] != 1 {
		t.Errorf("February is month 1 of a January cohort and it counted %d: %v",
			january.Active[1], january.Active)
	}
	if january.Active[12] != 1 {
		t.Errorf("the next January is month 12 and it counted %d: %v",
			january.Active[12], january.Active)
	}
}

// The window bounds how far any cohort is followed, so the oldest one does not
// grow a column a month forever.
func TestACohortIsNotFollowedPastTheWindow(t *testing.T) {
	a := id()

	all, err := cohortsOver(t,
		[]analysis.Active{active(month(2026, time.January), a)},
		[]analysis.Active{active(month(2026, time.December), a)},
		nil).Cohorts(context.Background(), uuid.New(), 3,
		month(2026, time.December), analysis.CountingReal, analysis.BySignup)
	if err != nil {
		t.Fatal(err)
	}

	january := cohortOf(t, all, month(2026, time.January))
	if len(january.Active) != 3 {
		t.Errorf("a window of three months produced %d columns", len(january.Active))
	}
	for i, n := range january.Active {
		if n != 0 {
			t.Errorf("month %d counted %d, and the only activity is past the window", i, n)
		}
	}
}

// A store without the stream refuses rather than answering an empty table, which
// would read as a school where nobody ever signed up.
func TestCohortsWithoutTheStreamRefuse(t *testing.T) {

	if _, err := analysis.NewStore(nil, nil, nil).
		Cohorts(context.Background(), uuid.New(), 12, month(2026, time.March),
			analysis.CountingReal, analysis.BySignup); err == nil {
		t.Error("a store with no stream answered a cohort table instead of refusing")
	}
}

/*
GROUPING BY SUBSCRIPTION DATES PEOPLE BY WHEN THEY PAID, NOT BY WHEN THEY JOINED.

	It is the whole of the second basis: the same people, in different rows.
	Somebody who signed up in March and started paying in May belongs to May's
	cohort here and to March's on the other basis, and their activity is
	measured from whichever the table is counting from.
*/
func TestGroupingBySubscriptionUsesTheMonthTheyStartedPaying(t *testing.T) {
	person := who()

	all, err := cohortsAlso(t,
		[]analysis.Active{active(month(2026, time.March), person)},
		[]analysis.Active{
			active(month(2026, time.May), person),
			active(month(2026, time.June), person),
		},
		[]analysis.Active{active(month(2026, time.May), person)},
		nil,
	).Cohorts(context.Background(), uuid.New(), 12,
		month(2026, time.June), analysis.CountingReal, analysis.BySubscription)
	if err != nil {
		t.Fatal(err)
	}

	if len(all) != 1 {
		t.Fatalf("one subscriber produced %d cohorts", len(all))
	}
	if got := all[0].Month; !got.Equal(month(2026, time.May)) {
		t.Errorf("the cohort is dated %s; they started paying in May and signed up in March",
			got.Format("2006-01"))
	}

	// And the columns are counted from May: active in May is month zero.
	c := cohortOf(t, all, month(2026, time.May))
	if len(c.Active) < 2 || c.Active[0] != 1 || c.Active[1] != 1 {
		t.Errorf("the row reads %v; they studied in May and June, which from a May "+
			"cohort is months zero and one", c.Active)
	}
}

/*
AND SOMEBODY WHO NEVER PAID IS NOT IN THE TABLE AT ALL.

	Not a zero, and not a cohort of their own. The population this basis is
	about is the people who started paying; anybody else is outside it, and
	putting them in would make a denominator nobody is under — the same mistake
	the signup basis avoids by dropping people who studied here without ever
	signing up here.
*/
func TestSomebodyWhoNeverPaidIsNotInASubscriptionCohort(t *testing.T) {
	payer, freeloader := who(), who()

	all, err := cohortsAlso(t,
		[]analysis.Active{
			active(month(2026, time.March), payer),
			active(month(2026, time.March), freeloader),
		},
		[]analysis.Active{
			active(month(2026, time.April), payer),
			active(month(2026, time.April), freeloader),
		},
		[]analysis.Active{active(month(2026, time.April), payer)},
		nil,
	).Cohorts(context.Background(), uuid.New(), 12,
		month(2026, time.April), analysis.CountingReal, analysis.BySubscription)
	if err != nil {
		t.Fatal(err)
	}

	if len(all) != 1 {
		t.Fatalf("one payer and one who never paid produced %d cohorts", len(all))
	}
	if all[0].People != 1 {
		t.Errorf("the April intake has %d people; only one of the two ever paid",
			all[0].People)
	}
}

/*
A SUBSCRIBER WHO IS NOT THIS SCHOOL'S IS NOT THIS SCHOOL'S COHORT.

	THIS IS THE ONE THAT WOULD HAVE CAUGHT THE OBVIOUS MISTAKE. A subscription
	covers every school (N-02) and carries no tenant, so the reader for it comes
	back with every subscriber on the platform. Folding that in without checking
	membership would give every school the same intake — eight schools each
	reporting the platform's subscribers as their own, and every number
	plausible. Membership comes from having signed up HERE, which is the only
	school-scoped fact there is.
*/
func TestASubscriberWhoNeverSignedUpHereIsNotInTheTable(t *testing.T) {
	ours, stranger := who(), who()

	all, err := cohortsAlso(t,
		[]analysis.Active{active(month(2026, time.March), ours)},
		[]analysis.Active{active(month(2026, time.April), ours)},
		[]analysis.Active{
			active(month(2026, time.April), ours),
			active(month(2026, time.April), stranger), // subscribed, never here
		},
		nil,
	).Cohorts(context.Background(), uuid.New(), 12,
		month(2026, time.April), analysis.CountingReal, analysis.BySubscription)
	if err != nil {
		t.Fatal(err)
	}

	if len(all) != 1 {
		t.Fatalf("produced %d cohorts", len(all))
	}
	if all[0].People != 1 {
		t.Errorf("the intake has %d people; one of the two subscribers had never been "+
			"near this school, and a table that counts them is the platform's rather "+
			"than this school's", all[0].People)
	}
}

/*
THE EARLIEST SUBSCRIPTION WINS, which matters more here than on the other basis.

	An account is created once; a subscription is started, refunded and started
	again by the same person, and the seeder produces exactly that. Taking the
	latest would move somebody forward into a younger cohort every time they came
	back — quietly shrinking the old intakes and inflating the new ones, which is
	the shape a retention table is read for.
*/
func TestTheFirstSubscriptionIsTheOneThatDatesTheCohort(t *testing.T) {
	person := who()

	all, err := cohortsAlso(t,
		[]analysis.Active{active(month(2026, time.January), person)},
		[]analysis.Active{active(month(2026, time.March), person)},
		[]analysis.Active{
			active(month(2026, time.May), person),   // came back
			active(month(2026, time.March), person), // and the first time
		},
		nil,
	).Cohorts(context.Background(), uuid.New(), 12,
		month(2026, time.June), analysis.CountingReal, analysis.BySubscription)
	if err != nil {
		t.Fatal(err)
	}

	if len(all) != 1 {
		t.Fatalf("one person produced %d cohorts", len(all))
	}
	if got := all[0].Month; !got.Equal(month(2026, time.March)) {
		t.Errorf("the cohort is dated %s, and they first paid in March",
			got.Format("2006-01"))
	}
}

// A STORE THAT CANNOT READ THE PLATFORM'S EVENTS REFUSES THIS BASIS RATHER THAN
// ANSWERING AN EMPTY TABLE. An empty table reads as "nobody ever subscribed",
// which is a claim about students rather than about a store that was wired with
// four readers out of five.
func TestGroupingBySubscriptionRefusesWithoutThePlatformReader(t *testing.T) {
	/* BUILT WITHOUT IT HERE RATHER THAN THROUGH THE HELPER, which always
	   supplies the reader — a store that has one and is handed no rows is a
	   different thing from a store that cannot read at all, and this test is
	   about the second. */
	store := analysis.NewStore(nil, nil, nil).WithStream(
		func(context.Context, uuid.UUID, []string, time.Time,
			analysis.Counting) ([]analysis.Reach, error) {
			return nil, nil
		},
		nil,
		func(_ context.Context, _ uuid.UUID, _ []string, _ time.Time,
			_ analysis.Counting) ([]analysis.Active, error) {
			return []analysis.Active{active(month(2026, time.March), who())}, nil
		},
		nil, // the platform reader this basis needs, deliberately absent
		nil,
		func(context.Context) (map[uuid.UUID]uuid.UUID, error) { return nil, nil },
	)

	_, err := store.Cohorts(context.Background(), uuid.New(), 12,
		month(2026, time.April), analysis.CountingReal, analysis.BySubscription)
	if err == nil {
		t.Error("a store with no platform reader answered a subscription cohort, and " +
			"the only answer it could have given is an empty one")
	}
}

// AND THE WORD IS REFUSED RATHER THAN CORRECTED, the same rule `Reading` is
// under: falling back to signups would draw the larger population under a
// heading somebody chose to say otherwise.
func TestAWordThatIsNotABasisIsRefusedAndFallsToSignup(t *testing.T) {
	for _, word := range []string{"signup", "subscription"} {
		if got, known := analysis.Grouping(word); !known || string(got) != word {
			t.Errorf("%q is a basis and Grouping said (%q, %v)", word, got, known)
		}
	}
	if got, known := analysis.Grouping("whenever"); known {
		t.Errorf("%q was accepted as a basis", "whenever")
	} else if got != analysis.BySignup {
		t.Errorf("the refusal fell back to %q, and the safe answer is the larger "+
			"population", got)
	}
}

// who is one person's account id, as a pointer, which is what `Active` carries.
func who() *uuid.UUID { v := uuid.New(); return &v }
