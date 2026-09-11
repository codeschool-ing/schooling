package analysis_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/analysis"
)

/* What the people are holding.

   THESE TESTS NEED NO DATABASE, for `countries_test.go`'s reason exactly: the
   folding is the whole risk, the query is one DISTINCT, and a test that wanted
   Postgres would skip on every machine and only ever run in CI. */

func held(t *testing.T, holdings []analysis.Holding,
	links map[uuid.UUID]uuid.UUID) analysis.Held {

	t.Helper()
	store := analysis.NewStore(nil, nil, nil).WithStream(nil, nil, nil, nil, nil,
		func(context.Context, uuid.UUID, time.Time, analysis.Counting) ([]analysis.Holding, error) {
			return holdings, nil
		},
		func(context.Context) (map[uuid.UUID]uuid.UUID, error) { return links, nil })

	out, err := store.Devices(context.Background(), uuid.New(), time.Time{},
		analysis.Counting("real"))
	if err != nil {
		t.Fatalf("reading what people are on: %v", err)
	}
	return out
}

func on(kind string, visitor, account *uuid.UUID) analysis.Holding {
	return analysis.Holding{Device: kind, VisitorID: visitor, AccountID: account}
}

func peopleOn(t *testing.T, out analysis.Held, kind string) int {
	t.Helper()
	for _, d := range out.Devices {
		if d.Kind == kind {
			return d.People
		}
	}
	return 0
}

/*
ONE PERSON ON TWO BROWSERS IS ONE PERSON, WHICH IS THE FUNNEL'S RULE.

	It has to be the same rule applied by the same function, or this screen and
	the funnel would put two totals on two screens of one console — both right
	by their own definition and neither reconcilable, which is worse than one of
	them being wrong because there is nothing to fix.
*/
func TestOneAccountSeenFromTwoBrowsersIsOnePerson(t *testing.T) {
	account := uuid.New()
	one, two := uuid.New(), uuid.New()
	links := map[uuid.UUID]uuid.UUID{one: account, two: account}

	out := held(t, []analysis.Holding{
		on("phone", &one, nil),
		on("phone", &two, &account),
	}, links)

	if out.People != 1 {
		t.Errorf("one person on two browsers counted as %d people", out.People)
	}
	if got := peopleOn(t, out, "phone"); got != 1 {
		t.Errorf("the phone row says %d, and it is the same person twice", got)
	}
}

/*
A PERSON ON TWO THINGS IS ON BOTH, AND THE TOTAL SAYS SO.

	Somebody who reads on a phone in a queue and drills on a laptop is two rows
	honestly, so the devices add up to more than the people. `People` is the
	half that stops a screen's bars being added into a headcount.
*/
func TestAPersonOnTwoThingsIsOnBothAndCountedOnce(t *testing.T) {
	account := uuid.New()
	browser := uuid.New()
	links := map[uuid.UUID]uuid.UUID{browser: account}

	out := held(t, []analysis.Holding{
		on("phone", &browser, &account),
		on("computer", &browser, &account),
	}, links)

	if out.People != 1 {
		t.Errorf("one person on two devices counted as %d people", out.People)
	}
	if peopleOn(t, out, "phone") != 1 || peopleOn(t, out, "computer") != 1 {
		t.Errorf("the rows are %+v, and the person is in both", out.Devices)
	}

	sum := 0
	for _, d := range out.Devices {
		sum += d.People
	}
	if sum <= out.People {
		t.Errorf("the devices sum to %d and the people are %d — the whole reason "+
			"both numbers come back is that the first is the larger", sum, out.People)
	}
}

func TestTheRowsAreBiggestFirstAndTheTieIsBrokenByName(t *testing.T) {
	links := map[uuid.UUID]uuid.UUID{}
	var rows []analysis.Holding
	for i := 0; i < 3; i++ {
		who := uuid.New()
		rows = append(rows, on("phone", &who, nil))
	}
	// One each, so the two small rows can only be ordered by their name — which
	// is what stops a screen reshuffling itself between two identical requests.
	a, b := uuid.New(), uuid.New()
	rows = append(rows, on("tablet", &a, nil), on("computer", &b, nil))

	out := held(t, rows, links)
	if len(out.Devices) != 3 {
		t.Fatalf("three kinds came back as %d: %+v", len(out.Devices), out.Devices)
	}
	if out.Devices[0].Kind != "phone" {
		t.Errorf("the biggest row is %q", out.Devices[0].Kind)
	}
	if out.Devices[1].Kind != "computer" || out.Devices[2].Kind != "tablet" {
		t.Errorf("the tie broke as %q then %q, and it is alphabetical",
			out.Devices[1].Kind, out.Devices[2].Kind)
	}
}

/*
`unknown` IS A ROW AND NOT A GAP.

	Only Chromium sends the hints this is read from and the page fills in for
	the rest; a browser doing neither is honestly unknown. Dropping that row, or
	folding it into the largest, would turn a report about Chromium into a
	report about the audience.
*/
func TestUnknownIsADeviceOnTheList(t *testing.T) {
	a, b := uuid.New(), uuid.New()
	out := held(t, []analysis.Holding{
		on("unknown", &a, nil),
		on("phone", &b, nil),
	}, map[uuid.UUID]uuid.UUID{})

	if peopleOn(t, out, "unknown") != 1 {
		t.Errorf("the unknown row is missing from %+v", out.Devices)
	}
}

/*
THE COLUMN WILL HAVE A SECOND WRITER, AND THE LESSON IS ALREADY PAID FOR.

	`countries.go` grouped on the raw string until the seeder's `BR` and the
	resolver's `br` had been two countries on one map for three weeks, with
	nothing failing anywhere. Folding here is that lesson applied before rather
	than after.
*/
func TestTheKindIsFoldedBeforeItIsGrouped(t *testing.T) {
	a, b := uuid.New(), uuid.New()
	out := held(t, []analysis.Holding{
		on("Phone", &a, nil),
		on("  phone ", &b, nil),
	}, map[uuid.UUID]uuid.UUID{})

	if len(out.Devices) != 1 {
		t.Fatalf("two spellings of one device made %d rows: %+v", len(out.Devices), out.Devices)
	}
	if peopleOn(t, out, "phone") != 2 {
		t.Errorf("the folded row holds %d of the two people", peopleOn(t, out, "phone"))
	}
}

func TestAnEmptyKindIsTheSameThingAsUnknown(t *testing.T) {
	// The column refuses an empty string so this cannot come from the database.
	// It can come from a hand-built row, and it means what `unknown` means.
	a := uuid.New()
	out := held(t, []analysis.Holding{on("", &a, nil)}, map[uuid.UUID]uuid.UUID{})
	if peopleOn(t, out, "unknown") != 1 {
		t.Errorf("an empty kind landed as %+v", out.Devices)
	}
}

/*
AN EVENT WITH NEITHER IDENTITY IS NOBODY.

	It happened, and there is nobody to count it for. Counting it as an
	anonymous person would inflate whichever device it came from — which is the
	direction that makes a number look like evidence.
*/
func TestAnEventWithNobodyOnItCountsForNobodyOnAnyDevice(t *testing.T) {
	out := held(t, []analysis.Holding{on("phone", nil, nil)}, map[uuid.UUID]uuid.UUID{})
	if out.People != 0 || len(out.Devices) != 0 {
		t.Errorf("an event naming nobody produced %+v", out)
	}
}

func TestAStoreWithoutTheStreamRefuses(t *testing.T) {
	/* A STORE WIRED WITHOUT THIS READER MUST NOT ANSWER AN EMPTY BREAKDOWN,
	   which would read as a school where nobody is on anything. */
	store := analysis.NewStore(nil, nil, nil)
	if _, err := store.Devices(context.Background(), uuid.New(), time.Time{},
		analysis.Counting("real")); err == nil {

		t.Error("a store with no stream answered the breakdown, and the only answer " +
			"it could have given is an empty one")
	}
}

/*
THE CROSS IS THE REASON THE BREAKDOWN EXISTS.

	"Seventy per cent are on phones" is trivia. "Seventy per cent are on phones
	and a tenth of them signed up, against half of the people on a keyboard" is
	a defect with an address — so every row carries both numbers, and a student
	is a person the same function resolved to an account.
*/
func TestEachRowSaysHowManyOfThemAreStudents(t *testing.T) {
	account := uuid.New()
	linked, bare, alone := uuid.New(), uuid.New(), uuid.New()
	links := map[uuid.UUID]uuid.UUID{linked: account}

	out := held(t, []analysis.Holding{
		on("phone", &linked, nil), // a browser that belongs to an account
		on("phone", &bare, nil),   // a browser that does not
		on("computer", &alone, &account),
	}, links)

	for _, d := range out.Devices {
		switch d.Kind {
		case "phone":
			if d.People != 2 || d.Students != 1 {
				t.Errorf("the phone row is %d people and %d students, and it is two and one",
					d.People, d.Students)
			}
		case "computer":
			if d.People != 1 || d.Students != 1 {
				t.Errorf("the computer row is %d people and %d students, and it is one and one",
					d.People, d.Students)
			}
		}
	}

	/* AND THE SAME ACCOUNT ON TWO THINGS IS ONE PERSON OVERALL, so the students
	   of each row can add up to more than the students there are — exactly as
	   the people do. A screen adding either column into a headcount is the
	   failure both totals exist to prevent. */
	if out.People != 2 {
		t.Errorf("one account on two devices plus one bare browser is %d people", out.People)
	}
}
