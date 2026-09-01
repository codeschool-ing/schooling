package analysis_test

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"

	"github.com/codeschool-ing/schooling/internal/analysis"
)

/* Where the people are.

   THESE TESTS NEED NO DATABASE, which is what makes them worth having. The
   folding is the whole risk — the query is one DISTINCT — and a test that
   wanted Postgres would skip on every machine and only ever run in CI, which
   is where the cohort screen's month-width defect got as far as it did. */

func placed(t *testing.T, origins []analysis.Origin,
	links map[uuid.UUID]uuid.UUID) analysis.Where {

	t.Helper()
	store := analysis.NewStore(nil, nil, nil).WithStream(nil, nil, nil, nil,
		func(context.Context, uuid.UUID, time.Time, analysis.Counting) ([]analysis.Origin, error) {
			return origins, nil
		},
		func(context.Context) (map[uuid.UUID]uuid.UUID, error) { return links, nil },
	)

	where, err := store.Countries(context.Background(), uuid.New(), time.Time{},
		analysis.Counting("real"))
	if err != nil {
		t.Fatalf("reading where people are: %v", err)
	}
	return where
}

func from(country string, visitor, account *uuid.UUID) analysis.Origin {
	return analysis.Origin{Country: country, VisitorID: visitor, AccountID: account}
}

func peopleIn(t *testing.T, where analysis.Where, code string) int {
	t.Helper()
	for _, c := range where.Countries {
		if c.Code == code {
			return c.People
		}
	}
	return 0
}

/*
ONE PERSON ON TWO BROWSERS IS ONE PERSON, WHICH IS THE FUNNEL'S RULE.

	It has to be the same rule, applied by the same function: a map counting
	identities while the funnel counts people would put two different totals on
	two screens of the same console, both right by their own definition and
	neither reconcilable. That is worse than one of them being wrong, because
	there is nothing to fix.
*/
func TestALaptopAndAPhoneAreOnePerson(t *testing.T) {
	account := id()
	laptop, phone := id(), id()

	where := placed(t, []analysis.Origin{
		from("br", laptop, account),
		from("br", phone, account),
	}, nil)

	if got := peopleIn(t, where, "br"); got != 1 {
		t.Errorf("br has %d people, want 1 — the same account on two browsers is "+
			"one person, and the account is the identity that says so", got)
	}
	if where.People != 1 {
		t.Errorf("the answer counts %d people altogether, want 1", where.People)
	}
}

// AND A VISITOR WHO LATER SIGNED UP IS THAT ACCOUNT, even on an event that
// carried no account id. It is how somebody who arrived on Monday and signed
// up on Friday stops being two people.
func TestAVisitorLinkedToAnAccountIsTheAccount(t *testing.T) {
	account := id()
	browser := id()

	where := placed(t,
		[]analysis.Origin{
			from("br", browser, nil), // arrived, signed out
			from("br", nil, account), // came back, signed in
		},
		map[uuid.UUID]uuid.UUID{*browser: *account})

	if got := peopleIn(t, where, "br"); got != 1 {
		t.Errorf("br has %d people, want 1 — the visitor is linked to that account", got)
	}
}

/*
A PERSON SEEN IN TWO COUNTRIES IS IN BOTH, AND THE TOTAL SAYS SO.

	This is the number somebody will add up, and they will get more people than
	there are. That is not a defect to hide: it is what the report means, and
	the only defence against the wrong reading is that the honest total travels
	beside the rows rather than being computed from them. Same rule as a
	threshold travelling with the number it produced (K-16).
*/
func TestSomebodyWhoTravelledIsInBothCountriesAndCountedOnce(t *testing.T) {
	account := id()

	where := placed(t, []analysis.Origin{
		from("br", nil, account),
		from("pt", nil, account),
	}, nil)

	if got := peopleIn(t, where, "br"); got != 1 {
		t.Errorf("br has %d people, want 1", got)
	}
	if got := peopleIn(t, where, "pt"); got != 1 {
		t.Errorf("pt has %d people, want 1", got)
	}
	if where.People != 1 {
		t.Errorf("the answer counts %d people altogether, want 1 — the countries add "+
			"up to two and there is one person, which is exactly why this field "+
			"exists rather than being the sum of the rows", where.People)
	}
}

/*
`unknown` IS A COUNTRY ON THE LIST AND NOT A ROW TO DROP.

	Today it is the honest majority: every event written before the database
	existed came from it, and everything behind a VPN will keep coming from it.
	Dropping it would make the map look complete and every percentage on it a
	lie.
*/
func TestNobodyKnowsWhereIsACountryOnTheList(t *testing.T) {
	where := placed(t, []analysis.Origin{
		from("unknown", id(), nil),
		from("unknown", id(), nil),
		from("br", id(), nil),
	}, nil)

	if got := peopleIn(t, where, "unknown"); got != 2 {
		t.Errorf("unknown has %d people, want 2 — it is where everything came from "+
			"before there was a database, and hiding it makes the map a lie", got)
	}
	if len(where.Countries) != 2 {
		t.Errorf("the answer has %d countries, want 2", len(where.Countries))
	}
}

// AN EVENT WITH NEITHER IDENTITY BELONGS TO NOBODY. It happened, and counting
// it as an anonymous person would inflate whichever country it came from —
// which is the one direction this report must not be wrong in, because a
// country with one invented person in it is a country somebody plans around.
func TestAnEventWithNobodyOnItCountsForNobody(t *testing.T) {
	where := placed(t, []analysis.Origin{
		from("br", nil, nil),
		from("br", id(), nil),
	}, nil)

	if got := peopleIn(t, where, "br"); got != 1 {
		t.Errorf("br has %d people, want 1", got)
	}
	if where.People != 1 {
		t.Errorf("the answer counts %d people, want 1", where.People)
	}
}

/*
BIGGEST FIRST, AND THE ORDER IS STABLE.

	Ranging over a map is deliberately unordered in Go, so without the
	tiebreaker two identical requests can come back with the rows in different
	places — which looks broken in a way nobody can reproduce and nobody
	reports.
*/
func TestTheBiggestCountryIsFirstAndTiesDoNotMove(t *testing.T) {
	origins := []analysis.Origin{
		from("pt", id(), nil),
		from("br", id(), nil), from("br", id(), nil), from("br", id(), nil),
		from("ar", id(), nil),
		from("cl", id(), nil),
	}

	first := placed(t, origins, nil)
	if len(first.Countries) == 0 || first.Countries[0].Code != "br" {
		t.Fatalf("the biggest country is not first: %v", first.Countries)
	}

	// `ar`, `cl` and `pt` all have one person, so only the tiebreaker decides
	// their order — and it has to decide it the same way every time.
	for i := 0; i < 5; i++ {
		again := placed(t, origins, nil)
		for at := range again.Countries {
			if again.Countries[at] != first.Countries[at] {
				t.Fatalf("read %d put %v where the first read put %v",
					i+2, again.Countries[at], first.Countries[at])
			}
		}
	}
}

// A STORE WITH NO STREAM REFUSES rather than answering an empty map, which is
// the most convincing possible way to be broken: a school where nobody is.
func TestAMapWiredWithoutTheStreamRefuses(t *testing.T) {
	store := analysis.NewStore(nil, nil, nil)

	if _, err := store.Countries(context.Background(), uuid.New(), time.Time{},
		analysis.Counting("real")); err == nil {
		t.Error("a map with nothing to read answered as though nobody was anywhere")
	}
}

/*
TWO SPELLINGS OF ONE COUNTRY ARE ONE COUNTRY.

	The column has more than one writer. `platform/geo` lowercases what it
	resolves; the seeder wrote `BR` for its first three weeks, and those rows
	are in the stream for good. Grouped on the raw string they were two
	countries — one drawn on the map with a flag and a name, one a bare code in
	the list beside it — and nothing failed anywhere.

	It is folded HERE and not fixed in a migration, because a migration cleans
	what exists once and this keeps being true for whatever writes the column
	next.
*/
func TestOneCountryInTwoCasesIsOneCountry(t *testing.T) {
	where := placed(t, []analysis.Origin{
		from("BR", nil, id()),
		from("br", nil, id()),
		from(" Br ", nil, id()),
	}, nil)

	if len(where.Countries) != 1 {
		t.Fatalf("%d countries came out of three spellings of one: %v",
			len(where.Countries), where.Countries)
	}
	if where.Countries[0].Code != "br" {
		t.Errorf("the code is %q, want %q — the map is keyed by the lower-case one",
			where.Countries[0].Code, "br")
	}
	if got := peopleIn(t, where, "br"); got != 3 {
		t.Errorf("br has %d people, want 3", got)
	}
}
