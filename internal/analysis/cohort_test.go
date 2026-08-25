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
	return analysis.NewStore(nil, nil, nil).WithStream(
		func(context.Context, uuid.UUID, []string, time.Time,
			analysis.Counting) ([]analysis.Reach, error) {
			return nil, nil
		},
		func(_ context.Context, _ uuid.UUID, names []string, _ time.Time,
			_ analysis.Counting) ([]analysis.Active, error) {
			if len(names) == 1 && names[0] == analysis.SignupEvent {
				return signups, nil
			}
			return studied, nil
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
		Cohorts(context.Background(), uuid.New(), 12, month(2026, time.May), analysis.CountingReal)
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
		month(2026, time.March), analysis.CountingReal)
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
		Cohorts(context.Background(), uuid.New(), 24, month(2026, time.June), analysis.CountingReal)
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
		Cohorts(context.Background(), uuid.New(), 24, month(2026, time.May), analysis.CountingReal)
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
		month(2026, time.March), analysis.CountingReal)
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
	).Cohorts(context.Background(), uuid.New(), 12, month(2026, time.April), analysis.CountingReal)
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
		month(2027, time.January), analysis.CountingReal)
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
		month(2026, time.December), analysis.CountingReal)
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
			analysis.CountingReal); err == nil {
		t.Error("a store with no stream answered a cohort table instead of refusing")
	}
}
