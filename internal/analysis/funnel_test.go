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

	/* THE ONE LIST IS SPLIT THE WAY THE REAL READERS SPLIT IT, by the name each
	   reach carries. A test can write `reach(subscribed, …)` beside the other
	   seven without knowing which query would have produced it — and the two
	   readers still see disjoint sets, so a fold that took the platform's
	   events without narrowing them to this school's people fails here rather
	   than passing because the harness handed it the same slice twice. */
	only := func(platform bool) []analysis.Reach {
		var out []analysis.Reach
		for _, r := range reaches {
			if (r.Name == subscribed) == platform {
				out = append(out, r)
			}
		}
		return out
	}

	return analysis.NewStore(pool, nil, nil).WithStream(
		func(context.Context, uuid.UUID, []string, time.Time,
			analysis.Counting) ([]analysis.Reach, error) {
			return only(false), nil
		},
		func(context.Context, []string, time.Time,
			analysis.Counting) ([]analysis.Reach, error) {
			return only(true), nil
		},
		nil, // the funnel reads neither months nor countries; `cohort_test.go`
		nil, // and `countries_test.go` cover those three readers
		nil,
		func(context.Context) (map[uuid.UUID]uuid.UUID, error) { return links, nil },
	)
}

// The step that belongs to no school, named here because these tests are about
// what the funnel does with it.
const subscribed = "subscription.started"

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
/*
A step nothing emits says so rather than reporting a zero.

	WHY THIS LOOKS LIKE A RULE AND NOT A LIST. It used to name the steps that
	could not be emitted — first two of them, then one — and it had to be edited
	every time one of them started being measured. The last edit is what
	prompted this: "Subscribed" became measurable, the test failed, and a test
	that fails because the product improved is a test that will eventually be
	made to pass by deleting the assertion.

	TODAY EVERY STEP IS MEASURED, so the list would be empty and a loop over it
	would check nothing at all. What is checked instead is the INVARIANT the
	`Measured` field exists for, which holds however many are in each class: a
	step either names an event and is measured, or names none and says why. The
	state that must never exist is a step reporting a confident zero for
	something nobody counts, and that is what the third branch catches.
*/
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

	for _, step := range funnel {
		switch {
		case step.Event != "" && !step.Measured:
			t.Errorf("%q names the event %q and says it is not measured",
				step.Label, step.Event)
		case step.Event == "" && step.Measured:
			t.Errorf("%q says it is measured and names no event, so its zero is a "+
				"claim nothing counted", step.Label)
		case step.Event == "" && step.Why == "":
			t.Errorf("%q is unmeasured and says nothing about why, which on a screen "+
				"is indistinguishable from everybody dropping out there", step.Label)
		}
	}

	// And a step that IS measured says so AT ZERO, which is the distinction the
	// whole field exists to make: nobody got here, and nobody counts this, are
	// different answers that look identical as a number.
	arrived := stepNamed(t, funnel, "Arrived")
	if !arrived.Measured {
		t.Error("`Arrived` says it is not measured")
	}
	if arrived.People != 0 {
		t.Errorf("nobody arrived and it counted %d", arrived.People)
	}
}

/*
The last step counts subscribers this school has actually seen, and no others.

	THIS IS THE ONE THAT WOULD HAVE CAUGHT THE FIRST VERSION. A subscription
	belongs to no school (N-02), so the reader for that step returns every
	subscriber on the platform — and folding them in beside the school's own
	steps, which is what the first draft did, gave every school credit for every
	subscription on the platform. Eight schools would each have reported the
	same conversions and every one of the numbers would have looked plausible.
*/
func TestTheLastStepCountsOnlySubscribersThisSchoolHasSeen(t *testing.T) {
	pool := testPool(t)

	ours, stranger := id(), id()

	funnel, err := funnelOver(t, pool,
		[]analysis.Reach{
			reach("visitor.arrived", nil, ours),
			reach(subscribed, nil, ours),

			// Somebody who subscribed and was never at this school. The
			// platform-wide reader returns them; this funnel must not.
			reach(subscribed, nil, stranger),
		},
		nil,
	).Funnel(context.Background(), uuid.New(), time.Time{}, analysis.CountingReal)
	if err != nil {
		t.Fatal(err)
	}

	step := stepNamed(t, funnel, "Subscribed")
	if !step.Measured {
		t.Fatal("`Subscribed` is not measured, and something emits it now")
	}
	if step.People != 1 {
		t.Errorf("`Subscribed` counted %d people; one of the two subscribers "+
			"had never been near this school", step.People)
	}
}

/*
Somebody this school saw only in the middle of the funnel still counts as
having subscribed.

	`visitor.arrived` IS THE STEP MOST LIKELY TO BE MISSING. It is emitted for a
	signed-out browser before any account exists (K-10), which is exactly when a
	blocked script, a direct link or a cold cache loses it — so requiring it as
	the ticket into the last step would drop somebody from the bottom of the
	funnel while leaving them in the middle of it, and the chart would show a
	drop-off that the rows above it contradict.
*/
func TestSubscribingCountsForSomebodyWhoseArrivalWasNeverRecorded(t *testing.T) {
	pool := testPool(t)
	student := id()

	funnel, err := funnelOver(t, pool,
		[]analysis.Reach{
			reach("lesson.opened", nil, student), // seen here, plainly
			reach(subscribed, nil, student),
		},
		nil,
	).Funnel(context.Background(), uuid.New(), time.Time{}, analysis.CountingReal)
	if err != nil {
		t.Fatal(err)
	}

	if got := stepNamed(t, funnel, "Subscribed").People; got != 1 {
		t.Errorf("`Subscribed` counted %d; somebody who opened a lesson here is "+
			"somebody this school has seen, arrival event or not", got)
	}
}

/*
A browser that arrived and an account that subscribed are one person.

	IT IS THE FUNNEL'S WHOLE PREMISE APPLIED ACROSS THE BOUNDARY THIS BRANCH
	ADDED. `personOf` has said since before there was anything to subscribe to
	that this is "how an arrival on Monday and a subscription on Friday become
	the same person" — and until now nothing exercised it, because the two
	events could not both exist. Counted by the identity each one carried they
	are two people, and the last step would report somebody this school never
	saw arrive.
*/
func TestAnArrivalAndASubscriptionAreOnePersonAcrossTheBoundary(t *testing.T) {
	pool := testPool(t)
	browser, account := id(), id()

	funnel, err := funnelOver(t, pool,
		[]analysis.Reach{
			reach("visitor.arrived", browser, nil), // signed out, no account yet
			reach(subscribed, nil, account),        // months later, signed in
		},
		map[uuid.UUID]uuid.UUID{*browser: *account},
	).Funnel(context.Background(), uuid.New(), time.Time{}, analysis.CountingReal)
	if err != nil {
		t.Fatal(err)
	}

	if got := stepNamed(t, funnel, "Arrived").People; got != 1 {
		t.Errorf("`Arrived` counted %d", got)
	}
	if got := stepNamed(t, funnel, "Subscribed").People; got != 1 {
		t.Errorf("`Subscribed` counted %d; the browser that arrived and the account "+
			"that subscribed are one person, and the link says so", got)
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
		/* BOTH READERS, because there are two now and the second is the easier
		   one to drop it in: it takes no school, so a closure that forgot the
		   argument would still compile, still return rows, and put the seeded
		   population into the last step of a chart headed "real people" —
		   under the one switch that exists to keep them apart. */
		var atSchool, anywhere analysis.Counting
		store := analysis.NewStore(pool, nil, nil).WithStream(
			func(_ context.Context, _ uuid.UUID, _ []string, _ time.Time,
				w analysis.Counting) ([]analysis.Reach, error) {
				atSchool = w
				return nil, nil
			},
			func(_ context.Context, _ []string, _ time.Time,
				w analysis.Counting) ([]analysis.Reach, error) {
				anywhere = w
				return nil, nil
			},
			nil,
			nil,
			nil,
			func(context.Context) (map[uuid.UUID]uuid.UUID, error) { return nil, nil },
		)

		if _, err := store.Funnel(context.Background(), uuid.New(), time.Time{}, who); err != nil {
			t.Fatal(err)
		}
		if atSchool != who {
			t.Errorf("the funnel was asked for %q and read %q at the school", who, atSchool)
		}
		if anywhere != who {
			t.Errorf("the funnel was asked for %q and read %q off any school", who, anywhere)
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
