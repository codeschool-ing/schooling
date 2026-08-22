package analysis_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/codeschool-ing/schooling/internal/analysis"
)

// A funnel over answers handed to it, so what is under test is the folding
// rather than the reading. The stream's own tests cover the query.
func funnelOver(t *testing.T, pool *pgxpool.Pool,
	reaches []analysis.Reach, links map[uuid.UUID]uuid.UUID) *analysis.Store {

	t.Helper()
	return analysis.NewStore(pool, nil, nil).WithStream(
		func(context.Context, uuid.UUID, []string, time.Time,
			analysis.Counting) ([]analysis.Reach, error) {
			return reaches, nil
		},
		func(context.Context) (map[uuid.UUID]uuid.UUID, error) { return links, nil },
	)
}

func reach(name string, visitor, account *uuid.UUID) analysis.Reach {
	return analysis.Reach{Name: name, VisitorID: visitor, AccountID: account}
}

func id() *uuid.UUID { v := uuid.New(); return &v }

func stepNamed(t *testing.T, funnel []analysis.Step, label string) analysis.Step {
	t.Helper()
	for _, s := range funnel {
		if s.Label == label {
			return s
		}
	}
	t.Fatalf("the funnel has no step called %q", label)
	return analysis.Step{}
}

// THE ONE THAT MAKES THE FUNNEL A FUNNEL. Somebody arrives as a browser and
// signs up as an account: counted by whichever identity each event carried,
// they would be two people, and "of those who arrived, how many signed up"
// would be a ratio between different populations.
func TestSomebodyWhoArrivedAndThenSignedUpIsOnePerson(t *testing.T) {
	pool := testPool(t)
	browser, account := id(), id()

	funnel, err := funnelOver(t, pool,
		[]analysis.Reach{
			reach("visitor.arrived", browser, nil),     // before there was an account
			reach("account.created", browser, account), // the moment of signing up
			reach("section.completed", nil, account),   // afterwards, account only
		},
		map[uuid.UUID]uuid.UUID{*browser: *account},
	).Funnel(context.Background(), uuid.New(), time.Time{}, analysis.CountingReal)
	if err != nil {
		t.Fatal(err)
	}

	for _, label := range []string{"Arrived", "Created an account", "Finished the first section"} {
		if got := stepNamed(t, funnel, label).People; got != 1 {
			t.Errorf("%q counted %d people; it is one person the whole way down", label, got)
		}
	}
}

// AND A BROWSER THAT NEVER SIGNED UP IS STILL A PERSON. They are most of the
// top of the funnel, and dropping them would make the conversion rate look
// perfect by counting only the people who converted.
func TestABrowserWithNoAccountIsCounted(t *testing.T) {
	pool := testPool(t)
	first, second := id(), id()

	funnel, err := funnelOver(t, pool, []analysis.Reach{
		reach("visitor.arrived", first, nil),
		reach("visitor.arrived", second, nil),
	}, nil).Funnel(context.Background(), uuid.New(), time.Time{}, analysis.CountingReal)
	if err != nil {
		t.Fatal(err)
	}

	if got := stepNamed(t, funnel, "Arrived").People; got != 2 {
		t.Errorf("two browsers with no account counted as %d people", got)
	}
}

// ONE PERSON ON TWO BROWSERS IS ONE PERSON. Somebody who reads on a phone and
// subscribes on a laptop is not two arrivals and half a conversion.
func TestOnePersonOnTwoBrowsersIsCountedOnce(t *testing.T) {
	pool := testPool(t)
	phone, laptop, account := id(), id(), id()

	funnel, err := funnelOver(t, pool,
		[]analysis.Reach{
			reach("visitor.arrived", phone, nil),
			reach("visitor.arrived", laptop, nil),
			reach("lesson.opened", phone, account),
			reach("lesson.opened", laptop, account),
		},
		map[uuid.UUID]uuid.UUID{*phone: *account, *laptop: *account},
	).Funnel(context.Background(), uuid.New(), time.Time{}, analysis.CountingReal)
	if err != nil {
		t.Fatal(err)
	}

	if got := stepNamed(t, funnel, "Arrived").People; got != 1 {
		t.Errorf("one person on two browsers arrived %d times", got)
	}
	if got := stepNamed(t, funnel, "Opened the first lesson").People; got != 1 {
		t.Errorf("one person opening lessons on two browsers counted as %d", got)
	}
}

// DOING SOMETHING FORTY TIMES IS DOING IT. A funnel asks how many people got
// this far, and somebody who opened forty lessons is one of them.
func TestDoingAStepRepeatedlyCountsOnce(t *testing.T) {
	pool := testPool(t)
	browser := id()

	var many []analysis.Reach
	for range 40 {
		many = append(many, reach("lesson.opened", browser, nil))
	}

	funnel, err := funnelOver(t, pool, many, nil).
		Funnel(context.Background(), uuid.New(), time.Time{}, analysis.CountingReal)
	if err != nil {
		t.Fatal(err)
	}
	if got := stepNamed(t, funnel, "Opened the first lesson").People; got != 1 {
		t.Errorf("one browser opening forty lessons counted as %d people", got)
	}
}

// A STEP WITH NO EVENT IS NOT A STEP WITH NOBODY.
//
// Two of the eight cannot be emitted: verifying an address has no feature, and
// subscribing has no gateway. Reported as a zero they would read as everybody
// dropping out there — the same mistake as a discrimination index of zero that
// was never measured — so they say what is missing instead.
func TestTheStepsNothingEmitsSayThatRatherThanZero(t *testing.T) {
	pool := testPool(t)

	funnel, err := funnelOver(t, pool, nil, nil).
		Funnel(context.Background(), uuid.New(), time.Time{}, analysis.CountingReal)
	if err != nil {
		t.Fatal(err)
	}
	if len(funnel) != 8 {
		t.Fatalf("the funnel has %d steps, want the eight the product has", len(funnel))
	}

	for _, label := range []string{"Verified the address", "Subscribed"} {
		step := stepNamed(t, funnel, label)
		if step.Measured {
			t.Errorf("%q says it is measured, and nothing emits it", label)
		}
		if step.Why == "" {
			t.Errorf("%q is unmeasured and says nothing about why", label)
		}
		if step.Event != "" {
			t.Errorf("%q names the event %q, which nothing writes", label, step.Event)
		}
	}

	// And a step that IS measured says so, even at zero — which is the
	// distinction this whole field exists to make.
	arrived := stepNamed(t, funnel, "Arrived")
	if !arrived.Measured {
		t.Error("`Arrived` says it is not measured")
	}
	if arrived.People != 0 {
		t.Errorf("nobody arrived and it counted %d", arrived.People)
	}
}

// EVERY STEP APPEARS, IN ORDER, WHATEVER THE STREAM CONTAINS. A funnel that
// showed only the steps somebody reached would hide exactly the drop somebody
// is looking for.
func TestEveryStepAppearsInOrderEvenWithNoData(t *testing.T) {
	pool := testPool(t)

	funnel, err := funnelOver(t, pool,
		[]analysis.Reach{reach("course.completed", id(), nil)}, nil).
		Funnel(context.Background(), uuid.New(), time.Time{}, analysis.CountingReal)
	if err != nil {
		t.Fatal(err)
	}

	want := []string{
		"Arrived", "Created an account", "Verified the address", "Chose a track",
		"Opened the first lesson", "Finished the first section",
		"Finished the free course", "Subscribed",
	}
	if len(funnel) != len(want) {
		t.Fatalf("the funnel has %d steps", len(funnel))
	}
	for i, label := range want {
		if funnel[i].Label != label {
			t.Errorf("step %d is %q, want %q — the order is the product, not the data",
				i+1, funnel[i].Label, label)
		}
	}
}

// An event carrying neither identity belongs to nobody, and counting it as an
// anonymous person would inflate every step it lands in.
func TestAnEventWithNobodyOnItIsNotAPerson(t *testing.T) {
	pool := testPool(t)

	funnel, err := funnelOver(t, pool,
		[]analysis.Reach{reach("visitor.arrived", nil, nil)}, nil).
		Funnel(context.Background(), uuid.New(), time.Time{}, analysis.CountingReal)
	if err != nil {
		t.Fatal(err)
	}
	if got := stepNamed(t, funnel, "Arrived").People; got != 0 {
		t.Errorf("an event with no identity on it counted as %d people", got)
	}
}

// A store with nowhere to read from refuses rather than answering an empty
// funnel, which would read as a school where nobody has ever done anything.
func TestAFunnelWithNoStreamRefuses(t *testing.T) {
	pool := testPool(t)

	if _, err := analysis.NewStore(pool, nil, nil).
		Funnel(context.Background(), uuid.New(), time.Time{}, analysis.CountingReal); err == nil {
		t.Error("a funnel was produced by a store with no stream behind it")
	}
}

// THE POPULATION HAS TO REACH THE STREAM, and nothing else in the funnel can
// tell whether it did: the arithmetic above it is the same whichever people it
// is counting, so a reader that dropped the argument would pass every test in
// this file and quietly report real students under a heading that said seeded.
func TestThePopulationAskedForIsThePopulationRead(t *testing.T) {
	pool := testPool(t)

	for _, who := range []analysis.Counting{
		analysis.CountingReal, analysis.CountingSeeded, analysis.CountingEverybody,
	} {
		var asked analysis.Counting
		store := analysis.NewStore(pool, nil, nil).WithStream(
			func(_ context.Context, _ uuid.UUID, _ []string, _ time.Time,
				w analysis.Counting) ([]analysis.Reach, error) {
				asked = w
				return nil, nil
			},
			func(context.Context) (map[uuid.UUID]uuid.UUID, error) { return nil, nil },
		)

		if _, err := store.Funnel(context.Background(), uuid.New(), time.Time{}, who); err != nil {
			t.Fatal(err)
		}
		if asked != who {
			t.Errorf("the funnel was asked for %q and read %q", who, asked)
		}
	}
}

// A WORD THAT IS NOT ONE OF THE THREE IS REFUSED RATHER THAN CORRECTED.
//
// The SQL falls back to real people for anything it does not know, which is the
// safe direction and the wrong answer for a caller that took the word from a
// request: `everbody` would draw real people under a switch saying otherwise.
// So the reading is separate from the counting, and it says which happened.
func TestAWordThatIsNotAPopulationIsRefusedAndFallsToReal(t *testing.T) {
	for _, word := range []string{"real", "seeded", "everybody"} {
		if who, known := analysis.Reading(word); !known || string(who) != word {
			t.Errorf("%q is a population and Reading said (%q, %v)", word, who, known)
		}
	}

	for _, word := range []string{"everbody", "REAL", "", "synthetic", "all"} {
		who, known := analysis.Reading(word)
		if known {
			t.Errorf("%q is not one of the three and Reading accepted it", word)
		}
		if who != analysis.CountingReal {
			t.Errorf("%q fell back to %q — an unknown word narrows the population, "+
				"it never widens it", word, who)
		}
	}
}
